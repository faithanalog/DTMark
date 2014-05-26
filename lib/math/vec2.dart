part of dtmark;

class Vec2 {
  
  double x, y;
  
  Vec2(this.x, this.y);
  
  Vec2.zero() {
    x = 0.0;
    y = 0.0;
  }
  
  Vec2 set(Vec2 o) {
    x = o.x;
    y = o.y;
    return this;
  }
  
  Vec2 setVals(double x, double y) {
    this.x = x;
    this.y = y;
    return this;
  }
  
  Vec2 add(Vec2 o) {
    x += o.x;
    y += o.y;
    return this;
  }
  
  Vec2 sub(Vec2 o) {
    x -= o.x;
    y -= o.y;
    return this;
  }
  
  Vec2 mult(Vec2 o) {
    x *= o.x;
    y *= o.y;
    return this;
  }
  
  Vec2 scale(double scalar) {
    x *= scalar;
    y *= scalar;
    return this;
  }
  
  Vec2 normalize() {
    return scale(1 / length);
  }
  
  double dot(Vec2 o) {
    return x * o.x + y * o.y;
  }

  Vec2 clone() {
    return new Vec2(x, y);
  }
  
  double get length => Math.sqrt(lengthSq);
  
  double get lengthSq => x * x + y * y;
  
}