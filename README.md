DTMark
===
This is a basic library to make it simpler to start making a game. It
has support for a tick rate independant of framerate, input handling,
texture loading, and rendering of basic colored and textured
rectangles. It also has a built in font renderer, with an included low res
font as well as the ability to generate a font on the fly.
It does not handle a lack of webgl support, that must be handled by the game
for now.

Do keep in mind that this is a work in progress and not really fit for widespead use.
Breaking changes can and will happen, and I'm not documenting
anything just yet.

Usage
---
To start, simply make a class that extends BaseGame. Then instantiate it and
call launchGame on it. Here is a basic example.
```dart
import 'package:dtmark/dtmark.dart' as DTMark;
import 'dart:html';

class Game extends DTMark.BaseGame {

  //Canvas with id game_canvas is in the hypothetical html.
  //frameRate and tickRate are in frames/ticks per second.
  Game(): super(document.getElementById("game_canvas"), frameRate: 60.0, tickRate: 60.0);
  
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
  //to the constructor. They will call these methods so just override them.
  @override
  void keyDown(int key) {
  }
  
  @override
  void keyUp(int key) {
  }
}

void main() {
  new Game().launchGame();
}
```