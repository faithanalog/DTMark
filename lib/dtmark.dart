library dtmark;

import 'dart:html';
import 'dart:convert';
import 'dart:math' as Math;
import 'dart:typed_data';
import 'dart:web_gl' as WebGL;
import 'dart:web_audio' as WebAudio;
import 'dart:async';
import 'dart:js';
import 'package:collection/iterable_zip.dart';
import 'package:vector_math/vector_math.dart';
import 'package:browser_detect/browser_detect.dart' as BrowserDetect;

//WebGL stuff
part 'src/gl/shader.dart';
part 'src/gl/texture.dart';
part 'src/gl/framebuffer.dart';
part 'src/gl/vertexbatch.dart';

//2D stuff
part 'src/2d/spritebatch.dart';
part 'src/2d/fontrenderer.dart';
part 'src/2d/animation.dart';

//3D stuff
part 'src/3d/geometry.dart';
part 'src/3d/material.dart';
part 'src/3d/mesh.dart';
part 'src/3d/model.dart';
part 'src/3d/tessellator.dart';
part 'src/3d/modelrenderer.dart';
part 'src/3d/camera.dart';
part 'src/util/objparser.dart';


//Audio
part 'src/audio/streaming.dart';
part 'src/audio/webaudio.dart';
part 'src/audio/oscillator.dart';
part 'src/audio/generator.dart';

//UI
part 'src/ui/component.dart';
part 'src/ui/event.dart';
part 'src/ui/button.dart';

//Other Util
part 'src/util/time.dart';

abstract class BaseGame {

  static bool _touchSupport = null;
  static bool get touchSupport => _touchSupport;

  /**
   * Set this to true to use window.onTouchX instead of canvas.onTouchX.
   * May be required by some technologies such as CocoonJS
   */
  static bool useWindowTouchEvents = false;



  CanvasElement canvas;
  WebGL.RenderingContext gl;

  double _timePerFrame;
  double _timePerTick;
  double _missedTicks = 0.0;

  double _lastTime = -1.0;
  double _deltaTime = 0.0;
  double _partialTick = 0.0;

  //Time in milliseconds at the start of the frame
  static int _frameTime = 0;

  /**
   * canvasResolution / windowResolution
   * So if the clientWidth is 100 and the canvas.width is 200, canvasScale would be 2.0
   */
  double canvasScale = 1.0;

  /**
   * All mouse coordinates are multiplied by this.
   * Use for if your [canvasScale] != 1.0 or your orthographic matrix
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
  StreamController<GameMouseEvent> _mouseDownController  = new StreamController();
  StreamController<GameMouseEvent> _mouseUpController    = new StreamController();
  StreamController<GameMouseEvent> _mouseMoveController  = new StreamController();
  StreamController<GameKeyboardEvent> _keyDownController = new StreamController();
  StreamController<GameKeyboardEvent> _keyUpController   = new StreamController();

  /**
   * Whether or not to invert Y values from what they are provided as in the event.
   * This applies to what mouseY is set to.
   *
   * For example, if invertMouseY is true, canvas height is 100, and a mouse event
   * is fired at (0,99), this will cause the game's event listener to change
   * that to (0,0)
   */
  bool invertMouseY = true;

  /**
   * Base game constructor. [frameRate] is only used when useAnimFrame is false,
   * otherwise render() will be called on every anim frame.
   */
  BaseGame(this.canvas,
           { double frameRate: 60.0,
             double tickRate: 60.0,
             bool useDeltaTime: false,
             bool useAnimFrame: true }) {
    canvas.onContextMenu.listen((Event e) => e.preventDefault());
    gl = createContext3d();
    _timePerFrame = 1 / (1000.0 / frameRate);
    _timePerTick = 1 / (1000.0 / tickRate);
    _useAnimFrame = useAnimFrame;
    _useDeltaTime = useDeltaTime;

    if (_touchSupport == null)
      _touchSupport = new JsObject.fromBrowserObject(window).hasProperty("ontouchstart");

    if (!_touchSupport) {
      _subscribeMouseAndKeyEvents();
    } else {
      touchStartHandler(evt) {
        var p = _getTouchPoint(evt);
        _onMouseDown(p.x, p.y, 0);
        evt.preventDefault();
      }

      touchEndHandler(evt) {
        var p = _getTouchPoint(evt);
        _onMouseUp(p.x, p.y, 0);
        _onMouseMove(-1, -1);
        evt.preventDefault();
      }

      touchMoveHandler(evt) {
        var p = _getTouchPoint(evt);
        _onMouseMove(p.x, p.y);
        evt.preventDefault();
      }

      var target = useWindowTouchEvents ? window : canvas;
      var tStart = target.onTouchStart.listen(touchStartHandler);
      var tEnd   = target.onTouchEnd.listen(touchEndHandler);
      var tMove  = target.onTouchMove.listen(touchMoveHandler);

      //There's no reliable way to detect presence of mouse hardware,
      //so if we receive a mouse move event we assume the user
      //has a mouse and disable the built-in touch support.
      canvas.onMouseMove.first.then((_) {
        tStart.cancel();
        tEnd.cancel();
        tMove.cancel();
        _subscribeMouseAndKeyEvents();
      });
    }
  }

  /**
   * Adds mouse down/up/move & key down/up listeners to the canvas for the game
   */
  void _subscribeMouseAndKeyEvents() {
    canvas.onMouseDown.listen((evt) {
      var p = _transformEventPoint(evt.offset);
      _onMouseDown(p.x, p.y, evt.button);
    });
    canvas.onMouseUp.listen((evt) {
      var p = _transformEventPoint(evt.offset);
      _onMouseUp(p.x, p.y, evt.button);
    });
    canvas.onMouseMove.listen((evt) {
      var p = _transformEventPoint(evt.offset);
      _onMouseMove(p.x, p.y);
    });
    canvas.onKeyDown.listen((evt) {
      _onKeyDown(evt.keyCode);
    });
    canvas.onKeyUp.listen((evt) {
      _onKeyUp(evt.keyCode);
    });
  }

  /**
   * Transforms browser event coordinates to game event coordinates
   */
  Point _transformEventPoint(Point p) {
    int x = (p.x * canvasScale * mousePosScale).toInt();
    int y = (p.y * canvasScale * mousePosScale).toInt();
    return new Point(x, y);
  }

  /**
   * Gets the position of `evt.changedTouches[0]` in game event coordinates.
   */
  Point _getTouchPoint(evt) {
    //This directly accesses the JS objects to work around a bug with CocoonJS
    //which causes errors when going through Dart
    JsObject ev = new JsObject.fromBrowserObject(evt);
    JsObject touch = new JsObject.fromBrowserObject(ev["changedTouches"][0]);
    Point offset = new Point(touch["clientX"], touch["clientY"]) - canvas.client.topLeft;
    return _transformEventPoint(offset);
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
      var timer;
      void startNewTimer() {
        var duration = new Duration(milliseconds: (1 / _timePerFrame).floor());
        timer = new Timer.periodic(duration,
          (_) => _renderCallback(Time.timeMillis.toDouble()));
      }
      startNewTimer();
      window.onFocus.listen((_) {
        if (!timer.isActive) {
          timer.cancel();
          startNewTimer();
        }
      });
      window.onBlur.listen((_) => timer.cancel());
    }
  }

  void _renderCallback(double time) {
    if (_useAnimFrame)
      window.animationFrame.then(_renderCallback);
    if (_lastTime == -1)
      _lastTime = time;
    double dif = time - _lastTime;
    //Missed more than a second just do 1 calc
    if (dif > 1000.0)
      _missedTicks++;
    else
      _missedTicks += dif * _timePerTick;
    _lastTime = time;

    //Don't tolerate more than 10 ticks missed
    if (_missedTicks > 10)
      _missedTicks = 10.0;
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
    _frameTime = Time.timeMillis;
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

  /**
   * Invert the Y coordinate if [invertMouseY] is set
   */
  int _invertIfNeeded(int y) {
    if (invertMouseY)
      return (canvas.height * mousePosScale).toInt() - y - 1;
    else
      return y;
  }

  void _onMouseDown(int x, int y, int btn) {
    _mouseX = x;
    _mouseY = _invertIfNeeded(y);
    _mouseButtons[btn] = 1;
    mouseDown(_mouseX, _mouseY, btn);
    _mouseDownController.add(new GameMouseEvent(_mouseX, _mouseY, btn));
  }

  void _onMouseUp(int x, int y, int btn) {
    _mouseX = x;
    _mouseY = _invertIfNeeded(y);
    _mouseButtons[btn] = 0;
    mouseUp(_mouseX, _mouseY, btn);
    _mouseUpController.add(new GameMouseEvent(_mouseX, _mouseY, btn));
  }

  void _onMouseMove(int x, int y) {
    _mouseX = x;
    _mouseY = _invertIfNeeded(y);
    mouseMove(_mouseX, _mouseY);
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
   * The percent of a game computation tick that has elapsed since the last
   * tick. For example, of a game has 1 computation tick every 50 milliseconds,
   * and the a frame renders 20 milliseconds after the last computation tick,
   * [partialTick] will be 0.4. If useDeltaTime was set to true in the
   * constructor, this will always be 0.0
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
  static int get frameTime => _frameTime;


}

/**
 * Returns the next power of 2 number that comes after [val].
 * If [val] is a power of 2, returns [val]
 */
int nextPowerOf2(int val) {
  int powof2 = 1;
  while (powof2 < val)
    powof2 <<= 1;
  return powof2;
}

/**
 * Sets the VertexAttribArray [array] to be either enabled or disabled based
 * on [active]
 */
void setVertexAttribArray(WebGL.RenderingContext gl, int array, bool active) {
  if (active)
    gl.enableVertexAttribArray(array);
  else
    gl.disableVertexAttribArray(array);
}

/**
 * Sets the state of something that can be glEnabled or glDisabled to [state]
 */
void setGLState(WebGL.RenderingContext gl, int glEnum, bool state) {
  if (state)
    gl.enable(glEnum);
  else
    gl.disable(glEnum);
}

class GameMouseEvent {
  int x, y, button;
  GameMouseEvent(this.x, this.y, this.button);
}

class GameKeyboardEvent {
  int key;
  GameKeyboardEvent(this.key);
}
