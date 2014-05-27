part of dtmark;

class Shader {
  
  WebGL.Program program;
  WebGL.Shader vertShader;
  WebGL.Shader fragShader;
  WebGL.RenderingContext gl;
  
  Map<String, WebGL.UniformLocation> uniformMap = new Map();
  
  Shader(String vertSrc, String fragSrc, this.gl) {
    vertShader = gl.createShader(WebGL.VERTEX_SHADER);
    gl.shaderSource(vertShader, vertSrc);
    gl.compileShader(vertShader);
    
    String log = gl.getShaderInfoLog(vertShader);
    if (log.isNotEmpty) {
      print("VERTEX ERR:\n" + log);
    }
    
    fragShader = gl.createShader(WebGL.FRAGMENT_SHADER);
    gl.shaderSource(fragShader, fragSrc);
    gl.compileShader(fragShader);
    
    log = gl.getShaderInfoLog(fragShader);
    if (log.isNotEmpty) {
      print("FRAGMENT ERR:\n" + log);
    }
    
    program = gl.createProgram();
    gl.attachShader(program, vertShader);
    gl.attachShader(program, fragShader);
    gl.linkProgram(program);
  }
  
  WebGL.UniformLocation getUniformLoc(String name) {
    if (uniformMap.containsKey(name)) {
      return uniformMap[name];
    } else {
      WebGL.UniformLocation loc = gl.getUniformLocation(program, name);
      uniformMap[name] = loc;
      return loc;
    }
  }
  
  void bindAttribLocation(int index, String name) => gl.bindAttribLocation(program, index, name);
  
  void use() => gl.useProgram(program);
  
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