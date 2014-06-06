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

//part 'math/vec2.dart';
//part 'math/vec3.dart';
//part 'math/vec4.dart';
//
//part 'math/mat4.dart';

//WebGL stuff
part 'gl/shader.dart';
part 'gl/texture.dart';

//2D stuff
part '2d/spritebatch.dart';
part '2d/fontrenderer.dart';

//Camera
part 'camera.dart';

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
  
  /**
   * canvasResolution / windowResolution
   * So if the clientWidth is 100 and the canvas.width is 200, canvasScale would be 2.0
   */
  double canvasScale = 1.0;
  
  /**
   * All mouse coordinates are multiplied by this.
   */
  double mousePosScale = 1.0;
  
  Int32List _keys = new Int32List(256);
  Int32List _mouseButtons = new Int32List(32);
  int _mouseX = 0;
  int _mouseY = 0;
  bool _useAnimFrame;
  bool _useDeltaTime;
  
  bool invertMouseY = false;
  
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
        onMouseDown((evt.offset.x * canvasScale * mousePosScale).toInt(), (evt.offset.y * canvasScale * mousePosScale).toInt(), evt.button);
      });
      canvas.onMouseUp.listen((evt) {
        onMouseUp((evt.offset.x * canvasScale * mousePosScale).toInt(), (evt.offset.y * canvasScale * mousePosScale).toInt(), evt.button);
      });
      canvas.onMouseMove.listen((evt) {
        onMouseMove((evt.offset.x * canvasScale * mousePosScale).toInt(), (evt.offset.y * canvasScale * mousePosScale).toInt());
      });
      canvas.onKeyDown.listen((evt) {
        onKeyDown(evt.keyCode);
      });
      canvas.onKeyUp.listen((evt) {
        onKeyUp(evt.keyCode);
      });
    } else {
      //Done through JS stuff to support cocoonjs
      canvas.onTouchStart.listen((evt) {
        JsObject ev = new JsObject.fromBrowserObject(evt);
        JsObject touch = new JsObject.fromBrowserObject(ev["changedTouches"][0]);
        Point offset = new Point(touch["clientX"], touch["clientY"]) - canvas.client.topLeft;
        onMouseDown((offset.x * canvasScale * mousePosScale).toInt(), (offset.y * canvasScale * mousePosScale).toInt(), 0);
        evt.preventDefault();
      });
      canvas.onTouchEnd.listen((evt) {
        JsObject ev = new JsObject.fromBrowserObject(evt);
        JsObject touch = new JsObject.fromBrowserObject(ev["changedTouches"][0]);
        Point offset = new Point(touch["clientX"], touch["clientY"]) - canvas.client.topLeft;
        onMouseUp((offset.x * canvasScale * mousePosScale).toInt(), (offset.y * canvasScale * mousePosScale).toInt(), 0);
        evt.preventDefault();
      });
      canvas.onTouchMove.listen((evt) {
        JsObject ev = new JsObject.fromBrowserObject(evt);
        JsObject touch = new JsObject.fromBrowserObject(ev["changedTouches"][0]);
        Point offset = new Point(touch["clientX"], touch["clientY"]) - canvas.client.topLeft;
        onMouseMove((offset.x * canvasScale * mousePosScale).toInt(), (offset.y * canvasScale * mousePosScale).toInt());
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
    render();
  }
  
  void render() {
    
  }
  
  void tick() {
    
  }
  
  void onKeyDown(int key) {
    _keys[key] = 1;
  }
  
  void onKeyUp(int key) {
    _keys[key] = 0;
  }
  
  void onMouseDown(int x, int y, int btn) {
    _mouseX = x;
    _mouseY = y;
    if (invertMouseY) {
      _mouseY = (canvas.height * mousePosScale).toInt() - _mouseY;
    }
    _mouseButtons[btn] = 1;
  }
  
  void onMouseUp(int x, int y, int btn) {
    _mouseX = x;
    _mouseY = y;
    if (invertMouseY) {
      _mouseY = (canvas.height * mousePosScale).toInt() - _mouseY;
    }
    _mouseButtons[btn] = 0;
  }
  
  void onMouseMove(int x, int y) {
    _mouseX = x;
    _mouseY = y;
    if (invertMouseY) {
      _mouseY = (canvas.height * mousePosScale).toInt() - _mouseY;
    }
  }
  
  bool isKeyDown(int key) {
    return _keys[key & 0xFF] != 0;
  }
  
  bool isMouseDown(int btn) {
    return _mouseButtons[btn & 0x1F] != 0;
  }
  
  int get mouseX => _mouseX;
  int get mouseY => _mouseY;
  double get partialTick => _partialTick;
  double get deltaTime => _deltaTime;
  
}

int nextPowerOf2(int val) {
  int powof2 = 1;
  while (powof2 < val) {
    powof2 <<= 1;
  }
  return powof2;
}