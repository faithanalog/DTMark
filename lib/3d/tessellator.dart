part of dtmark;

class Tessellator extends VertexBatch {

  Tessellator(WebGL.RenderingContext gl) : super(gl, [new VertexAttrib(0, 3), //Position
      new VertexAttrib(1, 2), //tex coords
      new VertexAttrib(2, 4), //color
      new VertexAttrib(3, 3)] /*normals*/) {
    _shader = getTessShader(gl);
    useTexture = false;
    useColor = false;
    useNormals = false;
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

  @override
  void begin() {
    super.begin();
    if (!useColor) {
      gl.vertexAttrib4f(2, 1.0, 1.0, 1.0, 1.0);
    }
  }

  set texture(Texture tex) {
    if (tex == null) {
      _switchTexture(_whiteTex);
    } else {
      _switchTexture(tex);
    }
  }

  set useTexture(bool useTex) {
    _attribs[1].active = useTex;
  }

  set useColor(bool useCol) {
    _attribs[2].active = useCol;
  }

  set useNormals(bool useNorm) {
    _attribs[3].active = useNorm;
  }

  bool get useTexture => _attribs[1].active;

  bool get useColor => _attribs[2].active;

  bool get useNormals => _attribs[3].active;

  /**
   * The current shader program used when rendering the batch. Setting
   * this will not affect anything until the next time [begin] is called.
   * Setting this to null will reset the shader to the default Tessellator
   * shader.
   */
  @override
  set shader(Shader shader) {
    if (shader == null) {
      _shader = _tessShader;
    } else {
      _shader = shader;
    }
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
          const AttribLocation(2, "a_color")
        ]);
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

varying vec2 v_texCoord;
varying vec4 v_color;

void main() {
  v_texCoord = a_texCoord;
  v_color = a_color;
  gl_Position = u_transform * vec4(a_position, 1.0);
}
""";

  /**
   * GLSL code of the default fragment shader
   */
  static const String FRAG_SHADER =
"""
precision mediump float;
uniform sampler2D u_texture;

varying vec2 v_texCoord;
varying vec4 v_color;

void main() {
  vec4 color = texture2D(u_texture, v_texCoord) * v_color;
  if (color.a == 0.0) {
    discard;
  }
  gl_FragColor = color;
}
""";
}
