part of dtmark;

class Tessellator extends VertexBatch {

  List<VertexAttrib> _vertAttribs = [new VertexAttrib(0, 3), //Position
      new VertexAttrib(1, 2), //tex coords
      new VertexAttrib(2, 4), //color
      new VertexAttrib(3, 3)]; //normals

  Tessellator(WebGL.RenderingContext gl) : super(gl _vertAttribs) {

  }

  void vertexUV(double x, double y, double z, double u, double v) {
    _flushIfNeeded();
    verts[_vOff + 0] = x;
    verts[_vOff + 1] = y;
    verts[_vOff + 2] = z;
    _vOff += 3;
    if (useTexture) {
      verts[_vOff + 0] = u;
      verts[_vOff + 1] = v;
      _vOff += 2;
    }
    if (useColor) {
      verts[_vOff + 0] = color.r;
      verts[_vOff + 1] = color.g;
      verts[_vOff + 2] = color.b;
      verts[_vOff + 3] = color.a;
      _vOff += 4;
    }
    if (useNormals) {
      verts[_vOff + 0] = 0.0;
      verts[_vOff + 1] = 0.0;
      verts[_vOff + 2] = 0.0;
      _vOff += 3;
    }
  }

  void vertex(double x, double y, double z) {
    vertexUV(x, y, z, 0.0, 0.0);
  }

  set useTexture(bool useTex) {
    _vertAttribs[1].active = useTex;
  }

  set useColor(bool useCol) {
    _vertAttribs[2].active = useCol;
  }

  set useNormals(bool useNorm) {
    _vertAttribs[3].active = useNorm;
  }

  bool get useTexture => _vertAttribs[1].active;

  bool get useColor => _vertAttribs[2].active;

  bool get useNormals => _vertAttribs[3].active;

}
