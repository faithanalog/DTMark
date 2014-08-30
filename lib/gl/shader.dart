part of dtmark;

/**
 * Basic ShaderProgram wrapper that makes WebGL shaders a bit easier to deal with.
 */
class Shader {

  /**
   * The WebGL shader program object
   */
  WebGL.Program program;

  /**
   * The vertex shader of the program
   */
  WebGL.Shader vertShader;

  /**
   * The fragment shader of the program
   */
  WebGL.Shader fragShader;

  /**
   * WebGL context associated with this shader
   */
  WebGL.RenderingContext gl;

  /**
   * A map of uniform identifiers to WebGL UniformLocations
   */
  final Map<String, WebGL.UniformLocation> uniformMap = new Map();

  /**
   * Creates a new shader program from the shader sources provided in [vertSrc]
   * and [fragSrc]. If any error results from compiling these shaders, it will
   * be printed out to the logs. If [shaderName] is provided, it will
   * be printed at the start of the error logs for easier identification
   * of which shader had an error.
   */
  Shader(String vertSrc, String fragSrc, this.gl, [shaderName = ""]) {
    vertShader = gl.createShader(WebGL.VERTEX_SHADER);
    gl.shaderSource(vertShader, vertSrc);
    gl.compileShader(vertShader);

    String log = gl.getShaderInfoLog(vertShader);
    if (log.isNotEmpty) {
      print("VERTEX ERR in shader $shaderName:\n" + log);
    }

    fragShader = gl.createShader(WebGL.FRAGMENT_SHADER);
    gl.shaderSource(fragShader, fragSrc);
    gl.compileShader(fragShader);

    log = gl.getShaderInfoLog(fragShader);
    if (log.isNotEmpty) {
      print("FRAGMENT ERR in shader $shaderName:\n" + log);
    }

    program = gl.createProgram();
    gl.attachShader(program, vertShader);
    gl.attachShader(program, fragShader);
    gl.linkProgram(program);
  }

  /**
   * Gets the UniformLocation of a uniform. This will return uniform location cache
   * if [name] has a value associated with it, otherwise it will query WebGL
   * and cache the result.
   */
  WebGL.UniformLocation getUniformLoc(String name) {
    if (uniformMap.containsKey(name)) {
      return uniformMap[name];
    } else {
      WebGL.UniformLocation loc = gl.getUniformLocation(program, name);
      uniformMap[name] = loc;
      return loc;
    }
  }

  /**
   * Binds the vertex attribute with identifier of [name] to attrib array [index].
   * Make sure to call [link] after calling this or the changes will
   * not go into effect.
   */
  void bindAttribLocation(int index, String name) => gl.bindAttribLocation(program, index, name);

  /**
   * Convenience function for gl.useProgram(this.program);
   *
   * Call before rendering with this shader.
   */
  void use() => gl.useProgram(program);

  /*
   * Re-links this shader program and clears the uniform location map
   */
  void link() {
    gl.linkProgram(program);
    uniformMap.clear();
  }

  void setUniform1f(String name, double a) => gl.uniform1f(getUniformLoc(name), a);
  void setUniform2f(String name, double a, double b) => gl.uniform2f(getUniformLoc(name), a, b);
  void setUniform3f(String name, double a, double b, double c) => gl.uniform3f(getUniformLoc(name), a, b, c);
  void setUniform4f(String name, double a, double b, double c, double d) => gl.uniform4f(getUniformLoc(name), a, b, c, d);

  void setUniform1i(String name, int a) => gl.uniform1i(getUniformLoc(name), a);
  void setUniform2i(String name, int a, int b) => gl.uniform2i(getUniformLoc(name), a, b);
  void setUniform3i(String name, int a, int b, int c) => gl.uniform3i(getUniformLoc(name), a, b, c);
  void setUniform4i(String name, int a, int b, int c, int d) => gl.uniform4i(getUniformLoc(name), a, b, c, d);

  void setUniformMatrix2fv(String name, bool transpose, Matrix2 mat) => gl.uniformMatrix2fv(getUniformLoc(name), transpose, mat.storage);
  void setUniformMatrix3fv(String name, bool transpose, Matrix3 mat) => gl.uniformMatrix3fv(getUniformLoc(name), transpose, mat.storage);
  void setUniformMatrix4fv(String name, bool transpose, Matrix4 mat) => gl.uniformMatrix4fv(getUniformLoc(name), transpose, mat.storage);

}
