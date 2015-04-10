part of dtmark;

/**
 * The 3D equivelant of sprite batch, allows simple rendering of 3d
 * content by uploading vertices on the fly. This is not an effecient
 * way to render static 3d content, and you should consider storing
 * your static terrain/models in vertex buffers yourself.
 *
 * Later versions will allow you to add vertices to a
 * tessellator and automatically generate a buffer from
 * them. Technically you can already do this, but it requires more effort
 */
class Tessellator extends VertexBatch {

  /**
   * Current normal vector used when adding vertices
   */
  Vector3 normal = new Vector3(0.0, 0.0, 0.0);

  Tessellator(WebGL.RenderingContext gl) : super(gl, [new VertexAttrib(0, 3), //Position
      new VertexAttrib(1, 2), //tex coords
      new VertexAttrib(2, 1), //texture unit
      new VertexAttrib(3, 4), //color
      new VertexAttrib(4, 3),] /*normals*/, quadInput: true) {
    //Quad input is passed to super() as true, but then immediately set to
    //false. This is because the indices are not generated unless quad input
    //is initially passed in as true, but I want the default mode to be
    //triangles
    _shader = getTessShader(gl);
    _quadInput = false;
    useTexture = false;
    useColor = false;
    useNormals = false;
  }

  /**
   * Adds a vertex to the tessellator with the given texture coords
   */
  void vertexUV(double x, double y, double z, double u, double v) {
    _flushIfNeeded();
    verts[_vOff + 0] = x;
    verts[_vOff + 1] = y;
    verts[_vOff + 2] = z;
    _vOff += 3;
    if (useTexture) {
      verts[_vOff + 0] = u;
      verts[_vOff + 1] = v;
      verts[_vOff + 2] = _currentTexUnit.toDouble();
      _vOff += 3;
    }
    if (useColor) {
      verts[_vOff + 0] = color.r;
      verts[_vOff + 1] = color.g;
      verts[_vOff + 2] = color.b;
      verts[_vOff + 3] = color.a;
      _vOff += 4;
    }
    if (useNormals) {
      verts[_vOff + 0] = normal.x;
      verts[_vOff + 1] = normal.y;
      verts[_vOff + 2] = normal.z;
      _vOff += 3;
    }
  }

  /**
   * Adds a vertex to the tessellator with texture coords of (0.0, 0.0)
   */
  void vertex(double x, double y, double z) {
    vertexUV(x, y, z, 0.0, 0.0);
  }

  @override
  void begin() {
    super.begin();
    if (!useTexture) {
      gl.vertexAttrib1f(2, 0.0);
      gl.activeTexture(WebGL.TEXTURE0);
      _whiteTex.bind();
    }
    if (!useColor) {
      //Vertex attribute location 2 is a vec4 storing the current color
      gl.vertexAttrib4f(3, 1.0, 1.0, 1.0, 1.0);
    }
  }

  /**
   * Begins saving vertices, but does not set up GL state for rendering
   */
  void beginSaving() {
    _vOff = 0;
  }

  /**
   * Save the current vertices as a new Geometry. If [bakeModelView] is true,
   * each position will be transformed with the modelView matrix before
   * being saved.
   */
  Geometry save([bool bakeModelView = false]) {
    Float32List geomVerts = null;
    if (useQuads) {
      //TODO: triangulate faces
    } else {
      geomVerts = new Float32List(_vOff);
      for (int i = 0; i < _vOff; i++) {
        geomVerts[i] = verts[i];
      }
    }
    _vOff = 0;
    Geometry geom = new Geometry(gl, geomVerts);
    geom.hasTexture = useTexture;
    geom.hasColor = useColor;
    geom.hasNormals = useNormals;
    geom.transform = modelView.clone();
    if (bakeModelView) {
      geom.bakeTransform();
    }
    return geom;
  }

  /**
   * Renders some geometry. Don't call between [begin] and [end]
   */
  void renderGeometry(Geometry geom) {
    _shader.use();
    _transform.setFrom(_projection);
    _transform.multiply(_modelView);
    if (geom.transform != null)
      _transform.multiply(geom.transform);

    _shader.setUniformMatrix4fv("u_transform", false, _transform);

    if (geom.hasTexture) {
      //TODO?
    } else {
      gl.vertexAttrib1f(2, 0.0);
      gl.activeTexture(WebGL.TEXTURE0);
      _whiteTex.bind();
    }

    //Set color (attribute 2) to white if geometry shouldn't be colored
    if (!geom.hasColor)
      gl.vertexAttrib4f(2, 1.0, 1.0, 1.0, 1.0);

    gl.enableVertexAttribArray(0);
    if (geom.hasTexture) {
      gl.enableVertexAttribArray(1);
      gl.enableVertexAttribArray(2);
    }
    if (geom.hasColor)
      gl.enableVertexAttribArray(3);
    if (geom.hasNormals)
      gl.enableVertexAttribArray(4);

    geom.render();

    gl.disableVertexAttribArray(0);
    if (geom.hasTexture) {
      gl.disableVertexAttribArray(1);
      gl.disableVertexAttribArray(2);
    }
    if (geom.hasColor)
      gl.disableVertexAttribArray(3);
    if (geom.hasNormals)
      gl.disableVertexAttribArray(4);
  }

  set texture(Texture tex) {
    _switchTexture(tex == null ? _whiteTex : tex);
  }

  set useTexture(bool useTex) {
    _attribs[1].active = useTex;
    _attribs[2].active = useTex;
  }

  set useColor(bool useCol) {
    _attribs[3].active = useCol;
  }

  set useNormals(bool useNorm) {
    _attribs[4].active = useNorm;
  }

  set useQuads(bool useQuads) {
    _quadInput = useQuads;
  }

  /**
   * Whether or not texture coordinates should be used
   */
  bool get useTexture => _attribs[1].active;

  /**
   * Whether or not color should be used. If false, color will default to white
   */
  bool get useColor => _attribs[3].active;

  /**
   * Whether or not normals should be used
   */
  bool get useNormals => _attribs[4].active;

  /**
   * Whether or not the input vertices will be interpreted as quads. If false,
   * they will be considered triangles
   */
  bool get useQuads => _quadInput;

  /**
   * The current shader program used when rendering the batch. Setting
   * this will not affect anything until the next time [begin] is called.
   * Setting this to null will reset the shader to the default Tessellator
   * shader.
   */
  @override
  set shader(Shader shader) {
    _shader = shader == null ? _tessShader : shader;
  }

  static Shader _tessShader;

  /**
   * Returns the default SpriteBatch shader. Creates it if it doesn't exist yet.
   */
  static Shader getTessShader(WebGL.RenderingContext gl) {
    if (_tessShader == null) {
      _tessShader = new Shader(VERT_SHADER, FRAG_SHADER, gl,
        name: "SpriteBatch Shader", attribLocs: const [
          const AttribLocation(0, "a_position"),
          const AttribLocation(1, "a_texCoord"),
          const AttribLocation(2, "a_color"),
          const AttribLocation(3, "a_texture")
        ]);
      _tessShader.use();
      gl.uniform1iv(_tessShader.getUniformLoc("u_texture"),
          new Int32List.fromList(new Iterable.generate(32).toList()));
    }
    return _tessShader;
  }

  /**
   * GLSL code of the default vertex shader
   */
  static const String VERT_SHADER =
"""
uniform mat4 u_transform;

attribute vec3 a_position;
attribute vec2 a_texCoord;
attribute vec4 a_color;
attribute float a_texture;

varying vec2 v_texCoord;
varying vec4 v_color;
varying int  v_texture;

void main() {
  v_texCoord = a_texCoord;
  v_color = a_color;
  v_texture = int(a_texture);
  gl_Position = u_transform * vec4(a_position, 1.0);
}
""";

  /**
   * GLSL code of the default fragment shader
   */
  static const String FRAG_SHADER =
"""
precision mediump float;
uniform sampler2D u_texture[32];

varying vec2 v_texCoord;
varying vec4 v_color;
varying int  v_texture;

void main() {
  vec4 color = texture2D(u_texture[v_texture], v_texCoord) * v_color;
  if (color.a == 0.0) {
    discard;
  }
  gl_FragColor = color;
}
""";
}
