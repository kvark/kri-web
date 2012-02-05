class Unit {
  final WebGLShader handle;
  bool _ready = false;
  String _infoLog = null;

  Unit(WebGLRenderingContext gl, int type, String text): handle = gl.createShader(type) {
    gl.shaderSource( handle, text );
    gl.compileShader( handle );
    _infoLog = gl.getShaderInfoLog( handle );
    num status = gl.getShaderParameter( handle, WebGLRenderingContext.COMPILE_STATUS );
    _ready = status>0;
  }

  Unit.invalid(): handle=null;
  bool isReady() => _ready;
  String getLog() => _infoLog;
}


class Program  {
  final WebGLProgram handle;
  bool _ready = false;
  String _infoLog = null;
  
  Program(WebGLRenderingContext gl, List<Unit> units): handle = gl.createProgram() {
    for (final unit in units) {
      assert( unit.isReady() );
      gl.attachShader( handle, unit.handle );
    }
    gl.linkProgram( handle );
    _infoLog = gl.getProgramInfoLog( handle );
    num status = gl.getProgramParameter( handle, WebGLRenderingContext.LINK_STATUS );
    _ready = status>0;
  }

  Program.invalid(): handle=null;
  bool isReady() => _ready;
  String getLog() => _infoLog;
}
