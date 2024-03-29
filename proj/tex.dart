#library('kri:tex');
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
	
	Texture spawn() => new Texture( gl, null );
	
	void _bind( dom.WebGLTexture handle ){
		gl.bindTexture( target, handle );
	}
	
	void bindRead( final Texture tex )=> _bind( tex.getLiveHandle() );
	void unbind() => _bind( null );
	
	abstract void _initRaw( final LevelInfo lev );
	
	void init( final Texture tex, final LevelInfo lev)	{
		_bind( tex.getInitHandle() );
		_initRaw( lev );
		tex.setAllocated();
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

class Binding2D extends Binding	{
	Binding2D( dom.WebGLRenderingContext context ):
		super( context, dom.WebGLRenderingContext.TEXTURE_2D );
	
	void _initRaw( final LevelInfo lev ){
		gl.texImage2D( target, lev.level, lev.internalFormat, lev.width, lev.height, 0 );
	}
	void _loadRaw( final LevelInfo lev, final Data data ){
		gl.texImage2D( target, lev.level, lev.internalFormat,
			lev.width, lev.height, 0, data.format, data.type, data.buffer );
	}
	void load( final Texture tex, final LevelInfo lev, final Data data){
		_bind( tex.getInitHandle() );
		_loadRaw( lev, data );
		tex.setFull();
		_bind( null );
	}
}

class BindingCube extends Binding	{
	final List<int> subFaces;
	BindingCube( dom.WebGLRenderingContext context ):
		super( context, dom.WebGLRenderingContext.TEXTURE_CUBE_MAP ),
		subFaces = [
			dom.WebGLRenderingContext.TEXTURE_CUBE_MAP_POSITIVE_X,
			dom.WebGLRenderingContext.TEXTURE_CUBE_MAP_NEGATIVE_X,
			dom.WebGLRenderingContext.TEXTURE_CUBE_MAP_POSITIVE_Y,
			dom.WebGLRenderingContext.TEXTURE_CUBE_MAP_NEGATIVE_Y,
			dom.WebGLRenderingContext.TEXTURE_CUBE_MAP_POSITIVE_Z,
			dom.WebGLRenderingContext.TEXTURE_CUBE_MAP_NEGATIVE_Z,
			];

	void _initRaw( final LevelInfo lev ){
		for (int subTarget in subFaces)
			gl.texImage2D( subTarget, lev.level, lev.internalFormat, lev.width, lev.height, 0 );
	}
	void _loadRaw( final LevelInfo lev, final List<Data> data ){
		for (int i=0; i<subFaces.length; ++i)	{
			gl.texImage2D( subFaces[i], lev.level, lev.internalFormat,
				lev.width, lev.height, 0, data[i].format, data[i].type, data[i].buffer );
		}
	}
	void load( final Texture tex, final LevelInfo lev, final List<Data> data ){
		_bind( tex.getInitHandle() );
		_loadRaw( lev, data );
		tex.setFull();
		_bind( null );
	}
}


class Accumulator extends Binding2D	{
	final List<Texture> slots;
	final Texture nullTexture;
	
	Accumulator( dom.WebGLRenderingContext gl ): super(gl),
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
	final Binding2D bid;
	
	Manager( dom.WebGLRenderingContext gl, String path ): super.buffer( path ), bid = new Binding2D(gl);
	
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
