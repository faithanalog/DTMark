part of dtmark;

abstract class UIEvent {
  
  final Component source;
  
  UIEvent(this.source);
  
}

abstract class DTMouseEvent extends UIEvent {
  
  final int x, y;
  DTMouseEvent(Component source, this.x, this.y): super(source);
  
}

class MouseDownEvent extends DTMouseEvent {
  final int button;
  MouseDownEvent(Component src, int x, int y, this.button): super(src, x, y);
}

class MouseUpEvent extends DTMouseEvent {
  final int button;
  MouseUpEvent(Component src, int x, int y, this.button): super(src, x, y);
}

class MouseMoveEvent extends DTMouseEvent {
  MouseMoveEvent(Component src, int x, int y): super(src, x, y);
}

abstract class KeyEvent extends UIEvent {
  
  final int key;
  KeyEvent(Component src, this.key): super(src);
  
}

class KeyDownEvent extends KeyEvent {
  KeyDownEvent(Component src, int key): super(src, key);
}

class KeyUpEvent extends KeyEvent {
  KeyUpEvent(Component src, int key): super(src, key);
}