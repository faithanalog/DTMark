part of dtmark;

abstract class MeshRenderer {

  WebGL.RenderingContext _gl;

  MeshRenderer(WebGL.RenderingContext gl) {
    _gl = gl;
  }

  WebGL.RenderingContext get gl => _gl;

  /**
   * Set up initial state for rendering meshes
   */
  void begin();

  /**
   * Disable state for rendering meshes
   */
  void end();

  /**
   * Render a mesh with its material
   */
  void renderMesh(Mesh mesh);

}

/**
 * Basic mesh renderer that supports colors, blending, and depth testing
 */
class BasicMeshRenderer extends MeshRenderer {

  bool _blend = false;
  int _blendSrc = WebGL.SRC_ALPHA;
  int _blendDst = WebGL.ONE_MINUS_SRC_ALPHA;
  bool _depthTest = true;

  bool _texEnabled = false;
  bool _colEnabled = false;
  bool _normEnabled = false;

  Shader _shader;
  Matrix4 _projection = new Matrix4.identity();
  Matrix4 _modelView = new Matrix4.identity();
  Matrix4 _transform = new Matrix4.identity();

  //Identity matrix, should not be modified
  Matrix4 _ident = new Matrix4.identity();

  /**
   * A 1x1 pixel texture which is white. Used for rendering solid blocks of color
   */
  Texture _whiteTex;
  Texture _lastTex = null;

  BasicMeshRenderer(WebGL.RenderingContext gl) : super(gl) {
    _shader = getMeshShader(gl);
    _whiteTex = new Texture(null, gl);
    gl.texImage2DTyped(WebGL.TEXTURE_2D, 0, WebGL.RGBA, 1, 1, 0, WebGL.RGBA, WebGL.UNSIGNED_BYTE, new Uint8List.fromList([255, 255, 255, 255]));

    _lastTex = _whiteTex;
  }

  @override
  void begin() {
    _blend = false;
    _blendSrc = WebGL.SRC_ALPHA;
    _blendDst = WebGL.ONE_MINUS_SRC_ALPHA;
    _depthTest = true;

    _shader.use();
    _transform.setFrom(_projection);
    _transform.multiply(_modelView);
    _shader.setUniformMatrix4fv("u_transform", false, _transform);
    _shader.setUniform1i("u_texture", 0);

    gl.disable(WebGL.BLEND);
    gl.blendFunc(_blendSrc, _blendDst);
    gl.enable(WebGL.DEPTH_TEST);

    gl.enableVertexAttribArray(0);
    _texEnabled = false;
    _colEnabled = false;
    _normEnabled = false;
  }

  @override
  void end() {
    gl.disable(WebGL.BLEND);
    gl.disable(WebGL.DEPTH_TEST);
    gl.disableVertexAttribArray(0);
    if (_texEnabled) gl.disableVertexAttribArray(1);
    if (_colEnabled) gl.disableVertexAttribArray(2);
    if (_normEnabled) gl.disableVertexAttribArray(3);
  }

  @override
  void renderMesh(Mesh mesh) {
    var material = mesh.material;
    if (!material.visible) {
      return;
    }
    if (_blend != material.blend) {
      _blend = material.blend;
      setGLState(gl, WebGL.BLEND, _blend);
    }
    if (_blendSrc != material.blendSrc || _blendDst != material.blendDst) {
      _blendSrc = material.blendSrc;
      _blendDst = material.blendDst;
      gl.blendFunc(_blendSrc, _blendDst);
    }
    if (_depthTest != material.depthTest) {
      _depthTest = material.depthTest;
      setGLState(gl, WebGL.DEPTH_TEST, _depthTest);
    }
    var color = material.color;
    var pos = mesh.position;
    var rot = mesh.rotation;
    _shader.setUniform4f("u_meshColor", color.r, color.g, color.b, color.a);

    _shader.setUniform3f("u_meshPosition", pos.x, pos.y, pos.z);
    if (rot.x == 0 && rot.y == 0 && rot.z == 0) {
      _shader.setUniformMatrix4fv("u_transform", false, _transform);
    } else {
      var meshTransform = new Matrix4.rotationX(rot.x).rotateY(rot.y).rotateZ(rot.z);
      _shader.setUniformMatrix4fv("u_transform", false, _transform * meshTransform);
    }
    if (material.texture == null) {
      _switchTexture(_whiteTex);
    } else {
      _switchTexture(material.texture);
    }
    _renderGeometry(mesh.geometry);
  }

  void _switchTexture(Texture tex) {
    if (_lastTex != tex) {
      tex.bind();
      _lastTex = tex;
    }
  }

  void _renderGeometry(Geometry geom) {
    _shader.setUniformMatrix4fv("u_geomTransform", false, geom.transform == null ? _ident : geom.transform);

    if (geom.hasTexture != _texEnabled) {
      _texEnabled = geom.hasTexture;
      setVertexAttribArray(gl, 1, _texEnabled);
    }

    if (geom.hasColor != _colEnabled) {
      _colEnabled = geom.hasColor;
      setVertexAttribArray(gl, 2, _colEnabled);
      if (!_colEnabled) {
        gl.vertexAttrib4f(2, 1.0, 1.0, 1.0, 1.0);
      }
    }

    if (geom.hasNormals != _normEnabled) {
      _normEnabled = geom.hasNormals;
      setVertexAttribArray(gl, 3, _normEnabled);
    }

    geom.render();
    if (!geom.children.isEmpty) {
      for (final child in geom.children) {
        _renderGeometry(child);
      }
    }
  }

  set projection(Matrix4 proj) {
    if (proj == null) {
      _projection = new Matrix4.identity();
    } else {
      _projection = proj;
    }
  }

  set modelView(Matrix4 mview) {
    if (mview == null) {
      _modelView = new Matrix4.identity();
    } else {
      _modelView = mview;
    }
  }

  set shader(Shader shader) {
    if (shader == null) {
      _shader = _meshShader;
    } else {
      _shader = shader;
    }
  }

  /**
   * The current shader program used when rendering the batch. Setting
   * this will not affect anything until the next time [begin] is called.
   */
  Shader get shader => _shader;

  /**
   * The current projection matrix. Setting this will not affect anything
   * until the next time [begin] is called.
   *
   *     projection = null;
   * is equivelant to
   *     projection = new Matrix4.identity();
   */
  Matrix4 get projection => _projection;

  /**
   * The current modelView matrix. Setting this will not affect anything
   * until the next time [begin] is called.
   *
   *     modelView = null;
   * is equivelant to
   *     modelView = new Matrix4.identity();
   */
  Matrix4 get modelView => _modelView;

  static Shader _meshShader;

  static Shader getMeshShader(WebGL.RenderingContext gl) {
    if (_meshShader == null) {
      _meshShader = new Shader(VERT_SHADER, FRAG_SHADER, gl,
        name: "Basic Mesh Shader", attribLocs: const [
          const AttribLocation(0, "a_position"),
          const AttribLocation(1, "a_texCoord"),
          const AttribLocation(2, "a_color")
        ]);
    }
    return _meshShader;
  }

  /**
   * GLSL code of the default vertex shader
   */
  static const String VERT_SHADER =
"""
uniform mat4 u_transform;
uniform mat4 u_geomTransform;
uniform vec3 u_meshPosition;

attribute vec3 a_position;
attribute vec2 a_texCoord;
attribute vec4 a_color;

varying vec2 v_texCoord;
varying vec4 v_color;

void main() {
  v_texCoord = a_texCoord;
  v_color = a_color;
  gl_Position = u_transform * u_geomTransform * vec4(a_position + u_meshPosition, 1.0);
}
""";

  /**
   * GLSL code of the default fragment shader
   */
  static const String FRAG_SHADER =
"""
precision mediump float;
uniform sampler2D u_texture;
uniform vec4 u_meshColor;

varying vec2 v_texCoord;
varying vec4 v_color;

void main() {
  vec4 color = texture2D(u_texture, v_texCoord) * v_color * u_meshColor;
  if (color.a == 0.0) {
    discard;
  }
  gl_FragColor = color;
}
""";

}