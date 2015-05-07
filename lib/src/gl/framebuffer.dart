part of dtmark;

/**
 * Wrapper class for WebGL framebuffers
 */
class Framebuffer {

  WebGL.RenderingContext _gl;
  WebGL.Framebuffer _glFbo;

  WebGL.Renderbuffer _depthBuffer;
  Texture _texture;
  bool _depth;

  /**
   * Creates a new framebuffer with the dimensions specified by [width] and
   * [height]. [depth] defines whether a depth buffer should be created.
   */
  factory Framebuffer(WebGL.RenderingContext gl, int width, int height, {bool depth: false}) {
    var texture = new Texture.empty(gl, width, height);
    return new Framebuffer.usingTexture(gl, texture, depth: depth);
  }

  /**
   * Creates a new framebuffer backed by [texture] with the same dimensions
   * as [texture]. [depth] defines whether a depth buffer should be created.
   */
  Framebuffer.usingTexture(WebGL.RenderingContext gl, Texture texture, {bool depth: false}) {
    _gl = gl;
    _texture = texture;
    _depth = depth;
    _glFbo = gl.createFramebuffer();

    gl.bindFramebuffer(WebGL.FRAMEBUFFER, _glFbo);
    gl.framebufferTexture2D(WebGL.FRAMEBUFFER, WebGL.COLOR_ATTACHMENT0, WebGL.TEXTURE_2D, _texture.glTex, 0);

    if (depth) {
      _depthBuffer = gl.createRenderbuffer();
      gl.bindRenderbuffer(WebGL.RENDERBUFFER, _depthBuffer);
      gl.renderbufferStorage(WebGL.RENDERBUFFER, WebGL.DEPTH_COMPONENT16, width, height);
      gl.bindRenderbuffer(WebGL.RENDERBUFFER, null);
      gl.framebufferRenderbuffer(WebGL.FRAMEBUFFER, WebGL.DEPTH_ATTACHMENT, WebGL.RENDERBUFFER, _depthBuffer);
    }
    gl.bindFramebuffer(WebGL.FRAMEBUFFER, null);
  }

  /**
   * Use this framebuffer as the rendering destination. If [setViewport]
   * is true, the WebGL viewport will be set to the dimensions of this
   * framebuffer.
   */
  void bind({bool setViewport: true}) {
    gl.bindFramebuffer(WebGL.FRAMEBUFFER, _glFbo);
    if (setViewport)
      gl.viewport(0, 0, width, height);
  }

  /**
   * Restores the primary framebuffer as rendering destination. Remember
   * to manually set the WebGL viewport back to the canvas size
   * after calling this if the viewport was changed previously.
   */
  void unbind() {
    gl.bindFramebuffer(WebGL.FRAMEBUFFER, null);
  }

  /**
   * Width in pixels of this framebuffer
   */
  int get width => _texture.width;

  /**
   * Height in pixels of this framebuffer
   */
  int get height => _texture.height;

  /**
   * WebGL rendering context assocaited with this framebuffer
   */
  WebGL.RenderingContext get gl => _gl;

  /**
   * The WebGL framebuffer object used by this framebuffer
   */
  WebGL.Framebuffer get glFbo => _glFbo;

  /**
   * Whether or not this framebuffer has a depth buffer
   */
  bool get depth => _depth;

  /**
   * WebGL Renderbuffer used as the depth buffer of this framebuffer, or
   * null if it has no depth buffer
   */
  WebGL.Renderbuffer get depthBuffer => _depthBuffer;

  /**
   * Backing texture of this framebuffer. Destination of color data rendered
   * to this framebuffer.
   */
  Texture get texture => _texture;

}
