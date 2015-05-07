part of dtmark;

/**
 * Base event class for UI events in DTMark
 */
abstract class UIEvent {

  final Component source;

  UIEvent(this.source);

}

/**
 * Base mouse event
 */
abstract class DTMouseEvent extends UIEvent {

  /**
   * X position of the mouse event
   */
  final int x;

  /**
   * Y position of the mouse event
   */
  final int y;
  DTMouseEvent(Component source, this.x, this.y): super(source);

}

/**
 * Event fired when a mouse button is pressed
 */
class MouseDownEvent extends DTMouseEvent {

  /**
   * The affected mouse button
   */
  final int button;
  MouseDownEvent(Component src, int x, int y, this.button): super(src, x, y);
}

/**
 * Event fired when a mouse button is released
 */
class MouseUpEvent extends DTMouseEvent {

  /**
   * The affected mouse button
   */
  final int button;
  MouseUpEvent(Component src, int x, int y, this.button): super(src, x, y);
}

/**
 * Event fired when the mouse is moved
 */
class MouseMoveEvent extends DTMouseEvent {
  MouseMoveEvent(Component src, int x, int y): super(src, x, y);
}

/**
 * Base key event
 */
abstract class KeyEvent extends UIEvent {

  /**
   * The affected keyboard key
   */
  final int key;
  KeyEvent(Component src, this.key): super(src);

}

/**
 * Event fired when a key is pressed
 */
class KeyDownEvent extends KeyEvent {
  KeyDownEvent(Component src, int key): super(src, key);
}

/**
 * Event fired when a key is released
 */
class KeyUpEvent extends KeyEvent {
  KeyUpEvent(Component src, int key): super(src, key);
}
