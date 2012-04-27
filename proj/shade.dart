#library('kri:shade');
#import('dart:html',  prefix:'dom');
#import('core.dart',  prefix:'core');
#import('frame.dart', prefix:'frame');
#import('load.dart',  prefix:'load');


class Unit extends core.Handle<dom.WebGLShader> {
  String _infoLog = null;

  Unit( final dom.WebGLRenderingContext gl, int type, String text ):
  super( gl.createShader(type), null ) {
    gl.shaderSource( _handle, text );
    gl.compileShader( _handle );
    _infoLog = gl.getShaderInfoLog( _handle );
    if( gl.getShaderParameter( _handle, dom.WebGLRenderingContext.COMPILE_STATUS ))
    	setFull();
    else
	    print(_infoLog);
  }
  
  String getLog() => _infoLog;
  
  Unit.vertex	( dom.WebGLRenderingContext gl, String text ):
  	this( gl, dom.WebGLRenderingContext.VERTEX_SHADER, text );
  Unit.fragment	( dom.WebGLRenderingContext gl, String text ):
  	this( gl, dom.WebGLRenderingContext.FRAGMENT_SHADER, text );
  
  Unit.invalid(): handle=null;
}


class Program extends core.Handle<dom.WebGLProgram> {
  String _infoLog = null;

  Program( final dom.WebGLRenderingContext gl ): super( gl.createProgram(), null );
  
  bool link( final dom.WebGLRenderingContext gl, final List<Unit> units ){
  	final dom.WebGLProgram h = getInitHandle();
    for (final Unit unit in units) {
      assert( unit.isFull() );
      gl.attachShader( h, unit.getLiveHandle() );
    }
    gl.linkProgram( h );
    _infoLog = gl.getProgramInfoLog( h );
	if (gl.getProgramParameter( h, dom.WebGLRenderingContext.LINK_STATUS ))	{
		setFull();
		return true;
	}
	setNone();
	print(_infoLog);
	return false;
  }
  
  String getLog() => _infoLog;
  
  Program.invalid(): super(null,null)	{ setFull(); }
  
  void bind( dom.WebGLRenderingContext gl ){
    gl.useProgram( getLiveHandle() );
  }
}


class Uniform {
  final dom.WebGLUniformLocation location;
  final dom.WebGLActiveInfo info;
  final Object defaultValue;
  Object value;
  Uniform( this.location, this.info, this.defaultValue )	{
  	value = defaultValue;
  }
}


interface IDataSource  {
  void fillData(final Map<String,Object> data);
}


class Effect extends Program implements IDataSource  {
  final Map<int,dom.WebGLActiveInfo> attributes;
  final List<Uniform> uniforms;
  
  void fillAttributes( final dom.WebGLRenderingContext gl ){
    attributes.clear();
    final h = getInitHandle();
    final int num = gl.getProgramParameter( h, dom.WebGLRenderingContext.ACTIVE_ATTRIBUTES );
    for (int i=0; i<num; ++i) {
      final dom.WebGLActiveInfo info = gl.getActiveAttrib( h, i );
      final int loc = gl.getAttribLocation( h, info.name );
      attributes[loc] = info;
    }
  }
  
  void fillUniforms( final dom.WebGLRenderingContext gl ){
    uniforms.clear();
    final h = getInitHandle();
    final int num = gl.getProgramParameter( h, dom.WebGLRenderingContext.ACTIVE_UNIFORMS );
    for (int i=0; i<num; ++i) {
      final dom.WebGLActiveInfo info = gl.getActiveUniform( h, i );
      final dom.WebGLUniformLocation loc = gl.getUniformLocation( h, info.name );
      final val = null; //gl.getUniform( h, loc ); // todo: 10 uniforms/sec is not acceptable
      uniforms.add( new Uniform(loc,info,val) );
    }
  }
  
  // imp: IDataSource
  void fillData( final Map<String,Object> data ){
    for(final Uniform uni in uniforms)
      data[uni.info.name] = uni.defaultValue;
  }
  
  bool activate( final dom.WebGLRenderingContext gl, final Map<String,Object> data, final bool complete ){
  	if (!isFull())
	  	return false;
  	bind( gl );
  	int texId = 0;
  	// load parameters
    for (final Uniform uni in uniforms)  {
      final value = data[uni.info.name];
      if (value==null && complete)	{
      	print("Parameter not found: ${uni.info.name}");
      	return false;
      }
      switch (uni.info.type)  {
      case dom.WebGLRenderingContext.FLOAT_VEC4:
        gl.uniform4fv( uni.location,
          new dom.Float32Array.fromList(value.toList()) );
        break;
      case dom.WebGLRenderingContext.FLOAT_MAT4:
        gl.uniformMatrix4fv( uni.location, false,
          new dom.Float32Array.fromList(value.toList()) );
        break;
      case dom.WebGLRenderingContext.SAMPLER_2D:
		gl.activeTexture( dom.WebGLRenderingContext.TEXTURE0 + texId );
        gl.uniform1i( uni.location, texId );
        gl.bindTexture( dom.WebGLRenderingContext.TEXTURE_2D, value.getLiveHandle() );
        ++texId; break;
      case dom.WebGLRenderingContext.SAMPLER_CUBE:
		gl.activeTexture( dom.WebGLRenderingContext.TEXTURE0 + texId );
        gl.uniform1i( uni.location, texId );
        gl.bindTexture( dom.WebGLRenderingContext.TEXTURE_CUBE_MAP, value.getLiveHandle() );
        ++texId; break;
      default: return false;
      }
    }
    return true;
  }
  
  // constructor
  Effect( final dom.WebGLRenderingContext gl, final List<Unit> units ): super(gl),
  attributes = new Map<int,dom.WebGLActiveInfo>(), uniforms = new List<Uniform>()  {
  	if (!link( gl, units ))
  		return;
    fillAttributes( gl );
    fillUniforms( gl );
  }
}


class Manager	{
	final load.Loader loader;
	final dom.WebGLRenderingContext gl;
	final Map<String,Unit>		_cacheUnit;
	final Map<String,Effect>	_cacheEffect;

	Manager( this.gl, String home ): loader = new load.Loader(home),
		_cacheUnit = new Map<String,Unit>(),
		_cacheEffect = new Map<String,Effect>();
	
	Unit loadUnit( final String path, int type ){
		Unit un = _cacheUnit[path];
		if (un == null)	{
			final String text = loader.getNow(path);
			if (type<=0 && path.endsWith('.glslv'))
				type = dom.WebGLRenderingContext.VERTEX_SHADER;
			if (type<=0 && path.endsWith('.glslf'))
				type = dom.WebGLRenderingContext.FRAGMENT_SHADER;
			_cacheUnit[path] = un = new Unit( gl, type, text );
		}
		return un;
	}
	
	Effect assemble( final List<String> paths ){
		final String mix = Strings.join(paths,'|');
		Effect ef = _cacheEffect[mix];
		if (ef==null)	{
			final List<Unit> units = new List<Unit>();
			for (final String sp in paths)
				units.add( loadUnit(sp,0) );
			_cacheEffect[mix] = ef = new Effect( gl, units );
		}
		return ef;
	}
}
