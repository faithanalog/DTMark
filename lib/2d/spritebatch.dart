part of dtmark;

//TODO: Add Z index (make it a vert attrib) so that things don't have to be painter's algorithim. good idea? maybe...
/**
 * A sprite batcher than will queue up sprites and draw them all in one draw
 * call. Not as effecient as pre-loading vertices to a buffer object,
 * but better than doing one draw call per sprite. This is convenient for
 * drawing anything that moves on the screen, or something dynamic like text,
 * but it may be ineffecient for static data like tiles in a tile based game.
 */
class SpriteBatch {

  //Max 65536 verts before flush
  /**
   * The max number of verts to store in ram before rendering.
   * Defaults to 65536, can be changed if needed. Changes affect
   * all SpriteBatches created after the change.
   */
  static int BATCH_MAX_VERTS = 65536;

  //X,Y,U,V,R,G,B,A
  /**
   * The array used to store verts while batching.
   */
  final Float32List verts = new Float32List(8 * BATCH_MAX_VERTS);

  /**
   * WebGL context associated with this SpriteBatch
   */
  final WebGL.RenderingContext gl;

  /**
   * WebGL buffer used for vertices
   */
  WebGL.Buffer _buffer;

  /**
   * WebGL buffer used for indices
   */
  WebGL.Buffer _indices;

  Shader _shader;

  /**
   * A 1x1 pixel texture which is white. Used for rendering solid blocks of color
   */
  Texture _whiteTex;
  Texture _lastTex = null;

  /**
   * Color used when rendering anything with the SpriteBatch. Changing
   * this will affect anything drawn after it is changed.
   */
  Vector4 color = new Vector4(1.0, 1.0, 1.0, 1.0);
  int _vOff = 0;
  int _vOffMax = 8 * BATCH_MAX_VERTS;


  //Max vertices we've actually used, we'll use this for buffer streaming so we dont use tons of vram
  int _maxVertsUsed = 0;

  Matrix4 _projection;
  Matrix4 _modelView;
  Matrix4 _transform = new Matrix4.identity();
  bool _rendering = false;

  bool _texChanged = false;

  /**
   * Constructs a new SpriteBatch with the given rendering context [gl].
   * If [width] and [height] are provided, they will be used to create
   * a default orthographic matrix for the projection matrix with
   * (0,0) as the bottom left corner, and (width - 1, height - 1) as the
   * top right corner. If [width] and [height] are not provided,
   * [projection] should be set manually.
   */
  SpriteBatch(this.gl, {int width: 1, int height: 1}) {
    _shader = getBatchShader(gl);
    _buffer = gl.createBuffer();

    //Generate indices
    var indData = new Uint16List(6 * BATCH_MAX_VERTS ~/ 4);
    var index = 0;
    for (var i = 0; i < indData.length; i += 6) {
      indData[i + 0] = index;
      indData[i + 1] = index + 1;
      indData[i + 2] = index + 2;
      indData[i + 3] = index + 2;
      indData[i + 4] = index + 3;
      indData[i + 5] = index;
      index += 4;
    }
    _indices = gl.createBuffer();
    gl.bindBuffer(WebGL.ELEMENT_ARRAY_BUFFER, _indices);
    gl.bufferDataTyped(WebGL.ELEMENT_ARRAY_BUFFER, indData, WebGL.STATIC_DRAW);
    gl.bindBuffer(WebGL.ELEMENT_ARRAY_BUFFER, null);


    _whiteTex = new Texture(null, gl);
    gl.texImage2DTyped(WebGL.TEXTURE_2D, 0, WebGL.RGBA, 1, 1, 0, WebGL.RGBA, WebGL.UNSIGNED_BYTE, new Uint8List.fromList([255, 255, 255, 255]));

    _projection = makeOrthographicMatrix(0, width, 0, height, -1, 1);
    _modelView = new Matrix4.identity();
    _lastTex = _whiteTex;
  }

  /**
   * Adds a vertex with the given values to the vert buffer, flushing
   * the buffer if it's full.
   */
  void _addVert(double x, double y, double u, double v) {
    if (_vOff >= _vOffMax) {
      _flush();
    }
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
   * Renders the current buffered vertices with the current texture, and
   * then switches the current texture to [tex]. If the current texture
   * already is [tex], then does nothing.
   */
  void _switchTexture(Texture tex) {
    if (_lastTex != tex) {
      _flush();
      _texChanged = true;
      _lastTex = tex;
    }
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
    if (width == null) {
      width = anim.width.toDouble();
    }
    if (height == null) {
      height = anim.height.toDouble();
    }
    drawTexRegion(anim.animationFrames, x, y, width, height, anim.frameX, anim.frameY, anim.width, anim.height);
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
      _shader = _batchShader;
    } else {
      _shader = shader;
    }
  }

  /**
   * The current shader program used when rendering the batch. Setting
   * this will not affect anything until the next time [begin] is called.
   * Setting this to null will reset the shader to the default SpriteBatch
   * shader.
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

  /**
   * Sets up the state required to render the sprite batch, including
   * the current shader, transform matrix, and texture.
   */
  void begin() {
    _rendering = true;
    _texChanged = true;
    _shader.use();
    _transform.setFrom(_projection);
    _transform.multiply(_modelView);
    _shader.setUniformMatrix4fv("u_transform", false, _transform);
    _shader.setUniform1i("u_texture", 0);

    gl.enableVertexAttribArray(0);
    gl.enableVertexAttribArray(1);
    gl.enableVertexAttribArray(2);

    gl.bindBuffer(WebGL.ARRAY_BUFFER, _buffer);
    gl.bindBuffer(WebGL.ELEMENT_ARRAY_BUFFER, _indices);
    gl.vertexAttribPointer(0, 2, WebGL.FLOAT, false, 32, 0);
    gl.vertexAttribPointer(1, 2, WebGL.FLOAT, false, 32, 8);
    gl.vertexAttribPointer(2, 4, WebGL.FLOAT, false, 32, 16);
  }

  /**
   * Flushes any remaining vertices from the SpriteBatch, unbinds the
   * buffer bound to ELEMENT_ARRAY_BUFFER, and disables vertix attrib
   * arrays 0, 1, and 2.
   */
  void end() {
    _flush();
    gl.bindBuffer(WebGL.ELEMENT_ARRAY_BUFFER, null);
    gl.disableVertexAttribArray(0);
    gl.disableVertexAttribArray(1);
    gl.disableVertexAttribArray(2);
    _rendering = false;
  }

  /**
   * Renders all vertices buffered in the SpriteBatch
   */
  void flush() {
      _flush();
  }

  void _flush() {
    if (_vOff > 0) {
      if (_texChanged) {
        if (_lastTex != null) {
          _lastTex.bind();
        }
        _texChanged = false;
      }
      gl.bufferDataTyped(WebGL.ARRAY_BUFFER, new Float32List.view(verts.buffer, 0, _vOff), WebGL.STREAM_DRAW);
      gl.drawElements(WebGL.TRIANGLES, (_vOff ~/ 8 ~/ 4 * 6), WebGL.UNSIGNED_SHORT, 0);
    }
    _vOff = 0;
  }

  static Shader _batchShader;

  /**
   * Returns the default SpriteBatch shader. Creates it if it doesn't exist yet.
   */
  static Shader getBatchShader(WebGL.RenderingContext gl) {
    if (_batchShader == null) {
      _batchShader = new Shader(VERT_SHADER, FRAG_SHADER, gl);
      _batchShader.bindAttribLocation(0, "a_position");
      _batchShader.bindAttribLocation(1, "a_texCoord");
      _batchShader.bindAttribLocation(2, "a_color");
      _batchShader.link();
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
