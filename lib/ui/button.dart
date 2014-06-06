part of dtmark;

class Button extends TextComponent {
  
  StreamController<ButtonClickEvent> _clickController = new StreamController();
  bool _clicked = false;
  
  
  Button([String text = ""]) {
    fontSize = 16;
    height = fontSize + 6;
    
    this.text = text;
    if (text.isNotEmpty) {
      font.scale = fontSize / font.size;
      width = font.getWidth(text).floor() + 6;
    }
  }
  
  @override
  void render(SpriteBatch batch) {
    bool hasMouse = containsMouse();
    if (_clicked && !hasMouse) {
      _clicked = false;
    }
    
    font.scale = fontSize / font.size;
    batch.begin();
    batch.color.setValues(0.6, 0.6, 0.6, 1.0);
    batch.fillRect(0.0, 0.0, width.toDouble(), height.toDouble());
    if (_clicked) {
      batch.color.setValues(0.7, 0.7, 0.7, 1.0);
    } else if (hasMouse) {
      batch.color.setValues(0.8, 0.8, 0.8, 1.0);
    } else {
      batch.color.setValues(0.95, 0.95, 0.95, 1.0);
    }
    batch.fillRect(1.0, 1.0, width.toDouble() - 2, height.toDouble() - 2);
    batch.color.setValues(0.0, 0.0, 0.0, 1.0);
    font.drawStringCentered(batch, text, (width >> 1).toDouble(), ((height - font.getHeight()) / 2).floorToDouble());
    batch.end();
  }
  
  @override
  _mouseDown(MouseDownEvent evt) {
    super._mouseDown(evt);
    _clicked = true;
  }
  
  @override
  _mouseUp(MouseUpEvent evt) {
    super._mouseUp(evt);
    if (_clicked) {
      _clickController.add(new ButtonClickEvent(this));
      _clicked = false;
    }
  }
  
  Stream<ButtonClickEvent> get onClick => _clickController.stream;
  
}

class ButtonClickEvent extends UIEvent {
  
  ButtonClickEvent(Component src): super(src);
  
}