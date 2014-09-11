part of dtmark;

class Material {

  Vector4 color = new Vector4(1.0, 1.0, 1.0, 1.0);
  bool transparent = false;
  bool blend = false;
  int blendSrc = WebGL.SRC_ALPHA;
  int blendDst = WebGL.ONE_MINUS_SRC_ALPHA;
  int blendEqu = WebGL.FUNC_ADD;
  bool depthTest = true;
  bool depthWrite = true;
  bool visible = true;

}
