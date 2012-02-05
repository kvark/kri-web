#library('shade');
#import('dart:dom');


class Base  {
  bool _ready = false;
  String _infoLog = null;
  
  bool isReady() => _ready;
  String getLog() => _infoLog;
}


class Unit extends Base {
  final WebGLShader handle;

  Unit(WebGLRenderingContext gl, int type, String text): handle = gl.createShader(type) {
    gl.shaderSource( handle, text );
    gl.compileShader( handle );
    _infoLog = gl.getShaderInfoLog( handle );
    _ready = gl.getShaderParameter( handle, WebGLRenderingContext.COMPILE_STATUS );
  }
  
  Unit.vertex(WebGLRenderingContext gl, String text)
    : this( gl, WebGLRenderingContext.VERTEX_SHADER, text );
  Unit.fragment(WebGLRenderingContext gl, String text)
  : this( gl, WebGLRenderingContext.FRAGMENT_SHADER, text );
  
  Unit.invalid(): handle=null;
}


class Program extends Base {
  final WebGLProgram handle;
  
  Program(WebGLRenderingContext gl, List<Unit> units): handle = gl.createProgram() {
    for (final unit in units) {
      assert( unit.isReady() );
      gl.attachShader( handle, unit.handle );
    }
    gl.linkProgram( handle );
    _infoLog = gl.getProgramInfoLog( handle );
    _ready = gl.getProgramParameter( handle, WebGLRenderingContext.LINK_STATUS );
  }

  Program.invalid(): handle=null;
  
  void bind(WebGLRenderingContext gl) {
    gl.useProgram( handle );
  }
}


class Uniform {
  final WebGLUniformLocation location;
  final WebGLActiveInfo info;
  Uniform( this.location, this.info );
}

class Effect extends Program  {
  final Map<int,WebGLActiveInfo> attributes;
  final List<Uniform> uniforms;
  
  Effect(WebGLRenderingContext gl, List<Unit> units)
  : super(gl,units), attributes = new Map<int,WebGLActiveInfo>(), uniforms = new List<Uniform>()  {
    final int nAt = gl.getProgramParameter( handle, WebGLRenderingContext.ACTIVE_ATTRIBUTES );
    for (int i=0; i<nAt; ++i) {
      final WebGLActiveInfo info = gl.getActiveAttrib( handle, i );
      final int loc = gl.getAttribLocation( handle, info.name );
      attributes[loc] = info;
    }
    final int nUn = gl.getProgramParameter( handle, WebGLRenderingContext.ACTIVE_UNIFORMS );
    for (int i=0; i<nUn; ++i) {
      final WebGLActiveInfo info = gl.getActiveUniform( handle, i );
      final WebGLUniformLocation loc = gl.getUniformLocation( handle, info.name );
      uniforms.add( new Uniform(loc,info) );
    }
  }
}


class Instance  {
  final Effect effect;
  final Map<String,Object> parameters;
  
  Instance(this.effect): parameters = new Map<String,Object>();
  
  bool activate(WebGLRenderingContext gl) {
    if (!effect.isReady())
      return false;
    effect.bind( gl );
    // set parameters
    for (final Uniform uni in effect.uniforms)  {
      var value = parameters[uni.info.name];
      if (!value)
        return false;
      switch (uni.info.type)  {
      case WebGLRenderingContext.FLOAT_VEC4:
        gl.uniform4fv( uni.location, value );
      }
    }
    return true;
  }
}
