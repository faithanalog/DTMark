part of dtmark;

class Material {

  static const int COLOR_BIT      = 0x1;
  static const int BLEND_BIT      = 0x2;
  static const int DEPTH_TEST_BIT = 0x4;
  static const int TEXTURE_BIT    = 0x8;

  final int flags;

  Material([this.flags = 0]);

  /**
   * Color to be applied when rendering
   */
  Vector4 color = new Vector4(1.0, 1.0, 1.0, 1.0);

  /**
   * Is this thing even visible? If not, don't render!
   */
  bool visible = true;

  /**
   * Texture to use when rendering material
   */
  Texture texture = null;

}
