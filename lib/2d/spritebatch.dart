part of dtmark;

//TODO: Add Z index (make it a vert attrib) so that things don't have to be painter's algorithim. good idea? maybe...
/**
 * A sprite batcher than will queue up sprites and draw them all in one draw
 * call. Not as effecient as pre-loading vertices to a buffer object,
 * but better than doing one draw call per sprite. This is convenient for
 * drawing anything that moves on the screen, or something dynamic like text,
 * but it may be ineffecient for static data like tiles in a tile based game.
 */
class SpriteBatch extends VertexBatch {

  /**
   * Constructs a new SpriteBatch with the given rendering context [gl].
   * If [width] and [height] are provided, they will be used to create
   * a default orthographic matrix for the projection matrix with
   * (0,0) as the bottom left corner, and (width - 1, height - 1) as the
   * top right corner. If [width] and [height] are not provided,
   * [projection] should be set manually.
   */
  SpriteBatch(WebGL.RenderingContext gl, {int width: 1, int height: 1}) : super(gl, [new VertexAttrib(0, 2),
      new VertexAttrib(1, 2),
      new VertexAttrib(2, 4)], quadInput: true) {

    _shader = getBatchShader(gl);
    _projection = makeOrthographicMatrix(0, width, 0, height, -1, 1);
  }

  /**
   * Adds a vertex with the given values to the vert buffer, flushing
   * the buffer if it's full.
   */
  void _addVert(double x, double y, double u, double v) {
    _flushIfNeeded();
    verts[_vOff + 0] = x;
    verts[_vOff + 1] = y;
    verts[_vOff + 2] = u;
    verts[_vOff + 3] = v;
    verts[_vOff + 4] = color.r;
    verts[_vOff + 5] = color.g;
    verts[_vOff + 6] = color.b;
    verts[_vOff + 7] = color.a;
    _vOff += 8;
  }

  //Vertex 0 is top left, Vertex 1 is bottom right
  /**
   * Adds a quad to the vert buffer with [_addVert].
   * [x0], [y0], [u0], and [v0] refer to the top left corner, while
   * [x1], [y1], [u1], and [v1] refer tothe bottom right corner.
   */
  void _addQuad(double x0, double y0, double u0, double v0, double x1, double y1, double u1, double v1) {

    //NEW: Top left, bottom left, bottom right, top right
    _addVert(x0, y0, u0, v0);
    _addVert(x0, y1, u0, v1);
    _addVert(x1, y1, u1, v1);
    _addVert(x1, y0, u1, v0);
  }

  /**
   * Fills a rectangle with the current color
   */
  void fillRect(double x, double y, double width, double height) {
    drawTexture(_whiteTex, x, y, width, height);
  }

  /**
   * Draws [tex] at ([x], [y]) with dimensions ([width], [height]) or
   * the the dimensions of [tex] if size is not specified.
   */
  void drawTexture(Texture tex, double x, double y, [double width, double height]) {
    _switchTexture(tex);
    if (width == null) {
      width = tex.width.toDouble();
    }
    if (height == null) {
      height = tex.height.toDouble();
    }
    _addQuad(x, y + height, 0.0, 0.0, x + width, y, 1.0, 1.0);
  }

  /**
   * Draws [texRegion] at ([x], [y]) with dimensions
   * ([width], [height]) or the dimensions of [texRegion] if
   * size is not specified.
   */
  void drawRegion(TextureRegion texRegion, double x, double y, [double width, double height]) {
    if (width == null) {
      width = texRegion.width.toDouble();
    }
    if (height == null) {
      height = texRegion.height.toDouble();
    }
    drawTexRegion(texRegion.texture, x, y, width, height, texRegion.x, texRegion.y, texRegion.width, texRegion.height);
  }

  /**
   * Draws [tex] at ([x], [y]) at [scale] times the original size.
   */
  void drawTexScaled(Texture tex, double x, double y, double scale) {
    drawTexture(tex, x, y, tex.width * scale, tex.height * scale);
  }

  /**
  * Draws a region of [tex] at ([x], [y]) with dimensions ([width], [height]).
  * [texX] and [texY] define the upper left corner of the texture region
  * in pixels. [texWidth] and [texHeight] define the width and height of
  * the texture region in pixels.
  */
  void drawTexRegion(Texture tex, double x, double y, double width, double height, int texX, int texY, int texWidth, int texHeight) {
    double w = 1 / tex.width;
    double h = 1 / tex.height;
    double u0 = texX * w;
    double v0 = texY * h;
    double u1 = u0 + texWidth * w;
    double v1 = v0 + texHeight * h;
    drawTexRegionUV(tex, x, y, width, height, u0, v0, u1, v1);
  }

  /**
   * Draws a region of [tex] at ([x], [y]) with dimensions ([width], [height]).
   * ([u0], [v0]) defines the upper left corner of the texture region in UV
   * coordinates. ([u1], [v1]) defines the bottom right corner.
   */
  void drawTexRegionUV(Texture tex, double x, double y, double width, double height, double u0, double v0, double u1, double v1) {
    _switchTexture(tex);
    _addQuad(x, y + height, u0, v0, x + width, y, u1, v1);
  }

  /**
   * Draws the current frame of the animation [anim] at ([x], [y]). Dimensions
   * are ([width], [height]), or the dimensions of [anim] if size is not specified.
   */
  void drawAnimation(SpriteAnimation anim, double x, double y, [double width, double height]) {
    drawRegion(anim.texRegion, x, y, width, height);
  }

  /**
   * The current shader program used when rendering the batch. Setting
   * this will not affect anything until the next time [begin] is called.
   * Setting this to null will reset the shader to the default SpriteBatch
   * shader.
   */
  @override
  set shader(Shader shader) {
    if (shader == null) {
      _shader = _batchShader;
    } else {
      _shader = shader;
    }
  }

  static Shader _batchShader;

  /**
   * Returns the default SpriteBatch shader. Creates it if it doesn't exist yet.
   */
  static Shader getBatchShader(WebGL.RenderingContext gl) {
    if (_batchShader == null) {
      _batchShader = new Shader(VERT_SHADER, FRAG_SHADER, gl,
        name: "SpriteBatch Shader", attribLocs: const [
          const AttribLocation(0, "a_position"),
          const AttribLocation(1, "a_texCoord"),
          const AttribLocation(2, "a_color")
        ]);
    }
    return _batchShader;
  }

  /**
   * GLSL code of the default vertex shader
   */
  static const String VERT_SHADER =
"""
uniform mat4 u_transform;

attribute vec2 a_position;
attribute vec2 a_texCoord;
attribute vec4 a_color;

varying vec2 v_texCoord;
varying vec4 v_color;

void main() {
  v_texCoord = a_texCoord;
  v_color = a_color;
  gl_Position = u_transform * vec4(a_position, 0.0, 1.0);
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
