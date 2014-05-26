part of dtmark;

class Vec4 {
  
  double x, y, z, w;
  
  Vec4(this.x, this.y, this.z, this.w);
  
  Vec4.zero() {
    x = 0.0;
    y = 0.0;
    z = 0.0;
    w = 0.0;
  }
  
  Vec4.fromVec2(Vec2 o) {
    x = o.x;
    y = o.y;
    z = 0.0;
    w = 1.0;
  }
  
  Vec4.fromVec3(Vec3 o) {
    x = o.x;
    y = o.y;
    z = o.z;
    w = 1.0;
  }
  
  Vec4 set(Vec4 o) {
    x = o.x;
    y = o.y;
    z = o.z;
    w = o.w;
    return this;
  }
  
  Vec4 setVals(double x, double y, double z, double w) {
    this.x = x;
    this.y = y;
    this.z = z;
    this.w = w;
    return this;
  }
  
  Vec4 add(Vec4 o) {
    x += o.x;
    y += o.y;
    z += o.z;
    w += o.w;
    return this;
  }
  
  Vec4 sub(Vec4 o) {
    x -= o.x;
    y -= o.y;
    z -= o.z;
    w -= o.w;
    return this;
  }
  
  Vec4 mult(Vec4 o) {
    x *= o.x;
    y *= o.y;
    z *= o.z;
    w *= o.w;
    return this;
  }
  
  Vec4 scale(double scalar) {
    x *= scalar;
    y *= scalar;
    z *= scalar;
    w *= scalar;
    return this;
  }
  
  Vec4 normalize() {
    return scale(1 / length);
  }
  
  double dot(Vec4 o) {
    return x * o.x + y * o.y + z * o.z + w * o.w;
  }
  
  Vec4 clone() {
    return new Vec4(x, y, z, w);
  }
  
  Vec4 transform(Mat4 o) {
    double tx = o.storage[0] * x + o.storage[4] * y + o.storage[8] * z + o.storage[12] * w;
    double ty = o.storage[1] * x + o.storage[5] * y + o.storage[9] * z + o.storage[13] * w;
    double tz = o.storage[2] * x + o.storage[6] * y + o.storage[10] * z + o.storage[14] * w;
    w = o.storage[3] * x + o.storage[7] * y + o.storage[11] * z + o.storage[15] * w;
    x = tx;
    y = ty;
    z = tz;
    return this;
  }
  
  double get length => Math.sqrt(lengthSq);
  
  double get lengthSq => x * x + y * y + z * z + w * w;
  
}