#library('tex');
#import('dart:dom',  prefix:'dom');
#import('core.dart', prefix:'core');
#import('load.dart', prefix:'load');


interface IPlane {
	int getWidth();
	int getHeight();
	int getDepth();
}


class Texture extends core.Handle<dom.WebGLTexture> implements IPlane {
  Texture( final dom.WebGLRenderingContext gl, final Texture fallback ):
  	super( gl.createTexture(), fallback );

  Texture.zero(): super(null,null);
  
  //todo: use queries
  int getWidth()	=> 0;
  int getHeight()	=> 0;
  int getDepth()	=> 0;
}


class Data	{
	final dom.ArrayBufferView buffer;
	final int format, type;
	
	Data( this.buffer, this.format, this.type );
}


class Binding	{
	dom.WebGLRenderingContext gl;
	final int target;
	
	Binding( this.gl, this.target );
	
	Binding.tex2d( dom.WebGLRenderingContext context ):
	  this( context, dom.WebGLRenderingContext.TEXTURE_2D );
	
	void _bind( dom.WebGLTexture handle ){
		gl.bindTexture( target, handle );
	}
	
	void bindRead( final Texture tex )=> _bind( tex.getLiveHandle() );
	void unbind() => _bind( null );
	
	void _initRaw( int level, int width, int height, int internalFormat){
		gl.texImage2D( target, level, internalFormat, width, height, 0 );
	}
	void _loadRaw (int level, int width, int height, int internalFormat, final Data data){
		gl.texImage2D( target, level, internalFormat,
			width, height, 0, data.format, data.type, data.buffer );
	}
	
	void init( final Texture tex, int level, int width, int height, int intFormat)	{
		_bind( tex.getInitHandle() );
		_initRaw( level, width, height, intFormat );
		tex.setAllocated();
		_bind( null );
	}
	void load( final Texture tex, int level, int width, int height, int intFormat, final Data data){
		_bind( tex.getInitHandle() );
		_loadRaw( level, width, height, intFormat, data );
		tex.setFull();
		_bind( null );
	}
}


class Manager extends load.Manager<Texture>	{
	final dom.WebGLRenderingContext gl;
	
	Manager( this.gl, String path ): super(path);
	
	Texture spawn( Texture fallback )=> new Texture( gl, fallback );
	
	void fill( Texture tex, String data ){
		//do something!
	}
}
