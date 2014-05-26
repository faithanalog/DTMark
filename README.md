DTMark
===
This is a basic library to make it simpler to start making a game. It
has support for a tick rate independant of framerate (more useful in the
future when it provides a partial tick value for rendering), input
handling, texture loading, and rendering of basic colored and textured
rectangles. It also has a built in font renderer, with an included low res
font as well as the ability to generate a font on the fly.
It does not handle a lack of webgl support, that must be handled by the game
for now.

Usage
---
To start, simply make a class that extends BaseGame. Then instantiate it and
call launchGame on it. Here is an example.
```dart
import 'package:dtmark/dtmark.dart' as DTMark;

class Game extends DTMark.BaseGame {

  //Canvas with id game_canvas is in the html.
  //frameRate and tickRate are in frames/ticks per second.
  Game(): super(querySelector("#game_canvas"), frameRate: 60.0, tickRate: 60.0);
  
  @override
  void launchGame() {
    //Initialize game stuff
    
    //Starts the game
    super.launchGame();
  }
  
  @override
  void render() {
    //Render your game. You are NOT guranteed to render as many frames
    //as you specified each second, so don't use this for code anything
    //that relies on a constant rate of being called. Use tick() instead.
  }
  
  @override
  void tick() {
    //Do all calculations here. DTMark will do it's best to have as many
    //calls to tick per second as specified by the tickRate, but if a
    //computer running the game is too slow the tick rate WILL decrease.
  }
  
  //Input listeners are automatically added to the canvas provided
  //to the constructor. They will call these methods so just override
  //them. Be sure to call the super method, or the built in key state
  //and mouse state tracking will not work!
  @override
  void onKeyDown(KeyboardEvent evt) {
    super.onKeyDown(evt);
  }
  
  @override
  void onKeyUp(KeyboardEvent evt) {
    super.onKeyUp(evt);
  }
  
  @override
  void onMouseDown(MouseEvent evt) {
    super.onMouseDown(evt);
  }
  
  @override
  void onMouseUp(MouseEvent evt) {
    super.onMouseUp(evt);
  }
  
  @override
  void onMouseMove(MouseEvent evt) {
    super.onMouseMove(evt);
  }
}

void main() {
  new Game().launchGame();
}
```