library dtmark;

import 'dart:html';
import 'dart:convert';
import 'dart:math' as Math;
import 'dart:typed_data';
import 'dart:web_gl' as WebGL;
import 'dart:web_audio' as Audio;
import 'dart:async';
import 'package:vector_math/vector_math.dart';

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

abstract class BaseGame {
  
  CanvasElement canvas;
  WebGL.RenderingContext gl;
  
  double _timePerFrame;
  double _timePerTick;
  double _missedFrames = 0.0;
  double _missedTicks = 0.0;
  
  double _lastTime = -1.0;
  
  Int32List _keys = new Int32List(256);
  Int32List _mouseButtons = new Int32List(32);
  int _mouseX = 0;
  int _mouseY = 0;
  
  bool invertMouseY = false;
  
  BaseGame(this.canvas, {double frameRate: 60.0, double tickRate: 60.0}) {
    canvas.onContextMenu.listen((Event e) => e.preventDefault());
    gl = createContext3d();
    _timePerFrame = 1 / (1000.0 / frameRate);
    _timePerTick = 1 / (1000.0 / tickRate);
    canvas.onMouseDown.listen(onMouseDown);
    canvas.onMouseUp.listen(onMouseUp);
    canvas.onMouseMove.listen(onMouseMove);
    canvas.onKeyDown.listen(onKeyDown);
    canvas.onKeyUp.listen(onKeyUp);
  }
  
  /**
   * Creates the WebGL context. Override this to customize attributes of the context
   */
  WebGL.RenderingContext createContext3d() {
    return canvas.getContext3d();
  }
  
  void launchGame() {
    window.animationFrame.then(_renderCallback);
  }
  
  void _renderCallback(double time) {
    window.animationFrame.then(_renderCallback);
    if (_lastTime == -1) {
      _lastTime = time;
    }
    double dif = time - _lastTime;
    //Missed more than a second just do 1 calc
    if (dif > 1000.0) {
      _missedTicks++;
      _missedFrames++;
    } else {
      _missedTicks += dif * _timePerTick;
      _missedFrames += dif * _timePerFrame;
    }
    _lastTime = time;
    
    //Don't tolerate more than 10 ticks missed
    if (_missedTicks > 10) {
      _missedTicks = 10.0;
    }
    while (_missedTicks >= 1.0) {
      tick();
      _missedTicks--;
    }
    //Only render once no matter how many frames missed
    if (_missedFrames >= 1.0) {
      render();
      _missedFrames -= _missedFrames.floor();
    }
  }
  
  void render() {
    
  }
  
  void tick() {
    
  }
  
  void onKeyDown(KeyboardEvent evt) {
    _keys[evt.keyCode] = 1;
  }
  
  void onKeyUp(KeyboardEvent evt) {
    _keys[evt.keyCode] = 0;
  }
  
  void onMouseDown(MouseEvent evt) {
    Point off = evt.offset;
    _mouseX = off.x;
    _mouseY = off.y;
    if (invertMouseY) {
      _mouseY = canvas.height - _mouseY;
    }
    _mouseButtons[evt.button] = 1;
  }
  
  void onMouseUp(MouseEvent evt) {
    Point off = evt.offset;
    _mouseX = off.x;
    _mouseY = off.y;
    if (invertMouseY) {
      _mouseY = canvas.height - _mouseY;
    }
    _mouseButtons[evt.button] = 0;
  }
  
  void onMouseMove(MouseEvent evt) {
    Point off = evt.offset;
    _mouseX = off.x;
    _mouseY = off.y;
    if (invertMouseY) {
      _mouseY = canvas.height - _mouseY;
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
  
}

int nextPowerOf2(int val) {
  int powof2 = 1;
  while (powof2 < val) {
    powof2 <<= 1;
  }
  return powof2;
}