part of dtmark;
class Texture {

  static bool allowNonPowerOf2 = true;

  WebGL.RenderingContext gl;
  WebGL.Texture glTex;

  int minFilter, magFilter, wrapS, wrapT;
  bool mipmap;

  double maxU = 1.0, maxV = 1.0;
  int width = 1, height = 1;

  bool needsUpdate = false;

  Future<Texture> _onLoad;

  Texture(CanvasImageSource data, this.gl, {int minFilter: WebGL.NEAREST, int magFilter: WebGL.NEAREST,
    int wrapS: WebGL.CLAMP_TO_EDGE, int wrapT: WebGL.CLAMP_TO_EDGE, bool mipmap: false}) {
    this.minFilter = minFilter;
    this.magFilter = magFilter;
    this.wrapS = wrapS;
    this.wrapT = wrapT;
    this.mipmap = mipmap;
    glTex = gl.createTexture();
    gl.bindTexture(WebGL.TEXTURE_2D, glTex);
    uploadData(data);
    _setProperties();
    _onLoad = new Future.value(this);
  }

  factory Texture.load(String url, WebGL.RenderingContext gl, {int minFilter: WebGL.NEAREST, int magFilter: WebGL.NEAREST,
    int wrapS: WebGL.CLAMP_TO_EDGE, int wrapT: WebGL.CLAMP_TO_EDGE, bool mipmap: false}) {
    Texture tex = new Texture(null, gl, minFilter: minFilter, magFilter: magFilter, wrapS: wrapS, wrapT: wrapT, mipmap: mipmap);
    Completer<Texture> loadCompleter = new Completer();
    tex._onLoad = loadCompleter.future;

    var img = new ImageElement();
    img.onLoad.first.then((Event) {
      tex.bind();
      tex.uploadData(img);
      loadCompleter.complete(tex);
    });
    img.src = url;
    return tex;
  }

  factory Texture.generate(WebGL.RenderingContext gl, int width, int height, void generate(CanvasRenderingContext2D ctx, int width, int height),
    {int minFilter: WebGL.NEAREST, int magFilter: WebGL.NEAREST, int wrapS: WebGL.CLAMP_TO_EDGE,
    int wrapT: WebGL.CLAMP_TO_EDGE, bool mipmap: false}) {

    var elem = new CanvasElement(width: width, height: height);
    var ctx = elem.getContext("2d") as CanvasRenderingContext2D;
    generate(ctx, width, height);
    return new Texture(elem, gl, minFilter: minFilter, magFilter: magFilter, wrapS: wrapS, wrapT: wrapT, mipmap: mipmap);
  }

  void uploadData(CanvasImageSource data) {
    if (data == null) {
      width = 1;
      height = 1;
      gl.texImage2DTyped(WebGL.TEXTURE_2D, 0, WebGL.RGBA, 1, 1, 0, WebGL.RGBA, WebGL.UNSIGNED_BYTE, new Uint8List.fromList([0, 0, 0, 255]));
    } else {
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
      if (mipmap) {
        gl.generateMipmap(WebGL.TEXTURE_2D);
      }
    }
  }

  void setSize(int width, int height) {
    this.width = width;
    this.height = height;
    if (allowNonPowerOf2) {
      gl.texImage2DTyped(WebGL.TEXTURE_2D, 0, WebGL.RGBA, width, height, 0, WebGL.RGBA, WebGL.UNSIGNED_BYTE, null);
      maxU = 1.0;
      maxV = 1.0;
    } else {
      int po2w = nextPowerOf2(width);
      int po2h = nextPowerOf2(height);
      gl.texImage2DTyped(WebGL.TEXTURE_2D, 0, WebGL.RGBA, po2w, po2h, 0, WebGL.RGBA, WebGL.UNSIGNED_BYTE, null);
      maxU = width / po2w;
      maxV = height / po2h;
    }
//    gl.texImage2D(WebGL.TEXTURE_2D, 0, WebGL.RGBA, po2w, po2h, 0);
  }

  void _setProperties() {
    gl.texParameteri(WebGL.TEXTURE_2D, WebGL.TEXTURE_MIN_FILTER, minFilter);
    gl.texParameteri(WebGL.TEXTURE_2D, WebGL.TEXTURE_MAG_FILTER, magFilter);
    gl.texParameteri(WebGL.TEXTURE_2D, WebGL.TEXTURE_WRAP_S, wrapS);
    gl.texParameteri(WebGL.TEXTURE_2D, WebGL.TEXTURE_WRAP_T, wrapT);
  }

  void bind() {
    gl.bindTexture(WebGL.TEXTURE_2D, glTex);
    if (needsUpdate) {
      _setProperties();
      needsUpdate = false;
    }
  }

  Future<Texture> get onLoad => _onLoad;

}

class TextureRegion {

  final Texture texture;
  final int x, y, width, height;

  /**
   * Defines a texture region of a given texture. [x] and [y]
   * are the coordinates of the top left point of the region,
   * and width
   */
  TextureRegion(this.texture, this.x, this.y, this.width, this.height);

  int get maxX => x + width;
  int get maxY => y + height;

}
