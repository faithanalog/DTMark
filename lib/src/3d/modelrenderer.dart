part of dtmark;

abstract class ModelRenderer {

  WebGL.RenderingContext _gl;

  ModelRenderer(WebGL.RenderingContext gl) {
    _gl = gl;
  }

  WebGL.RenderingContext get gl => _gl;


  /**
   * Renders a list of models with the provided camera and shader.
   * ModelRenderer implementations should use a default shader implementation
   * to use when the provided shader is null. [renderModels] will not
   * modify the contents of the list, but may sort it in place.
   */
  void renderModels(List<Model> models, Camera cam, [Shader shader = null]);

}

/**
 * Basic model renderer that supports colors, blending, textures, and depth testing
 */
class BasicModelRenderer extends ModelRenderer {

  static Shader _defaultShader = null;

  BasicModelRenderer(WebGL.RenderingContext gl): super(gl) {
    if (_defaultShader == null) {

    }
  }

  void renderModels(List<Model> models, Camera cam, [Shader shader = null]) {
    models.sort((a, b) => a.material.flags.compareTo(b.material.flags));

  }

}
