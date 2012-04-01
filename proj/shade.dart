#library('shade');
#import('dart:html',  prefix:'dom');
#import('core.dart',  prefix:'core');
#import('frame.dart', prefix:'frame');
#import('tex.dart',	  prefix:'tex');
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
  
  // returns number of texture units occupied, or -1 if failed
  int activate( final dom.WebGLRenderingContext gl, final Map<String,Object> data, final bool complete ){
  	if (!isFull())
	  	return -1;
  	bind( gl );
  	// load parameters
  	final tex.Binding texBind = new tex.Binding.tex2d(gl);
    int texId = 0;
    for (final Uniform uni in uniforms)  {
      final value = data[uni.info.name];
      if (value==null && complete)	{
      	print("Parameter not found: ${uni.info.name}");
      	return ~texId;
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
        gl.uniform1i( uni.location, texId );
        gl.activeTexture( dom.WebGLRenderingContext.TEXTURE0 + texId );
        texBind.bindRead( value );	// todo: unbind where?
        ++texId; break;
      case dom.WebGLRenderingContext.SAMPLER_CUBE:
        gl.uniform1i( uni.location, texId );
        gl.activeTexture( dom.WebGLRenderingContext.TEXTURE0 + texId );
        gl.bindTexture( dom.WebGLRenderingContext.TEXTURE_CUBE_MAP, value );
        ++texId; break;
      default: return ~texId;
      }
    }
    return texId;
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
	final Map<String,Unit>		_cacheUnit;
	final Map<String,Effect>	_cacheEffect;

	Manager(String home): loader = new load.Loader(home),
		_cacheUnit = new Map<String,Unit>(),
		_cacheEffect = new Map<String,Effect>();
	
	Effect assemble( final dom.WebGLRenderingContext gl, final List<String> paths)	{
		final String mix = Strings.join(paths,'|');
		Effect ef = _cacheEffect[mix];
		if (ef==null)	{
			final List<Unit> units = new List<Unit>();
			for (final String sp in paths)	{
				Unit un = _cacheUnit[sp];
				if (un == null)	{
					final String text = loader.getNow(sp);
					int type = 0;
					if (sp.endsWith('.glslv'))
						type = dom.WebGLRenderingContext.VERTEX_SHADER;
					if (sp.endsWith('.glslf'))
						type = dom.WebGLRenderingContext.FRAGMENT_SHADER;
					_cacheUnit[sp] = un = new Unit( gl, type, text );
				}
				units.add(un);
			}
			_cacheEffect[mix] = ef = new Effect( gl, units );
		}
		return ef;
	}
}
