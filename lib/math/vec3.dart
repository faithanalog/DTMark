part of dtmark;

class Vec3 {
  
  double x, y, z;
  
  Vec3(this.x, this.y, this.z);
  
  Vec3.zero() {
    x = y = z = 0.0;
  }
  
  Vec3.fromVec2(Vec2 o) {
    x = o.x;
    y = o.y;
    z = 0.0;
  }
  
  Vec3 set(Vec3 o) {
    x = o.x;
    y = o.y;
    z = o.z;
    return this;
  }
  
  Vec3 setVals(double x, double y, double z) {
    this.x = x;
    this.y = y;
    this.z = z;
    return this;
  }
  
  Vec3 add(Vec3 o) {
    x += o.x;
    y += o.y;
    z += o.z;
    return this;
  }
  
  Vec3 sub(Vec3 o) {
    x -= o.x;
    y -= o.y;
    z -= o.z;
    return this;
  }
  
  Vec3 mult(Vec3 o) {
    x *= o.x;
    y *= o.y;
    z *= o.z;
    return this;
  }
  
  Vec3 scale(double scalar) {
    x *= scalar;
    y *= scalar;
    z *= scalar;
    return this;
  }
  
  Vec3 normalize() {
    return scale(1 / length);
  }
  
  double dot(Vec3 o) {
    return x * o.x + y * o.y + z * o.z;
  }
  
  Vec3 cross(Vec3 o) {
    return new Vec3(y * o.z - z * o.y,
                    z * o.x - x * o.z,
                    x * o.y - y * o.x);
  }
  
  Vec3 clone() {
    return new Vec3(x, y, z);
  }
  
  Vec3 transform(Mat4 o) {
    double tx = o.storage[0] * x + o.storage[4] * y + o.storage[8] * z + o.storage[12];
    double ty = o.storage[1] * x + o.storage[5] * y + o.storage[9] * z + o.storage[13];
    double tz = o.storage[2] * x + o.storage[6] * y + o.storage[10] * z + o.storage[14];
    double tw = (1 / o.storage[3] * x + o.storage[7] * y + o.storage[11] * z + o.storage[15]);
    
    x = tx * tw;
    y = ty * tw;
    z = tz * tw;
    return this;
  }
  
  double get length => Math.sqrt(lengthSq);
  
  double get lengthSq => x * x + y * y + z * z;
  
}