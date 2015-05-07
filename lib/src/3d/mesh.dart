part of dtmark;

class Mesh {

  Float32List vertices;
  List<VertexAttrib> vAttribs;
  List<Mesh> children = [];
  Matrix4 transform;

  Mesh({this.vertices:  null,
        this.vAttribs:  null,
        this.transform: null}) {
    if (vAttribs == null)
      vAttribs = [];
  }

  int get vertSize => vAttribs.fold(0, (a, x) => a + x.size);

  /**
   * Multiplies all vertices by [transform] and then sets [transform] to null.
   * Recursively applies to children.
   */
  void bakeTransform() {
    int stride = vertSize;
    //Avoid lots of ram allocs during transformations
    Vector4 invec  = new Vector4.zero();
    Vector4 outvec = new Vector4.zero();
    for (int i = 0; i < vertices.length; i += stride) {
      var x = vertices[i];
      var y = vertices[i + 1];
      var z = vertices[i + 2];
      invec.setValues(x, y, z, 1.0);
      transform.transformed(invec, outvec);
      vertices[i]     = outvec.x;
      vertices[i + 1] = outvec.y;
      vertices[i + 2] = outvec.z;
    }
    for (final x in children) {
      x.transform = transform * x.transform;
      x.bakeTransform();
    }
    transform = null;
  }

}
