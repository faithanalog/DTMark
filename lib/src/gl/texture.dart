part of dtmark;

/**
 * WebGL texture wrapper. Very useful, used extensively in the 2d library code
 */
class Texture {

  WebGL.RenderingContext _gl;
  WebGL.Texture _glTex;

  int _minFilter = WebGL.NEAREST;
  int _magFilter = WebGL.NEAREST;
  int _wrapS = WebGL.CLAMP_TO_EDGE;
  int _wrapT = WebGL.CLAMP_TO_EDGE;
  bool _mipmap = false;

  int _width = 1, _height = 1;

  bool _needsUpdate = false;
  bool _needsMipmap = false;

  Future<Texture> _onLoad;

  /**
   * Loads a texture from the provided data
   *
   * minFilter and magFilter default to `WebGL.NEAREST`. wrapS and wrapT
   * default to `WebGL.CLAMP_TO_EDGE`
   */
  Texture(CanvasImageSource data, WebGL.RenderingContext gl, {bool mipmap: false}) {
    _mipmap = mipmap;
    _gl = gl;
    _glTex = gl.createTexture();
    gl.bindTexture(WebGL.TEXTURE_2D, glTex);
    uploadData(data);
    _setProperties();
    _onLoad = new Future.value(this);
  }

  /**
   * Creates an empty texture with the given dimensions
   *
   * minFilter and magFilter default to `WebGL.NEAREST`. wrapS and wrapT
   * default to `WebGL.CLAMP_TO_EDGE`
   */
   Texture.empty(WebGL.RenderingContext gl, int width, int height, {bool mipmap: false}) {
     _mipmap = mipmap;
     _gl = gl;
     _glTex = gl.createTexture();
     gl.bindTexture(WebGL.TEXTURE_2D, glTex);
     setSize(width, height);
     _setProperties();
     _onLoad = new Future.value(this);
   }


  /**
   * Loads a texture from the image at [url].
   *
   * minFilter and magFilter default to `WebGL.NEAREST`. wrapS and wrapT
   * default to `WebGL.CLAMP_TO_EDGE`
   */
  factory Texture.load(String url, WebGL.RenderingContext gl, {bool mipmap: false}) {
    Texture tex = new Texture(null, gl, mipmap: mipmap);

    var img = new ImageElement();
    tex._onLoad = img.onLoad.first.then((_) {
      tex.bind();
      tex.uploadData(img);
      return tex;
    });
    img.src = url;
    return tex;
  }

  /**
   * Provides a convenient way to generate a texutre on the fly in code. Takes a function
   * [generate] which will be called with a 2d context used to draw the
   * source image data of the texture.
   *
   * minFilter and magFilter default to `WebGL.NEAREST`. wrapS and wrapT
   * default to `WebGL.CLAMP_TO_EDGE`
   */
  factory Texture.generate(WebGL.RenderingContext gl, int width, int height,
    void generate(CanvasRenderingContext2D ctx, int width, int height), {bool mipmap: false}) {

    var elem = new CanvasElement(width: width, height: height);
    var ctx = elem.getContext("2d") as CanvasRenderingContext2D;
    generate(ctx, width, height);
    return new Texture(elem, gl, mipmap: mipmap);
  }

  /**
   * Uploads image data to the texture
   */
  void uploadData(CanvasImageSource data) {
    if (data == null) {
      _width = 1;
      _height = 1;
      gl.texImage2DTyped(WebGL.TEXTURE_2D, 0, WebGL.RGBA, 1, 1, 0, WebGL.RGBA,
        WebGL.UNSIGNED_BYTE, new Uint8List.fromList([0, 0, 0, 255]));
    } else {
      //Evil code dupe but necessary because of dart's type system
      if (data is ImageElement) {
        setSize(data.width, data.height);
        gl.texSubImage2DImage(WebGL.TEXTURE_2D, 0, 0, 0, WebGL.RGBA, WebGL.UNSIGNED_BYTE, data);
      } else if (data is CanvasElement) {
        setSize(data.width, data.height);
        gl.texSubImage2DCanvas(WebGL.TEXTURE_2D, 0, 0, 0, WebGL.RGBA, WebGL.UNSIGNED_BYTE, data);
      } else if (data is VideoElement) {
        setSize(data.width, data.height);
        gl.texSubImage2DVideo(WebGL.TEXTURE_2D, 0, 0, 0, WebGL.RGBA, WebGL.UNSIGNED_BYTE, data);
      }
      if (_mipmap)
        gl.generateMipmap(WebGL.TEXTURE_2D);
    }
  }

  /**
   * Resizes the texture to be [width] x [height].
   * If the texture width and height are equal to
   * [width] and [height], nothing is done
   */
  void setSize(int width, int height) {
    if (this._width != width || this._height != height) {
      this._width = width;
      this._height = height;
      gl.texImage2DTyped(WebGL.TEXTURE_2D, 0, WebGL.RGBA, width, height, 0,
        WebGL.RGBA, WebGL.UNSIGNED_BYTE, null);
    }
  }

  void _setProperties() {
    gl.texParameteri(WebGL.TEXTURE_2D, WebGL.TEXTURE_MIN_FILTER, _minFilter);
    gl.texParameteri(WebGL.TEXTURE_2D, WebGL.TEXTURE_MAG_FILTER, _magFilter);
    gl.texParameteri(WebGL.TEXTURE_2D, WebGL.TEXTURE_WRAP_S, _wrapS);
    gl.texParameteri(WebGL.TEXTURE_2D, WebGL.TEXTURE_WRAP_T, _wrapT);
  }

  /**
   * Binds this texture, and sets texture paramaters if any
   * have changed since the last time this was called.
   */
  void bind() {
    gl.bindTexture(WebGL.TEXTURE_2D, glTex);
    if (_needsUpdate) {
      _setProperties();
      _needsUpdate = false;
    }
    if (_needsMipmap) {
      gl.generateMipmap(WebGL.TEXTURE_2D);
      _needsMipmap = false;
    }
  }

  Future<Texture> get onLoad => _onLoad;

  set minFilter(int filter) {
    if (_minFilter != filter) {
      _minFilter = filter;
      _needsUpdate = true;
    }
  }

  set magFilter(int filter) {
    if (_magFilter != filter) {
      _magFilter = filter;
      _needsUpdate = true;
    }
  }

  set wrapS(int wrap) {
    if (_wrapS != wrap) {
      _wrapS = wrap;
      _needsUpdate = true;
    }
  }

  set wrapT(int wrap) {
    if (_wrapT != wrap) {
      _wrapT = wrap;
      _needsUpdate = true;
    }
  }

  set mipmap(bool mip) {
    if (mip && !_mipmap) {
      _needsMipmap = true;
    }
    _mipmap = mip;
  }

  /**
   * Filter used when displaying the texture at smaller sizes than its normal size.
   * Setting to use mipmaps requires a texture with dimensions that are
   * powers of 2. Setting this will not affect the texture until the next time [bind] is called.
   *
   * This may be set to:

   * * `WebGL.NEAREST`
   * * `WebGL.NEAREST_MIPMAP_NEAREST`
   * * `WebGL.NEAREST_MIPMAP_LINEAR`
   * * `WebGL.LINEAR`
   * * `WebGL.LINEAR_MIPMAP_LINEAR`
   * * `WebGL.LINEAR_MIPMAP_LINEAR`
   */
  int get minFilter => _minFilter;

  /**
   * Filter used when displaying the texture at larger sizes than its normal size.
   * Setting this will not affect the texture until the next time [bind] is called.
   *
   * This may be set to:

   * * `WebGL.NEAREST`
   * * `WebGL.LINEAR`
   */
  int get magFilter => _magFilter;


  /**
   * Texture wrapping rule on X axis
   *
   * This may be set to:

   * * `WebGL.REPEAT`
   * * `WebGL.CLAMP_TO_EDGE`
   */
  int get wrapS => _wrapS;

  /**
   * Texture wrapping rule on Y axis
   *
   * This may be set to:

   * * `WebGL.REPEAT`
   * * `WebGL.CLAMP_TO_EDGE`
   */
   int get wrapT => _wrapT;

   /**
    * Whether or not this texture should generate mipmaps when new data
    * is uploaded. If mipmap was previously false and is set to true,
    * the texture will have mipmaps generated next time [bind] is called.
    */
   bool get mipmap => _mipmap;

   /**
    * Width of texture in pixels
    */
   int get width => _width;

   /**
    * Height of texture in pixels
    */
   int get height => _height;

   /**
    * Rendering context associated with this texture
    */
   WebGL.RenderingContext get gl => _gl;

   /**
    * Backing WebGL Texture object of this texture
    */
   WebGL.Texture get glTex => _glTex;
}

/**
 * Defines a region of a texture to be used with a SpriteBatch for drawing
 */
class TextureRegion {

  /**
   * Source texture of the region
   */
  final Texture texture;
  final int x, y, width, height;

  /**
   * Defines a texture region of a given texture. [x] and [y]
   * are the coordinates of the top left point of the region,
   * and width
   */
  TextureRegion(this.texture, this.x, this.y, this.width, this.height);

  /**
   * x + width
   */
  int get maxX => x + width;

  /**
   * y + height
   */
  int get maxY => y + height;

  /**
   * U coordinate of the top left corner
   */
  double get minU => x / texture.width;

  /**
   * V coordiante of the top left corner
   */
  double get minV => y / texture.height;

  /**
   * U coordinate of the bottom right corner
   */
  double get maxU => maxX / texture.width;

  /**
   * V coordinate of the bottom right corner
   */
  double get maxV => maxY / texture.height;

  /**
   * Width of the TextureRegion in UV coordinates
   */
  double get uvWidth => width / texture.width;

  /**
   * Height of the TextureRegion in UV coordinates
   */
  double get uvHeight => height / texture.height;

}
