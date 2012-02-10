#library('shade');
#import('dart:dom', prefix:'dom');


class Base  {
  bool _ready = false;
  String _infoLog = null;
  
  bool isReady() => _ready;
  String getLog() => _infoLog;
}


class Unit extends Base {
  final dom.WebGLShader handle;

  Unit(dom.WebGLRenderingContext gl, int type, String text): handle = gl.createShader(type) {
    gl.shaderSource( handle, text );
    gl.compileShader( handle );
    _infoLog = gl.getShaderInfoLog( handle );
    _ready = gl.getShaderParameter( handle, dom.WebGLRenderingContext.COMPILE_STATUS );
  }
  
  Unit.vertex(dom.WebGLRenderingContext gl, String text)
    : this( gl, dom.WebGLRenderingContext.VERTEX_SHADER, text );
  Unit.fragment(dom.WebGLRenderingContext gl, String text)
  : this( gl, dom.WebGLRenderingContext.FRAGMENT_SHADER, text );
  
  Unit.invalid(): handle=null;
}


class Program extends Base {
  final dom.WebGLProgram handle;
  
  Program(dom.WebGLRenderingContext gl, List<Unit> units): handle = gl.createProgram() {
    for (final unit in units) {
      assert( unit.isReady() );
      gl.attachShader( handle, unit.handle );
    }
    gl.linkProgram( handle );
    _infoLog = gl.getProgramInfoLog( handle );
    _ready = gl.getProgramParameter( handle, dom.WebGLRenderingContext.LINK_STATUS );
  }

  Program.invalid(): handle=null;
  
  void bind(dom.WebGLRenderingContext gl) {
    gl.useProgram( handle );
  }
}


class Uniform {
  final dom.WebGLUniformLocation location;
  final dom.WebGLActiveInfo info;
  Uniform( this.location, this.info );
}

class Effect extends Program  {
  final Map<int,dom.WebGLActiveInfo> attributes;
  final List<Uniform> uniforms;
  
  Effect(dom.WebGLRenderingContext gl, List<Unit> units)
  : super(gl,units), attributes = new Map<int,dom.WebGLActiveInfo>(), uniforms = new List<Uniform>()  {
    final int nAt = gl.getProgramParameter( handle, dom.WebGLRenderingContext.ACTIVE_ATTRIBUTES );
    for (int i=0; i<nAt; ++i) {
      final dom.WebGLActiveInfo info = gl.getActiveAttrib( handle, i );
      final int loc = gl.getAttribLocation( handle, info.name );
      attributes[loc] = info;
    }
    final int nUn = gl.getProgramParameter( handle, dom.WebGLRenderingContext.ACTIVE_UNIFORMS );
    for (int i=0; i<nUn; ++i) {
      final dom.WebGLActiveInfo info = gl.getActiveUniform( handle, i );
      final dom.WebGLUniformLocation loc = gl.getUniformLocation( handle, info.name );
      uniforms.add( new Uniform(loc,info) );
    }
  }
}


class Instance  {
  final Effect effect;
  final Map<String,Object> parameters;
  
  Instance(this.effect): parameters = new Map<String,Object>();
  Instance.from(Instance other): effect = other.effect,
   parameters = new Map<String,Object>.from(other.parameters);
  
  bool activate(dom.WebGLRenderingContext gl) {
    if (!effect.isReady())
      return false;
    effect.bind( gl );
    // set parameters
    for (final Uniform uni in effect.uniforms)  {
      var value = parameters[uni.info.name];
      if (!value)
        return false;
      switch (uni.info.type)  {
      case dom.WebGLRenderingContext.FLOAT_VEC4:
        gl.uniform4fv( uni.location, value );
      }
    }
    return true;
  }
}
