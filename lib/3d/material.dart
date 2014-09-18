part of dtmark;

class Material {

  /**
   * Color to be applied when rendering
   */
  Vector4 color = new Vector4(1.0, 1.0, 1.0, 1.0);

  /**
   * Is this material at all see through
   */
  bool transparent = false;

  /**
   * Should blending be enabled when rendering?
   */
  bool blend = false;

  /**
   * SRC factor when blending
   */
  int blendSrc = WebGL.SRC_ALPHA;

  /**
   * DST factor when blending
   */
  int blendDst = WebGL.ONE_MINUS_SRC_ALPHA;

  /**
   * Should the depth test be enabled?
   */
  bool depthTest = true;

  /**
   * Is this thing even visible? If not, don't render!
   */
  bool visible = true;

}
