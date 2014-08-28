library dtmark;

import 'dart:html';
import 'dart:convert';
import 'dart:math' as Math;
import 'dart:typed_data';
import 'dart:web_gl' as WebGL;
import 'dart:web_audio' as WebAudio;
import 'dart:async';
import 'dart:js';
import 'package:vector_math/vector_math.dart';
import 'package:browser_detect/browser_detect.dart' as BrowserDetect;

//WebGL stuff
part 'gl/shader.dart';
part 'gl/texture.dart';

//2D stuff
part '2d/spritebatch.dart';
part '2d/fontrenderer.dart';
part '2d/animation.dart';

//Audio
part 'audio/streaming.dart';
part 'audio/webaudio.dart';

//UI
part 'ui/component.dart';
part 'ui/event.dart';
part 'ui/button.dart';

abstract class BaseGame {

  static bool touchSupport = null;

  CanvasElement canvas;
  WebGL.RenderingContext gl;

  double _timePerFrame;
  double _timePerTick;
  double _missedFrames = 0.0;
  double _missedTicks = 0.0;

  double _lastTime = -1.0;
  double _deltaTime = 0.0;
  double _partialTick = 0.0;

  //Time in milliseconds at the start of the frame
  int _frameTime = 0;

  /**
   * canvasResolution / windowResolution
   * So if the clientWidth is 100 and the canvas.width is 200, canvasScale would be 2.0
   */
  double canvasScale = 1.0;

  /**
   * All mouse coordinates are multiplied by this.
   * Use for if your [canvasScale] != 1.0 or your orthographics matrix
   * resolution != canvas resolution.
   *
   * For example, if [canvasScale] is 2.0, set this to 2.0
   */
  double mousePosScale = 1.0;

  Int32List _keys = new Int32List(256);
  Int32List _mouseButtons = new Int32List(32);
  int _mouseX = 0;
  int _mouseY = 0;
  bool _useAnimFrame;
  bool _useDeltaTime;

  /*
   * Controllers for all event streams
   * This is very similar to the UI event stuff, and uses similar events
   */
  StreamController<GameMouseEvent> _mouseDownController = new StreamController();
  StreamController<GameMouseEvent> _mouseUpController = new StreamController();
  StreamController<GameMouseEvent> _mouseMoveController = new StreamController();
  StreamController<GameKeyboardEvent> _keyDownController = new StreamController();
  StreamController<GameKeyboardEvent> _keyUpController = new StreamController();

  /**
   * Whether or not to invert Y values from what they are provided as in the event.
   * This applies to what mouseY is set to.
   */
  bool invertMouseY = true;

  /**
   * Base game constructor. [frameRate] is only used when useAnimFrame is false,
   * otherwise render() will be called on every anim frame.
   */
  BaseGame(this.canvas, {double frameRate: 60.0, double tickRate: 60.0, bool useDeltaTime: false, bool useAnimFrame: true}) {
    canvas.onContextMenu.listen((Event e) => e.preventDefault());
    gl = createContext3d();
    _timePerFrame = 1 / (1000.0 / frameRate);
    _timePerTick = 1 / (1000.0 / tickRate);
    _useAnimFrame = useAnimFrame;
    _useDeltaTime = useDeltaTime;

    if (touchSupport == null) {
      touchSupport = new JsObject.fromBrowserObject(window).hasProperty("ontouchstart");
    }

    if (!touchSupport) {
      canvas.onMouseDown.listen((evt) {
        _onMouseDown((evt.offset.x * canvasScale * mousePosScale).toInt(), (evt.offset.y * canvasScale * mousePosScale).toInt(), evt.button);
      });
      canvas.onMouseUp.listen((evt) {
        _onMouseUp((evt.offset.x * canvasScale * mousePosScale).toInt(), (evt.offset.y * canvasScale * mousePosScale).toInt(), evt.button);
      });
      canvas.onMouseMove.listen((evt) {
        _onMouseMove((evt.offset.x * canvasScale * mousePosScale).toInt(), (evt.offset.y * canvasScale * mousePosScale).toInt());
      });
      canvas.onKeyDown.listen((evt) {
        _onKeyDown(evt.keyCode);
      });
      canvas.onKeyUp.listen((evt) {
        _onKeyUp(evt.keyCode);
      });
    } else {
      //Done through JS stuff to support cocoonjs
      canvas.onTouchStart.listen((evt) {
        JsObject ev = new JsObject.fromBrowserObject(evt);
        JsObject touch = new JsObject.fromBrowserObject(ev["changedTouches"][0]);
        Point offset = new Point(touch["clientX"], touch["clientY"]) - canvas.client.topLeft;
        _onMouseDown((offset.x * canvasScale * mousePosScale).toInt(), (offset.y * canvasScale * mousePosScale).toInt(), 0);
        evt.preventDefault();
      });
      canvas.onTouchEnd.listen((evt) {
        JsObject ev = new JsObject.fromBrowserObject(evt);
        JsObject touch = new JsObject.fromBrowserObject(ev["changedTouches"][0]);
        Point offset = new Point(touch["clientX"], touch["clientY"]) - canvas.client.topLeft;
        _onMouseUp((offset.x * canvasScale * mousePosScale).toInt(), (offset.y * canvasScale * mousePosScale).toInt(), 0);
        _onMouseMove(-1, -1);
        evt.preventDefault();
      });
      canvas.onTouchMove.listen((evt) {
        JsObject ev = new JsObject.fromBrowserObject(evt);
        JsObject touch = new JsObject.fromBrowserObject(ev["changedTouches"][0]);
        Point offset = new Point(touch["clientX"], touch["clientY"]) - canvas.client.topLeft;
        _onMouseMove((offset.x * canvasScale * mousePosScale).toInt(), (offset.y * canvasScale * mousePosScale).toInt());
        evt.preventDefault();
      });
    }
  }

  /**
   * Creates the WebGL context. Override this to customize attributes of the context
   */
  WebGL.RenderingContext createContext3d() {
    return canvas.getContext3d();
  }

  void launchGame() {
    if (_useAnimFrame) {
      window.animationFrame.then(_renderCallback);
    } else {
      var timer = new Timer.periodic(new Duration(milliseconds: (1 / _timePerFrame).floor()), (timer) {
        var now = new DateTime.now().millisecondsSinceEpoch;
        _renderCallback(now.toDouble());
      });
      window.onFocus.listen((evt) {
        if (!timer.isActive) {
          timer.cancel();
          timer = new Timer.periodic(new Duration(milliseconds: (1 / _timePerFrame).floor()), (timer) {
            var now = new DateTime.now().millisecondsSinceEpoch;
            _renderCallback(now.toDouble());
          });
        }
      });
      window.onBlur.listen((evt) {
        timer.cancel();
      });
    }
  }

  void _renderCallback(double time) {
    if (_useAnimFrame) {
      window.animationFrame.then(_renderCallback);
    }
    if (_lastTime == -1) {
      _lastTime = time;
    }
    double dif = time - _lastTime;
    //Missed more than a second just do 1 calc
    if (dif > 1000.0) {
      _missedTicks++;
    } else {
      _missedTicks += dif * _timePerTick;
    }
    _lastTime = time;

    //Don't tolerate more than 10 ticks missed
    if (_missedTicks > 10) {
      _missedTicks = 10.0;
    }
    _deltaTime = 1.0;
    while (_missedTicks >= 1.0) {
      tick();
      _missedTicks--;
    }
    if (_useDeltaTime) {
      _deltaTime = _missedTicks;
      _missedTicks = 0.0;
      tick();
    }
    _partialTick = _missedTicks;
    _frameTime = new DateTime.now().millisecondsSinceEpoch;
    render();
  }

  /**
   * Called every frame. Override this to provide your render code
   */
  void render() {

  }

  /**
   * Called every computation tick. Override this to provide your game logic
   */
  void tick() {

  }

  void _onKeyDown(int key) {
    _keys[key] = 1;
    keyDown(key);
    _keyDownController.add(new GameKeyboardEvent(key));
  }

  void _onKeyUp(int key) {
    _keys[key] = 0;
    keyUp(key);
    _keyUpController.add(new GameKeyboardEvent(key));
  }

  void _onMouseDown(int x, int y, int btn) {
    _mouseX = x;
    _mouseY = y;
    if (invertMouseY) {
      _mouseY = (canvas.height * mousePosScale).toInt() - _mouseY - 1;
    }
    _mouseButtons[btn] = 1;
    mouseDown(_mouseX, _mouseY, btn);
    _mouseDownController.add(new GameMouseEvent(_mouseX, _mouseY, btn));
  }

  void _onMouseUp(int x, int y, int btn) {
    _mouseX = x;
    _mouseY = y;
    if (invertMouseY) {
      _mouseY = (canvas.height * mousePosScale).toInt() - _mouseY - 1;
    }
    _mouseButtons[btn] = 0;
    mouseUp(_mouseX, _mouseY, btn);
    _mouseUpController.add(new GameMouseEvent(_mouseX, _mouseY, btn));
  }

  void _onMouseMove(int x, int y) {
    _mouseX = x;
    _mouseY = y;
    if (invertMouseY) {
      _mouseY = (canvas.height * mousePosScale).toInt() - _mouseY - 1;
    }
    mouseMove(x, y);
    _mouseMoveController.add(new GameMouseEvent(_mouseX, _mouseY, -1));
  }

  /*
   * Games have 2 options for input handling: Override keyDown,keyUp, etc.
   * Or, use the streams provided below. Both can be used simultaneously.
   * The streams are useful for pieces of the game that want to listen
   * for say specific key events, whereas overriding the methods
   * makes it easier to just get input into the game.
   */
  Stream<GameMouseEvent> get onMouseDown => _mouseDownController.stream;
  Stream<GameMouseEvent> get onMouseUp => _mouseUpController.stream;
  Stream<GameMouseEvent> get onMouseMove => _mouseMoveController.stream;
  Stream<GameKeyboardEvent> get onKeyDown => _keyDownController.stream;
  Stream<GameKeyboardEvent> get onKeyUp => _keyUpController.stream;

  /**
   * Called whenever a key is pressed. Override to handle event.
   */
  void keyDown(int key) {}

  /**
   * Called whenever a key is released. Override to handle event.
   */
  void keyUp(int key) {}

  /**
   * Called whenever a mouse button is pressed. Override to handle event.
   */
  void mouseDown(int x, int y, int btn) {}

  /**
   * Called whenever a mouse button is released. Override to handle event.
   */
  void mouseUp(int x, int y, int btn) {}

  /**
   * Called whenever the mouse is moved. Override to handle event.
   */
  void mouseMove(int x, int y) {}

  /**
   * Sets an internal key state. Does not fire an event
   */
  void setKey(int key, bool down) {
    _keys[key & 0xFF] = down ? 1 : 0;
  }

  /**
   * Sets an internal mouse button state. Does not fire an event
   */
  void setMouse(int btn, bool down) {
    _mouseButtons[btn & 0x1F] = down ? 1 : 0;
  }

  /**
   * Returns the state of the given keyboard [key].
   */
  bool isKeyDown(int key) {
    return _keys[key & 0xFF] != 0;
  }

  /**
   * Returns the state of the given mouse button [btn].
   */
  bool isMouseDown(int btn) {
    return _mouseButtons[btn & 0x1F] != 0;
  }

  /**
   * Mouse X coordinate in pixels
   */
  int get mouseX => _mouseX;

  /**
   * Mouse Y coordinate in pixels
   */
  int get mouseY => _mouseY;

  /**
   * The percent of a game computation tick that has elapsed since the last tick.
   * For example, of a game has 1 computation tick every 50 milliseconds, and
   * the a frame renders 20 milliseconds after the last computation tick,
   * [partialTick] will be 0.4. If useDeltaTime was set to true in the constructor,
   * this will always be 0.0
   */
  double get partialTick => _partialTick;

  /**
   * If useDeltaTime was set to true in the constructor, this will be the
   * percent of a tick that has elapsed since the last computation tick.
   * Otherwise, it will be 0.0. [deltaTime] will never be greater than 1.0
   */
  double get deltaTime => _deltaTime;

  /**
   * The current system time in milliseconds at the start of the current frame.
   * Useful for animations.
   */
  int get frameTime => _frameTime;


}

int nextPowerOf2(int val) {
  int powof2 = 1;
  while (powof2 < val) {
    powof2 <<= 1;
  }
  return powof2;
}

class GameMouseEvent {
  int x, y, button;
  GameMouseEvent(this.x, this.y, this.button);
}

class GameKeyboardEvent {
  int key;
  GameKeyboardEvent(this.key);
}
