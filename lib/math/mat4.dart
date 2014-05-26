part of dtmark;
class Mat4 {
  
  //To get an element from [row, column] access storage[row + (column * 4)]
  Float32List storage = new Float32List(16); 
  
  //Notation of parameters is row, column.
  Mat4(double m00, double m01, double m02, double m03,
      double m10, double m11, double m12, double m13,
      double m20, double m21, double m22, double m23,
      double m30, double m31, double m32, double m33) {
    Float32List s = storage;
    s[0] = m00; s[4] = m01; s[8]  = m02; s[12] = m03;
    s[1] = m10; s[5] = m11; s[9]  = m12; s[13] = m13;
    s[2] = m20; s[6] = m21; s[10] = m22; s[14] = m23;
    s[3] = m30; s[7] = m31; s[11] = m32; s[15] = m33;
  }
  
  Mat4.fromList(Iterable<double> storage) {
    this.storage.setAll(0, storage);
  }
  
  Mat4.identity() {
    storage[0] = 1.0;
    storage[5] = 1.0;
    storage[10] = 1.0;
    storage[15] = 1.0;
  }
  
  factory Mat4.translation(Vec3 vec) {
    return new Mat4.translationVals(vec.x, vec.y, vec.z);
  }
  
  factory Mat4.translationVals(double x, double y, double z) {
    Mat4 m = new Mat4.identity();
    m.storage[12] = x;
    m.storage[13] = y;
    m.storage[14] = z;
    return m;
  }
  
  factory Mat4.scaling(Vec3 vec) {
    return new Mat4.scalingVals(vec.x, vec.y, vec.z);
  }
  
  Mat4.scalingVals(double x, double y, double z) {
    storage[0] = x;
    storage[5] = y;
    storage[10] = z;
    storage[15] = 1.0;
  }
  
  factory Mat4.rotationX(double radians) {
    double sin = Math.sin(radians);
    double cos = Math.cos(radians);
    return new Mat4(
        1.0, 0.0,  0.0, 0.0,
        0.0, cos, -sin, 0.0,
        0.0, sin,  cos, 0.0,
        0.0, 0.0,  0.0, 1.0);
  }
  
  factory Mat4.rotationY(double radians) {
    double sin = Math.sin(radians);
    double cos = Math.cos(radians);
    return new Mat4(
         cos, 0.0, sin, 0.0,
         0.0, 1.0, 0.0, 0.0,
        -sin, 0.0, cos, 0.0,
         0.0, 0.0, 0.0, 1.0);
  }
  
  factory Mat4.rotationZ(double radians) {
    double sin = Math.sin(radians);
    double cos = Math.cos(radians);
    return new Mat4(
        cos, -sin, 0.0, 0.0,
        sin,  cos, 0.0, 0.0,
        0.0,  0.0, 1.0, 0.0,
        0.0,  0.0, 0.0, 1.0);
  }
  
  Mat4.orthographic(double left, double right, double bottom, double top, double near, double far) {
    //width, height, depth of view plane reciprocals (since code divides by them twice)
    double w = 1.0 / (right - left);
    double h = 1.0 / (top - bottom);
    double d = 1.0 / (far - near);
    storage[0] = 2 * w;
    storage[5] = 2 * h;
    storage[10] -2 * d;
    storage[12] = -(right + left) * w;
    storage[13] = -(top + bottom) * h;
    storage[14] = -(far + near) * d;
    storage[15] = 1.0;
  }
  
  Mat4.frustum(double left, double right, double bottom, double top, double near, double far) {
    //width, height, depth of view plane reciprocals (since code divides by them twice)
    double w = 1.0 / (right - left);
    double h = 1.0 / (top - bottom);
    double d = 1.0 / (far - near);
    storage[0] = near * 2 * w;
    storage[5] = near * 2 * h;
    storage[8] = (left + right) * w;
    storage[9] = (top + bottom) * h;
    storage[10] = -(far + near) * d;
    storage[11] = -1.0;
    storage[14] = -(far * near * 2) * d;
  }
  
  //FOV is in radians!
  factory Mat4.perspective(double fov, double aspectRatio, double near, double far) {
    double top = near * Math.tan(fov / 2.0);
    double right = top * aspectRatio;
    return new Mat4.frustum(-right, right, -top, top, near, far);
  }
  
  Mat4 add(Mat4 o) {
    Float32List l = storage;
    Float32List r = o.storage;
    l[0] += r[0];
    l[1] += r[1];
    l[2] += r[2];
    l[3] += r[3];
    l[4] += r[4];
    l[5] += r[5];
    l[6] += r[6];
    l[7] += r[7];
    l[8] += r[8];
    l[9] += r[9];
    l[10] += r[10];
    l[11] += r[11];
    l[12] += r[12];
    l[13] += r[13];
    l[14] += r[14];
    l[15] += r[15];
    return this;
  }
  
  Mat4 negate() {
    Float32List s = storage;
    s[0] *= -1;
    s[1] *= -1;
    s[2] *= -1;
    s[3] *= -1;
    s[4] *= -1;
    s[5] *= -1;
    s[6] *= -1;
    s[7] *= -1;
    s[8] *= -1;
    s[9] *= -1;
    s[10] *= -1;
    s[11] *= -1;
    s[12] *= -1;
    s[13] *= -1;
    s[14] *= -1;
    s[15] *= -1;
    return this;
  }
  
  Mat4 sub(Mat4 o) {
    Float32List l = storage;
    Float32List r = o.storage;
    l[0] -= r[0];
    l[1] -= r[1];
    l[2] -= r[2];
    l[3] -= r[3];
    l[4] -= r[4];
    l[5] -= r[5];
    l[6] -= r[6];
    l[7] -= r[7];
    l[8] -= r[8];
    l[9] -= r[9];
    l[10] -= r[10];
    l[11] -= r[11];
    l[12] -= r[12];
    l[13] -= r[13];
    l[14] -= r[14];
    l[15] -= r[15];
    return this;
  }
  
  Mat4 mult(Mat4 o) {
    Float32List l = storage;
    Float32List r = o.storage;
    
    double m00 = l[0] * r[0] + l[4] * r[1] + l[8]  * r[2] + l[12] * r[3];
    double m10 = l[1] * r[0] + l[5] * r[1] + l[9]  * r[2] + l[13] * r[3];
    double m20 = l[2] * r[0] + l[6] * r[1] + l[10] * r[2] + l[14] * r[3];
    double m30 = l[3] * r[0] + l[7] * r[1] + l[11] * r[2] + l[15] * r[3];
    
    double m01 = l[0] * r[4] + l[4] * r[5] + l[8]  * r[6] + l[12] * r[7];
    double m11 = l[1] * r[4] + l[5] * r[5] + l[9]  * r[6] + l[13] * r[7];
    double m21 = l[2] * r[4] + l[6] * r[5] + l[10] * r[6] + l[14] * r[7];
    double m31 = l[3] * r[4] + l[7] * r[5] + l[11] * r[6] + l[15] * r[7];
    
    double m02 = l[0] * r[8] + l[4] * r[9] + l[8]  * r[10] + l[12] * r[11];
    double m12 = l[1] * r[8] + l[5] * r[9] + l[9]  * r[10] + l[13] * r[11];
    double m22 = l[2] * r[8] + l[6] * r[9] + l[10] * r[10] + l[14] * r[11];
    double m32 = l[3] * r[8] + l[7] * r[9] + l[11] * r[10] + l[15] * r[11];
    
    double m03 = l[0] * r[12] + l[4] * r[13] + l[8]  * r[14] + l[12] * r[15];
    double m13 = l[1] * r[12] + l[5] * r[13] + l[9]  * r[14] + l[13] * r[15];
    double m23 = l[2] * r[12] + l[6] * r[13] + l[10] * r[14] + l[14] * r[15];
    double m33 = l[3] * r[12] + l[7] * r[13] + l[11] * r[14] + l[15] * r[15];
    
    l[0] = m00; l[4] = m01; l[8]  = m02; l[12] = m03;
    l[1] = m10; l[5] = m11; l[9]  = m12; l[13] = m13;
    l[2] = m20; l[6] = m21; l[10] = m22; l[14] = m23;
    l[3] = m30; l[7] = m31; l[11] = m32; l[15] = m33;
    return this;
  }
  
  Mat4 transpose() {
    Float32List s = storage;
    
    double m10 = s[4];
    double m20 = s[8];
    double m30 = s[12];
    double m21 = s[9];
    double m31 = s[13];
    double m32 = s[14];
    
    s[4]  = s[1];
    s[8]  = s[2];
    s[12] = s[3];
    s[9]  = s[6];
    s[13] = s[7];
    s[14] = s[11];
    
    s[1]  = m10;
    s[2]  = m20;
    s[3]  = m30;
    s[6]  = m21;
    s[7]  = m31;
    s[11] = m32;
    return this;
  }
  
  Mat4 multScalar(double scalar) {
    Float32List s = storage;
    s[0] *= scalar;
    s[1] *= scalar;
    s[2] *= scalar;
    s[3] *= scalar;
    s[4] *= scalar;
    s[5] *= scalar;
    s[6] *= scalar;
    s[7] *= scalar;
    s[8] *= scalar;
    s[9] *= scalar;
    s[10] *= scalar;
    s[11] *= scalar;
    s[12] *= scalar;
    s[13] *= scalar;
    s[14] *= scalar;
    s[15] *= scalar;
    return this;
  }
  
  Mat4 translate(Vec3 vec) {
    return translateVals(vec.x, vec.y, vec.z);
  }
  
  Mat4 translateVals(double x, double y, double z) {
    Float32List s = storage;
    s[12] += s[0] * x + s[4] * y + s[8] * z;
    s[13] += s[1] * x + s[5] * y + s[9] * z;
    s[14] += s[2] * x + s[6] * y + s[10] * z;
    s[15] += s[3] * x + s[7] * y + s[11] * z;
    return this;
  }
  
  Mat4 scale(Vec3 vec) {
    return scaleVals(vec.x, vec.y, vec.z);
  }
  
  Mat4 scaleVals(double x, double y, double z) {
    Float32List s = storage;
    s[0] *= x;
    s[1] *= x;
    s[2] *= x;
    s[3] *= x;
    
    s[4] *= y;
    s[5] *= y;
    s[6] *= y;
    s[7] *= y;
    
    s[8] *= z;
    s[9] *= z;
    s[10] *= z;
    s[11] *= z;
    return this;
  }
  
  //TODO Implement rotating matrices without allocating new ones
  Mat4 rotateX(double radians) {
    return mult(new Mat4.rotationX(radians));
  }
  
  Mat4 rotateY(double radians) {
    return mult(new Mat4.rotationY(radians));
  }
  
  Mat4 rotateZ(double radians) {
    return mult(new Mat4.rotationZ(radians));
  }
  
  Mat4 clone() {
    return new Mat4.fromList(storage);
  }
  
  double get m00 => storage[0];
  double get m10 => storage[1];
  double get m20 => storage[2];
  double get m30 => storage[3];
  double get m01 => storage[4];
  double get m11 => storage[5];
  double get m21 => storage[6];
  double get m31 => storage[7];
  double get m02 => storage[8];
  double get m12 => storage[9];
  double get m22 => storage[10];
  double get m32 => storage[11];
  double get m03 => storage[12];
  double get m13 => storage[13];
  double get m23 => storage[14];
  double get m33 => storage[15];
  
  set m00(double val) => storage[0] = val;
  set m10(double val) => storage[1] = val;
  set m20(double val) => storage[2] = val;
  set m30(double val) => storage[3] = val;
  set m01(double val) => storage[4] = val;
  set m11(double val) => storage[5] = val;
  set m21(double val) => storage[6] = val;
  set m31(double val) => storage[7] = val;
  set m02(double val) => storage[8] = val;
  set m12(double val) => storage[9] = val;
  set m22(double val) => storage[10] = val;
  set m32(double val) => storage[11] = val;
  set m03(double val) => storage[12] = val;
  set m13(double val) => storage[13] = val;
  set m23(double val) => storage[14] = val;
  set m33(double val) => storage[15] = val;
  
}