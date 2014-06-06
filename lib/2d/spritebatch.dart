part of dtmark;

//TODO Add Z index (make it a vert attrib) so that things don't have to be painter's algorithim. good idea? maybe...
class SpriteBatch {
  
  //Max 65536 verts before flush
  static int BATCH_MAX_VERTS = 65536;
  
  //X,Y,U,V,R,G,B,A
  Float32List verts = new Float32List(8 * BATCH_MAX_VERTS);
  WebGL.RenderingContext gl;
  WebGL.Buffer buffer;
  WebGL.Buffer indices;
  Shader _shader;
  
  Texture whiteTex;
  Texture _lastTex = null;
  Vector4 color = new Vector4(1.0, 1.0, 1.0, 1.0);
  int _vOff = 0;
  
  
  //Max vertices we've actually used, we'll use this for buffer streaming so we dont use tons of vram
  int _maxVertsUsed = 0;
  
  Matrix4 _projection;
  Matrix4 _modelView;
  Matrix4 _transform = new Matrix4.identity();
  bool _rendering = false;
  
  bool _texChanged = false;
  
  SpriteBatch(this.gl, {int width: 1, int height: 1}) {
    _shader = getBatchShader(gl);
    buffer = gl.createBuffer();
    
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
    indices = gl.createBuffer();
    gl.bindBuffer(WebGL.ELEMENT_ARRAY_BUFFER, indices);
    gl.bufferDataTyped(WebGL.ELEMENT_ARRAY_BUFFER, indData, WebGL.STATIC_DRAW);
    gl.bindBuffer(WebGL.ELEMENT_ARRAY_BUFFER, null);
    
    
    whiteTex = new Texture(null, gl);
    gl.texImage2DTyped(WebGL.TEXTURE_2D, 0, WebGL.RGBA, 1, 1, 0, WebGL.RGBA, WebGL.UNSIGNED_BYTE, new Uint8List.fromList([255, 255, 255, 255]));
    
    _projection = makeOrthographicMatrix(0, width, 0, height, -1, 1);
    _modelView = new Matrix4.identity();
    _lastTex = whiteTex;
  }
  
  void _addVert(double x, double y, double u, double v) {
    if (_vOff >= verts.length) {
      _flush();
    }
    verts[_vOff + 0] = x;
    verts[_vOff + 1] = y;
    verts[_vOff + 2] = u;
    verts[_vOff + 3] = v;
    verts.setAll(_vOff + 4, color.storage);
    _vOff += 8;
  }
  
  //Vertex 0 is top left, Vertex 1 is bottom right
  void _addQuad(double x0, double y0, double u0, double v0, double x1, double y1, double u1, double v1) {
    
    //NEW: Top left, bottom left, bottom right, top right
    _addVert(x0, y0, u0, v0);
    _addVert(x0, y1, u0, v1);
    _addVert(x1, y1, u1, v1);
    _addVert(x1, y0, u1, v0);
  }
  
  void _switchTexture(Texture tex) {
    if (_lastTex != tex) {
      _flush();
      _texChanged = true;
      _lastTex = tex;
    }
  }
  
  void fillRect(double x, double y, double width, double height) {
    drawTexture(whiteTex, x, y, width, height);
  }
  
  void drawTexture(Texture tex, double x, double y, [double width, double height]) {
    _switchTexture(tex);
    if (width == null) {
      width = tex.width.toDouble();
    }
    if (height == null) {
      height = tex.height.toDouble();
    }
    _addQuad(x, y + height, 0.0, 0.0, x + width, y, tex.maxU, tex.maxV);
  }
  
  void drawTexScaled(Texture tex, double x, double y, double scale) {
    drawTexture(tex, x, y, tex.width * scale, tex.height * scale);
  }
  
  void drawTexRegion(Texture tex, double x, double y, double width, double height, int texX, int texY, int texWidth, int texHeight) {
    double w = 1 / tex.width;
    double h = 1 / tex.height;
    double u0 = texX * w;
    double v0 = texY * h;
    double u1 = u0 + texWidth * w;
    double v1 = v0 + texHeight * h;
    drawTexRegionUV(tex, x, y, width, height, u0, v0, u1, v1);
  }
  
  void drawTexRegionUV(Texture tex, double x, double y, double width, double height, double u0, double v0, double u1, double v1) {
    _switchTexture(tex);
    _addQuad(x, y + height, u0, v0, x + width, y, u1, v1);
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
  
  Shader get shader => _shader;
  
  Matrix4 get projection => _projection;
  Matrix4 get modelView => _modelView;
  
  void begin() {
    _rendering = true;
    _texChanged = true;
    _shader.use();
    _transform.setFrom(_projection);
    _transform.multiply(_modelView);
    _shader.setUniformMatrix4fv("u_transform", false, _transform);
    
    gl.enableVertexAttribArray(0);
    gl.enableVertexAttribArray(1);
    gl.enableVertexAttribArray(2);
    
    gl.bindBuffer(WebGL.ARRAY_BUFFER, buffer);
    gl.bindBuffer(WebGL.ELEMENT_ARRAY_BUFFER, indices);
    gl.vertexAttribPointer(0, 2, WebGL.FLOAT, false, 32, 0);
    gl.vertexAttribPointer(1, 2, WebGL.FLOAT, false, 32, 8);
    gl.vertexAttribPointer(2, 4, WebGL.FLOAT, false, 32, 16);
  }
  
  void end() {
    _flush();
    gl.bindBuffer(WebGL.ELEMENT_ARRAY_BUFFER, null);
    gl.disableVertexAttribArray(0);
    gl.disableVertexAttribArray(1);
    gl.disableVertexAttribArray(2);
    _rendering = false;
  }
  
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