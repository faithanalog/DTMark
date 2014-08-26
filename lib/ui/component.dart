part of dtmark;

/*
 * TODO
 * Render font (and ui elements too maybe?) with distance field shaders
 */

class Align {

  static const Align LEFT = const Align(0);
  static const Align CENTER = const Align(1);
  static const Align RIGHT = const Align(2);
  static const Align TOP = const Align(3);
  static const Align BOTTOM = const Align(4);

  final int id;

  const Align(this.id);

}

void initUISystem(WebGL.RenderingContext gl) {
  Component.defaultFont = new FontRenderer.lowResMono(gl);
}

abstract class Component {

  static FontRenderer defaultFont;
  static Align defaultHAlign = Align.LEFT;
  static Align defaultVAlign = Align.BOTTOM;

  int offX = 0, offY = 0, width = 0, height = 0;
  Align halign = defaultHAlign;
  Align valign = defaultVAlign;

  FontRenderer font = defaultFont;

  Container _parent = null;

  StreamController<MouseDownEvent> _mouseDownController = new StreamController();
  StreamController<MouseUpEvent> _mouseUpController = new StreamController();
  StreamController<MouseMoveEvent> _mouseMoveController = new StreamController();
  StreamController<KeyDownEvent> _keyDownController = new StreamController();
  StreamController<KeyUpEvent> _keyUpController = new StreamController();

  Stream<MouseDownEvent> get onMouseDown => _mouseDownController.stream;
  Stream<MouseUpEvent> get onMouseUp => _mouseUpController.stream;
  Stream<MouseMoveEvent> get onMouseMove => _mouseMoveController.stream;
  Stream<KeyDownEvent> get onKeyDown => _keyDownController.stream;
  Stream<KeyUpEvent> get onKeyUp => _keyUpController.stream;
  Container get parent => _parent;

  int get x {
    switch(halign) {
      case Align.LEFT:
        return offX;
      case Align.RIGHT:
        return _parent.width - width + offX;
      case Align.CENTER:
        return ((_parent.width - width) >> 1) + offX;
      default:
        return offX;
    }
  }

  int get y {
    switch(valign) {
      case Align.TOP:
        return offY;
      case Align.BOTTOM:
        return _parent.height - height + offY;
      case Align.CENTER:
        return ((_parent.height - height) >> 1) + offY;
      default:
        return offY;
    }
  }

  int get mouseX {
    return _parent.mouseX - x;
  }

  int get mouseY {
    return _parent.mouseY - y;
  }

  void _mouseDown(MouseDownEvent evt) => _mouseDownController.add(evt);
  void _mouseUp(MouseUpEvent evt) => _mouseUpController.add(evt);
  void _mouseMove(MouseMoveEvent evt) => _mouseMoveController.add(evt);

  void _keyDown(KeyDownEvent evt) => _keyDownController.add(evt);
  void _keyUp(KeyUpEvent evt) => _keyUpController.add(evt);

  /**
   * Checks if the point is within the component. [x] and [y] should be
   * relative to the location of the component, such that (0, 0) is the
   * bottom left corner of the component.
   */
  bool containsPoint(int x, int y) {
    return x >= 0 && x < width && y >= 0 && y < height;
  }

  bool containsMouse() {
    return containsPoint(mouseX, mouseY);
  }

  void render(SpriteBatch batch);

}

class Container extends Component {

  final Set<Component> _children = new Set();
  Component focus = null;

  void add(Component child) {
    child._parent = this;
    _children.add(child);
  }

  void addAll(Iterable<Component> children) {
    for (final child in children) {
      child._parent = this;
    }
    _children.addAll(children);
  }

  void remove(Component child) {
    child._parent = null;
    _children.remove(child);
  }

  void removeAll(Iterable<Component> children) {
    for (final child in children) {
      child._parent = null;
    }
    _children.removeAll(children);
  }

  @override
  void _mouseDown(MouseDownEvent evt) {
    super._mouseDown(evt);
    focus = null;
    for (final child in _children) {
      int cx = evt.x - child.x, cy = evt.y - child.y;
      if (child.containsPoint(cx, cy)) {
        focus = child;
        child._mouseDown(new MouseDownEvent(child, cx, cy, evt.button));
        break;
      }
    }
  }

  @override
  void _mouseUp(MouseUpEvent evt) {
    super._mouseUp(evt);
    for (final child in _children) {
      int cx = evt.x - child.x, cy = evt.y - child.y;
      if (child.containsPoint(cx, cy)) {
        child._mouseUp(new MouseUpEvent(child, cx, cy, evt.button));
      }
    }
  }

  @override
  void _mouseMove(MouseMoveEvent evt) {
    super._mouseMove(evt);
    for (final child in _children) {
      int cx = evt.x - child.x, cy = evt.y - child.y;
      if (child.containsPoint(cx, cy)) {
        child._mouseMove(new MouseMoveEvent(child, cx, cy));
      }
    }
  }

  @override
  void _keyDown(KeyDownEvent evt) {
    super._keyDown(evt);
    if (focus != null) {
      focus._keyDown(new KeyDownEvent(focus, evt.key));
    }
  }

  @override
  void _keyUp(KeyUpEvent evt) {
    super._keyUp(evt);
    if (focus != null) {
      focus._keyUp(new KeyUpEvent(focus, evt.key));
    }
  }

  @override
  void render(SpriteBatch batch) {
    for (final child in _children) {
      double x = child.x.toDouble(), y = child.y.toDouble();
      batch.modelView.translate(x, y, 0.0);
      child.render(batch);
      batch.modelView.translate(-x, -y, 0.0);
    }
  }
}

class RootPanel extends Container {

  bool active = false;
  SpriteBatch batch;

  BaseGame game;

  int _mouseX = -1, _mouseY = -1;
  double scale = 1.0;

  RootPanel(this.game) {
    var canvas = game.canvas;
    var gl = game.gl;
    batch = new SpriteBatch(gl);
    game.onMouseDown.listen((evt) {
      _mouseX = evt.x;
      _mouseY = evt.y;
      if (active) {
        _mouseDown(new MouseDownEvent(this, _mouseX, _mouseY, evt.button));
      }
    });
    game.onMouseUp.listen((evt) {
      _mouseX = evt.x;
      _mouseY = evt.y;
      if (active) {
        _mouseUp(new MouseUpEvent(this, _mouseX, _mouseY, evt.button));
      }
    });
    game.onMouseMove.listen((evt) {
      _mouseX = evt.x;
      _mouseY = evt.y;
      if (active) {
        _mouseMove(new MouseMoveEvent(this, _mouseX, _mouseY));
      }
    });
    game.onKeyDown.listen((evt) {
      if (active) {
        _keyDown(new KeyDownEvent(this, evt.key));
      }
    });
    game.onKeyUp.listen((evt) {
      if (active) {
        _keyUp(new KeyUpEvent(this, evt.key));
      }
    });
  }

  void renderAll() {
    batch.projection = makeOrthographicMatrix(0, game.canvas.width / scale, 0, game.canvas.height / scale, -1, 1);
    render(batch);
  }

  @override
  int get x => 0;

  @override
  int get y => 0;

  @override
  int get width => game.canvas.width ~/ scale;

  @override
  int get height => game.canvas.height ~/ scale;

  @override
  int get mouseX => _mouseX;

  @override
  int get mouseY => _mouseY;

}

abstract class TextComponent extends Component {

  String text;
  int fontSize;

}
