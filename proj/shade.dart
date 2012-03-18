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
  Uniform( this.location, this.info );
}


class Effect extends Program  {
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
      uniforms.add( new Uniform(loc,info) );
    }
  }
  
  Effect( final dom.WebGLRenderingContext gl, final List<Unit> units ): super(gl),
  attributes = new Map<int,dom.WebGLActiveInfo>(), uniforms = new List<Uniform>()  {
  	if (!link( gl, units ))
  		return;
    fillAttributes( gl );
    fillUniforms( gl );
  }
}


interface IDataSource  {
  Object askData(final String name);
}


class Instance  {
  final Effect effect;
  final Map<String,Object> parameters;
  final List<IDataSource> dataSources;
  
  Instance( this.effect ):
    parameters = new Map<String,Object>(),
    dataSources = new List<IDataSource>();

  Instance.from( Instance other ): effect = other.effect,
    parameters = new Map<String,Object>.from( other.parameters ),
    dataSources = new List<IDataSource>.from( other.dataSources );
  
  // note: some parameters might not be there
  void gatherData()  {
    for (final Uniform uni in effect.uniforms)  {
      for(final IDataSource source in dataSources)  {
        final Object value = source.askData( uni.info.name );
        if (value!=null)  {
          parameters[uni.info.name] = value;
          break; 
        }
      }
    }
  }
  
  void loadDefaults( dom.WebGLRenderingContext gl ){
    for(final Uniform uni in effect.uniforms) {
      final val = gl.getUniform( effect.getLiveHandle(), uni.location );
      parameters[uni.info.name] = val;
    }
  }
  
  bool _pushData( dom.WebGLRenderingContext gl ){
	final tex.Binding texBind = new tex.Binding.tex2d(gl);
    int texId = 0;
    for (final Uniform uni in effect.uniforms)  {
      var value = parameters[uni.info.name];
      if (value==null)	{
      	dom.window.console.debug('Parameter not found: ' + uni.info.name);
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
        gl.uniform1i( uni.location, texId );
        gl.activeTexture( dom.WebGLRenderingContext.TEXTURE0 + texId );
        texBind.bindRead( value );	// todo: unbind where?
        ++texId; break;
      case dom.WebGLRenderingContext.SAMPLER_CUBE:
        gl.uniform1i( uni.location, texId );
        gl.activeTexture( dom.WebGLRenderingContext.TEXTURE0 + texId );
        gl.bindTexture( dom.WebGLRenderingContext.TEXTURE_CUBE_MAP, value );
        ++texId; break;
      default: return false;
      }
    }
    if (texId>0)
	    gl.activeTexture( dom.WebGLRenderingContext.TEXTURE0 );
    return true;
  }
  
  bool activate( dom.WebGLRenderingContext gl ){
    gatherData();
    effect.bind(gl);
    _pushData(gl);
    return !effect.isFull() || _pushData(gl);
  }
}


class Manager	{
	final load.Loader loader;
	final Map<String,Unit>		_cacheUnit;
	final Map<String,Effect>	_cacheEffect;

	Manager(String home): loader = new load.Loader(home),
		_cacheUnit = new Map<String,Unit>(),
		_cacheEffect = new Map<String,Effect>();
	
	Instance assemble( final dom.WebGLRenderingContext gl, final List<String> paths)	{
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
		return new Instance(ef);
	}
}
