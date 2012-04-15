#library('tex');
#import('dart:html', prefix:'dom');
#import('core.dart', prefix:'core');
#import('load.dart', prefix:'load');


interface IPlane {
	int getWidth();
	int getHeight();
	int getDepth();
	int getSamples();
}


class Texture extends core.Handle<dom.WebGLTexture> implements IPlane {
  Texture( final dom.WebGLRenderingContext gl, final Texture fallback ):
  	super( gl.createTexture(), fallback );

  Texture.zero(): super(null,null);
  
  //todo: use queries
  int getWidth()	=> 0;
  int getHeight()	=> 0;
  int getDepth()	=> 0;
  int getSamples()	=> 0;
}


class Data	{
	final dom.ArrayBufferView buffer;
	final int format, type;
	
	Data( this.buffer, this.format, this.type );
	
	Data.color( final dom.Uint8Array array, bool alpha ): this( array,
		alpha ? dom.WebGLRenderingContext.RGBA : dom.WebGLRenderingContext.RGB,
		dom.WebGLRenderingContext.UNSIGNED_BYTE );
}

class LevelInfo	{
	int level;
	final int width, height;
	final int internalFormat;
	
	LevelInfo( this.level, this.width, this.height, this.internalFormat );
	
	LevelInfo.color( int w, int h, bool alpha ): this(0,w,h,
		alpha ? dom.WebGLRenderingContext.RGBA : dom.WebGLRenderingContext.RGB);
}


class Binding	{
	final dom.WebGLRenderingContext gl;
	final int target;
	
	Binding( this.gl, this.target );
	
	Binding.tex2d( dom.WebGLRenderingContext context ):
	  this( context, dom.WebGLRenderingContext.TEXTURE_2D );
	  
	Texture spawn() => new Texture( gl, null );
	
	void _bind( dom.WebGLTexture handle ){
		gl.bindTexture( target, handle );
	}
	
	void bindRead( final Texture tex )=> _bind( tex.getLiveHandle() );
	void unbind() => _bind( null );
	
	void _initRaw( final LevelInfo lev ){
		gl.texImage2D( target, lev.level, lev.internalFormat, lev.width, lev.height, 0 );
	}
	void _loadRaw( final LevelInfo lev, final Data data ){
		gl.texImage2D( target, lev.level, lev.internalFormat,
			lev.width, lev.height, 0, data.format, data.type, data.buffer );
	}
	
	void init( final Texture tex, final LevelInfo lev)	{
		_bind( tex.getInitHandle() );
		_initRaw( lev );
		tex.setAllocated();
		_bind( null );
	}
	void load( final Texture tex, final LevelInfo lev, final Data data){
		_bind( tex.getInitHandle() );
		_loadRaw( lev, data );
		tex.setFull();
		_bind( null );
	}
	
	void state( final Texture tex, bool filter, bool mips, int wrap ){
		_bind( tex.getInitHandle() );
		if (mips)
			gl.generateMipmap(target);
		gl.texParameteri( target, dom.WebGLRenderingContext.TEXTURE_MIN_FILTER, filter ?
			( mips ? dom.WebGLRenderingContext.LINEAR_MIPMAP_LINEAR	: dom.WebGLRenderingContext.LINEAR) :
			( mips ? dom.WebGLRenderingContext.NEAREST_MIPMAP_LINEAR: dom.WebGLRenderingContext.NEAREST)
			);
		gl.texParameteri( target, dom.WebGLRenderingContext.TEXTURE_MAG_FILTER,
			filter ? dom.WebGLRenderingContext.LINEAR : dom.WebGLRenderingContext.NEAREST );
		final int wrapMode = [
			dom.WebGLRenderingContext.MIRRORED_REPEAT,
			dom.WebGLRenderingContext.CLAMP_TO_EDGE,
			dom.WebGLRenderingContext.REPEAT
			][wrap+1];
		gl.texParameteri( target, dom.WebGLRenderingContext.TEXTURE_WRAP_S, wrapMode );
		gl.texParameteri( target, dom.WebGLRenderingContext.TEXTURE_WRAP_T, wrapMode );
		_bind( null );
	}
}


class Accumulator extends Binding	{
	final List<Texture> slots;
	final Texture nullTexture;
	
	Accumulator( dom.WebGLRenderingContext gl ): super.tex2d(gl),
		slots = new List<Texture>(), nullTexture = new Texture.zero();

	int append(final Texture tex)	{
		final int i = slots.length;
		gl.activeTexture( dom.WebGLRenderingContext.TEXTURE0 + i );
		bindRead( tex );
		slots.add( tex );
		return i;
	}

	int release()	{
		final int num = slots.length;
		for(int i=num; --i>=0; )	{
			gl.activeTexture( dom.WebGLRenderingContext.TEXTURE0 + i );
			bindRead( nullTexture );
		}
		return num;
	}
}


// image TGA loader
class Manager extends load.Manager<Texture>	{
	final Binding bid;
	
	Manager( dom.WebGLRenderingContext gl, String path ): super.buffer( path ), bid = new Binding.tex2d(gl);
	
	Texture spawn( Texture fallback )=> new Texture( bid.gl, fallback );
	
	void fill( final Texture tex, final load.IntReader br ){
		final log = dom.window.console;
		// read header
		final int idSize = br.getByte();
		final int cmType = br.getByte();
		final int imType = br.getByte();
		br.getLarge(5);	//color map info
		br.getLarge(4);	//xrig,yrig
		final int width  = br.getLarge(2);
		final int height = br.getLarge(2);
		final int bits	= br.getByte();
		final int descr	= br.getByte();
		// check header
		if (imType!=0 && imType!=2)	{
			log.debug('unknow image type');
			log.debug(imType);
			return;
		}
		// load data
		br.getLarge( idSize );	//skip id
		final levInfo = new LevelInfo.color( width, height, bits>24 );
		// warning: WebGL doesn't like internal format RGBA while the input format is RGB
		final texData = new Data.color( br.getArray( width*height*(bits>>3) ), bits>24 );
		//assert (texData.buffer.length == (bits>>3)*width*height);
		bid.load( tex, levInfo, texData );
	}
}
