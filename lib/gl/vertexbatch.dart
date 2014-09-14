part of dtmark;

/**
 * Base vertex batch class used by anything that needs to queue up vertices
 * and push them to the GPU. Intended for internal use only
 */
class VertexBatch {

  /**
   * The max number of verts to store in ram before rendering.
   * Defaults to 65536 / 2, can be changed if needed. Changes affect
   * all VertexBatches created after the change.
   */
  static int BATCH_MAX_VERTS = 65536 ~/ 2;

  /**
   * The array used to store verts while batching.
   */
  Float32List verts = null;

  /**
   * WebGL context associated with this VertexBatch
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
   * Color used when rendering anything with the VertexBatch. Changing
   * this will affect anything drawn after it is changed.
   */
  Vector4 color = new Vector4(1.0, 1.0, 1.0, 1.0);
  int _vOff = 0;
  int _vOffMax = 0;

  Matrix4 _projection = new Matrix4.identity();
  Matrix4 _modelView = new Matrix4.identity();
  Matrix4 _transform = new Matrix4.identity();
  bool _rendering = false;
  bool _texChanged = false;
  bool _quadInput = false;

  List<VertexAttrib> _attribs = null;
  int _maxVertSize = 0;

  /**
   * Constructs a new VertexBatch which will used the provided attribs
   * if [quadInput] is specified, will draw vertices as if they specify quads,
   * otherwise it is assumed they are triangles
   */
  VertexBatch(this.gl, List<VertexAttrib> attribs, {bool quadInput: false}) {
    _shader = null;
    _attribs = attribs;
    _quadInput = quadInput;
    for (var attrib in attribs) {
      _maxVertSize += attrib.size;
    }
    _vOffMax = _maxVertSize * BATCH_MAX_VERTS;
    verts = new Float32List(_vOffMax);

    _buffer = gl.createBuffer();

    if (_quadInput) {
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
    }


    _whiteTex = new Texture(null, gl);
    gl.texImage2DTyped(WebGL.TEXTURE_2D, 0, WebGL.RGBA, 1, 1, 0, WebGL.RGBA, WebGL.UNSIGNED_BYTE, new Uint8List.fromList([255, 255, 255, 255]));

    _lastTex = _whiteTex;
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
    _shader = shader;
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

  /**
   * The amount of floats in each vertex
   */
  int get vertSize {
    int size = 0;
    for (var attrib in _attribs) {
      if (attrib.active) {
        size += attrib.size;
      }
    }
    return size;
  }

  /**
   * Sets up the state required to render the vertex batch, including
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

    gl.bindBuffer(WebGL.ARRAY_BUFFER, _buffer);
    if (_quadInput) {
      gl.bindBuffer(WebGL.ELEMENT_ARRAY_BUFFER, _indices);
    }

    int stride = vertSize * 4;
    int offs = 0;
    for (var attrib in _attribs) {
      if (attrib.active) {
        gl.enableVertexAttribArray(attrib.index);
        gl.vertexAttribPointer(attrib.index, attrib.size, WebGL.FLOAT, false, stride, offs);
        offs += attrib.size * 4;
      }
    }
  }

  /**
   * Flushes any remaining vertices from the VertexBatch, unbinds the
   * buffer bound to `ELEMENT_ARRAY_BUFFER`, and disables vertix attrib
   * arrays 0, 1, and 2.
   */
  void end() {
    _flush();
    if (_quadInput) {
      gl.bindBuffer(WebGL.ELEMENT_ARRAY_BUFFER, null);
    }
    for (var attrib in _attribs) {
      if (attrib.active) {
        gl.disableVertexAttribArray(attrib.index);
      }
    }
    _rendering = false;
  }

  /**
   * Renders all vertices buffered in the VertexBatch
   */
  void flush() {
      _flush();
  }

  void _flushIfNeeded() {
    if (_vOff >= _vOffMax) {
      _flush();
    }
  }

  void _flush() {
    if (!_rendering) {
      return;
    }
    if (_vOff > 0) {
      if (_texChanged) {
        if (_lastTex != null) {
          _lastTex.bind();
        }
        _texChanged = false;
      }
      gl.bufferDataTyped(WebGL.ARRAY_BUFFER, new Float32List.view(verts.buffer, 0, _vOff), WebGL.STREAM_DRAW);
      if (_quadInput) {
        gl.drawElements(WebGL.TRIANGLES, (_vOff ~/ vertSize ~/ 4 * 6), WebGL.UNSIGNED_SHORT, 0);
      } else {
        gl.drawArrays(WebGL.TRIANGLES, 0, (_vOff ~/ vertSize));
      }
    }
    _vOff = 0;
  }
}

class VertexAttrib {

  /**
   * VertexAttribArray index
   */
  final int index;

  /**
   * Number of floats in the attribute
   */
  final int size;

  /**
   * Whether or not this VertexAttrib should be active when rendering
   */
  bool active = true;

  VertexAttrib(this.index, this.size);

}
