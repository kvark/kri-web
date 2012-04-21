#library('kri:frame');
#import('dart:html', prefix:'dom');
#import('core.dart', prefix:'core');
#import('tex.dart',  prefix:'tex');


class Color {
  final double r,g,b,a;
  
  Color( this.r, this.g, this.b, this.a );
  Color.black(): this(0.0,0.0,0.0,0.0);
  Color.white(): this(1.0,1.0,1.0,1.0);
  Color.safe( final Color c ): this(
  	c.r==null?0.0:c.r, c.g==null?0.0:c.g, c.b==null?0.0:c.b, c.a==null?0.0:c.a );
}

class Rect  {
  final int x,y,w,h;
  Rect( this.x, this.y, this.w, this.h );
  double aspect() => w.toDouble() / h.toDouble();
}




class Surface extends core.Handle<dom.WebGLRenderbuffer> implements tex.IPlane  {
  Surface(dom.WebGLRenderingContext gl): super( gl.createRenderbuffer(), null );
  Surface.zero(): super(null,null);
  
  //todo: use queries
  int getWidth() => 0;
  int getHeight() => 0;
  int getDepth() => 0;
}


interface ITarget  {
  void bind(dom.WebGLRenderingContext gl, int point);
}


class RenderSurface implements ITarget {
  final Surface surface;
  
  RenderSurface( this.surface );
  RenderSurface.zero(): surface = new Surface.zero();
  
  void bind(dom.WebGLRenderingContext gl, int point)  {
    gl.framebufferRenderbuffer( dom.WebGLRenderingContext.FRAMEBUFFER,
      point, dom.WebGLRenderingContext.RENDERBUFFER, surface.getInitHandle() );
  }
}


class RenderTexture implements ITarget {
  final tex.Texture texture;
  final int level;
  final int side;
  
  RenderTexture( this.texture, this.level ): side = dom.WebGLRenderingContext.TEXTURE2D;
  RenderTexture.fromCube( this.texture, this.level, this.side );
  
  void bind(dom.WebGLRenderingContext gl, int point)  {
    gl.framebufferTexture2D( dom.WebGLRenderingContext.FRAMEBUFFER,
      point, side, texture.getInitHandle(), level );
  }
}


class Buffer {
  final dom.WebGLFramebuffer handle;
  ITarget color = null, depth = null, stencil = null;
  ITarget _color = null, _depth = null, _stencil = null;
  final ITarget nullRender;
  
  Buffer._from( this.handle ): nullRender = new RenderSurface.zero();
  Buffer( final dom.WebGLRenderingContext gl ): this._from( gl.createFramebuffer() );
  Buffer.main(): this._from( null );
  
  void _update(final dom.WebGLRenderingContext gl, ITarget tNew, ITarget tOld, int slot)	{
  	if (tNew==tOld)
  		return;
  	(tNew==null ? tNew : nullRender).bind(gl,slot);
  	tOld = tNew;
  }
  
  void bind(final dom.WebGLRenderingContext gl)  {
  	gl.bindFramebuffer( dom.WebGLRenderingContext.FRAMEBUFFER, handle );
    _update( gl,color,_color,		dom.WebGLRenderingContext.COLOR_ATTACHMENT0 );
    _update( gl,depth,_depth,		dom.WebGLRenderingContext.DEPTH_ATTACHMENT );
    _update( gl,stencil,_stencil,	dom.WebGLRenderingContext.STENCIL_ATTACHMENT );
  }
}


class Control  {
  final dom.WebGLRenderingContext gl;
  
  Control( this.gl );
  
  Buffer spawn()  => new Buffer(gl);
  
  void bind( final Buffer buf ){
  	buf.bind( gl );
  }
  
  // helper functions
  
  void viewport(final Rect r, double zMin, double zMax)	{
  	gl.viewport( r.x, r.y, r.w, r.h );
  	gl.depthRange( zMin, zMax );
  }
  
  void clear(final Color color, double depth, int stencil) {
    int mask = 0;
    if (color != null) {
      mask += dom.WebGLRenderingContext.COLOR_BUFFER_BIT;
      gl.clearColor( color.r, color.g, color.b, color.a );
    }
    if (depth != null)  {
      mask += dom.WebGLRenderingContext.DEPTH_BUFFER_BIT;
      gl.clearDepth( depth );
    }
    if (stencil != null)  {
      mask += dom.WebGLRenderingContext.STENCIL_BUFFER_BIT;
      gl.clearStencil( stencil );
    }
    gl.clear( mask );
  }
  
  dom.Uint8Array readUint8(final Rect rect, final String format)	{
  	int idFormat = 0, count = 0;
  	if (format == 'rgba')	{
  		idFormat = dom.WebGLRenderingContext.RGBA;
  		count = 4;
  	}
  	assert( idFormat!=0 && count!=0 );
  	final dom.Uint8Array array = new dom.Uint8Array( rect.w * rect.h * count );
	gl.readPixels( rect.x, rect.y, rect.w, rect.h,
		idFormat, dom.WebGLRenderingContext.UNSIGNED_BYTE, array );  	
	return array;
  }
}
