part of dtmark;

/*
 * TODO: Render font (and ui elements too maybe?) with distance field shaders
 */

/**
 * Generic alignment constants used in UI code
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

/**
 * Sets up the UI system to work with the rendering context.
 * Currently only creates a font for Component.defaultFont
 */
void initUISystem(WebGL.RenderingContext gl) {
  Component.defaultFont = new FontRenderer.lowResMono(gl);
}

/**
 * Base class for all UI components
 */
abstract class Component {

  /**
   * Default font used by any component rendering text
   */
  static FontRenderer defaultFont;

  /**
   * Default horizontal alignment for new components
   */
  static Align defaultHAlign = Align.LEFT;

  /**
   * Default vertical alignment for new components
   */
  static Align defaultVAlign = Align.BOTTOM;

  /**
   * X offset of component from its normal position
   */
  int offX = 0;

  /**
   * Y offset of component from its normal position
   */
  int offY = 0;

  /**
   * Current width
   */
  int width = 0;

  /**
   * Current height
   */
  int height = 0;

  /**
   * Current horizontal alignment
   */
  Align halign = defaultHAlign;

  /**
   * Current vertical alignment
   */
  Align valign = defaultVAlign;

  /**
   * Current font used when rendering text
   */
  FontRenderer font = defaultFont;

  /**
   * Parent container if any. Only RootPanel or new components have no parent.
   */
  Container _parent = null;

  StreamController<MouseDownEvent> _mouseDownController = new StreamController();
  StreamController<MouseUpEvent> _mouseUpController = new StreamController();
  StreamController<MouseMoveEvent> _mouseMoveController = new StreamController();
  StreamController<KeyDownEvent> _keyDownController = new StreamController();
  StreamController<KeyUpEvent> _keyUpController = new StreamController();

  /**
   * Stream of mouseDown events
   */
  Stream<MouseDownEvent> get onMouseDown => _mouseDownController.stream;

  /**
   * Stream of mouseUp events
   */
  Stream<MouseUpEvent> get onMouseUp => _mouseUpController.stream;

  /**
   * Stream of mouseMove events
   */
  Stream<MouseMoveEvent> get onMouseMove => _mouseMoveController.stream;

  /**
   * Stream of keyDown events
   */
  Stream<KeyDownEvent> get onKeyDown => _keyDownController.stream;

  /**
   * Stream of keyUp events
   */
  Stream<KeyUpEvent> get onKeyUp => _keyUpController.stream;

  /**
   * Parent container of this component
   */
  Container get parent => _parent;

  /**
   * X position of this component relative to parent
   */
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

  /**
   * Y position of this component relative to parent
   */
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

  /**
   * Mouse X position relative to this component
   */
  int get mouseX {
    return _parent.mouseX - x;
  }

  /**
   * Mouse Y position relative to this component
   */
  int get mouseY {
    return _parent.mouseY - y;
  }

  void _mouseDown(MouseDownEvent evt) => _mouseDownController.add(evt);
  void _mouseUp(MouseUpEvent evt) => _mouseUpController.add(evt);
  void _mouseMove(MouseMoveEvent evt) => _mouseMoveController.add(evt);

  void _keyDown(KeyDownEvent evt) => _keyDownController.add(evt);
  void _keyUp(KeyUpEvent evt) => _keyUpController.add(evt);

  /**
   * Checks if the point is within this component. [x] and [y] should be
   * relative to the location of this component, such that (0, 0) is the
   * bottom left corner of this component.
   */
  bool containsPoint(int x, int y) {
    return x >= 0 && x < width && y >= 0 && y < height;
  }

  /**
   * Checks if the mouse is within the bounds of this component
   */
  bool containsMouse() {
    return containsPoint(mouseX, mouseY);
  }

  /**
   * Renders this component with the given sprite batch
   */
  void render(SpriteBatch batch);

}

/**
 * Container component which can contain children. The positions
 * of child components are relative to their parent Container.
 */
class Container extends Component {

  final Set<Component> _children = new Set();

  /**
   * Currently focused component which will receive key events
   */
  Component focus = null;

  /**
   * Adds a new child component to this Container
   */
  void add(Component child) {
    child._parent = this;
    _children.add(child);
  }

  /**
   * Adds multiple child components at once
   */
  void addAll(Iterable<Component> children) {
    for (final child in children) {
      child._parent = this;
    }
    _children.addAll(children);
  }

  /**
   * Remove a child component from this Container
   */
  void remove(Component child) {
    child._parent = null;
    _children.remove(child);
  }

  /**
   * Remove multiple child components at once
   */
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

  /**
   * Render all children of this Container
   */
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

/**
 * The root panel of the UI system. RootPanels do not have
 * a parent and instead receive events from a BaseGame
 */
class RootPanel extends Container {

  /**
   * If false, will ignore all input events
   */
  bool active = false;

  /**
   * SpriteBatch used when rendering child components
   */
  SpriteBatch batch;

  /**
   * BaseGame associated with this RootPanel
   */
  BaseGame game;

  int _mouseX = -1, _mouseY = -1;

  /**
   * Scale of the UI relative to the game canvas width and height
   */
  double scale = 1.0;

  RootPanel(this.game) {
    var canvas = game.canvas;
    var gl = game.gl;
    batch = new SpriteBatch(gl);
    game.onMouseDown.listen((evt) {
      _mouseX = evt.x ~/ scale;
      _mouseY = evt.y ~/ scale;
      if (active) {
        _mouseDown(new MouseDownEvent(this, _mouseX, _mouseY, evt.button));
      }
    });
    game.onMouseUp.listen((evt) {
      _mouseX = evt.x ~/ scale;
      _mouseY = evt.y ~/ scale;
      if (active) {
        _mouseUp(new MouseUpEvent(this, _mouseX, _mouseY, evt.button));
      }
    });
    game.onMouseMove.listen((evt) {
      _mouseX = evt.x ~/ scale;
      _mouseY = evt.y ~/ scale;
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

  /**
   * Renders the UI
   */
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

/**
 * Base class for components which contain a String to render
 */
abstract class TextComponent extends Component {

  String text;
  int fontSize;

}
