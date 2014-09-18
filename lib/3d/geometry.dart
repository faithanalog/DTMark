part of dtmark;

class Geometry {

  Float32List vertices;
  Matrix4 transform = null;
  bool hasTexture = false;
  bool hasColor = false;
  bool hasNormals = false;

  /**
   * Must be set to true whenever [vertices] are modified, or the changed
   * will not be sent to the GPU
   */
  bool needsUpdate = false;

  /**
   * Any children will be rendered when [render] is called
   */
  List<Geometry> children = new List();

  WebGL.RenderingContext _gl;
  WebGL.Buffer _vertBuff;

  Geometry(WebGL.RenderingContext gl, [Float32List verts = null]) {
    _gl = gl;
    _vertBuff = gl.createBuffer();
    this.vertices = verts;
    needsUpdate = true;
  }

  WebGL.RenderingContext get gl => _gl;

  int get vertSize {
    int size = 3;
    if (hasTexture) size += 2;
    if (hasColor) size += 4;
    if (hasNormals) size += 3;
    return size;
  }

  /**
   * Multiplies all vertices by [transform] and then sets [transform] to null
   */
  void bakeTransform() {
    int stride = vertSize;
    //Avoid lots of ram allocs during transformations
    Vector4 invec = new Vector4.zero();
    Vector4 outvec = new Vector4.zero();
    for (int i = 0; i < vertices.length; i += stride) {
      var x = vertices[i];
      var y = vertices[i + 1];
      var z = vertices[i + 2];
      invec.setValues(x, y, z, 1.0);
      transform.transformed(invec, outvec);
      vertices[i] = outvec.x;
      vertices[i + 1] = outvec.y;
      vertices[i + 2] = outvec.z;
    }
    transform = null;
    needsUpdate = true;
  }

  /**
   * Renders the vertices with glDrawArrays. Uses attribArray 0 for position, 1
   * for texture, 2 for color, and 3 for normals. [transform]
   * has no effect when using this method. It is up to the caller to
   * set the proper uniforms with the value of [transform].
   * It is also up to the caller to enable the required attrib arrays
   * before calling this method.
   */
  void render() {
    gl.bindBuffer(WebGL.ARRAY_BUFFER, _vertBuff);
    if (needsUpdate) {
      gl.bufferDataTyped(WebGL.ARRAY_BUFFER, vertices, WebGL.STATIC_DRAW);
    }
    int stride = vertSize * 4;
    int offs = 0;
    gl.vertexAttribPointer(0, 3, WebGL.FLOAT, false, stride, offs);
    offs += 12;
    if (hasTexture) {
      gl.vertexAttribPointer(1, 2, WebGL.FLOAT, false, stride, offs);
      offs += 8;
    }
    if (hasColor) {
      gl.vertexAttribPointer(2, 4, WebGL.FLOAT, false, stride, offs);
      offs += 16;
    }
    if (hasNormals) {
      gl.vertexAttribPointer(3, 3, WebGL.FLOAT, false, stride, offs);
    }
    gl.drawArrays(WebGL.TRIANGLES, 0, vertices.length ~/ vertSize);
  }
}
