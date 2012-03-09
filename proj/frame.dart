#library('frame');
#import('dart:html', prefix:'dom');
#import('core.dart', prefix:'core');
#import('help.dart', prefix:'help');
#import('tex.dart',  prefix:'tex');


class Color {
  final double r,g,b,a;
  
  Color( this.r, this.g, this.b, this.a );
  Color.black(): this(0.0,0.0,0.0,0.0);
  Color.white(): this(1.0,1.0,1.0,1.0);
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
  RenderSurface.zero(): surface = Surface.zero();
  
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
  
  Buffer( final dom.WebGLRenderingContext gl ):
  	handle = gl.createFramebuffer(),
    nullRender = new RenderSurface.zero();

  Buffer.main(): handle = null;
  
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
  
  // helper functions
  
  void scissor(final Rect r)  => gl.scissor ( r.x, r.y, r.w, r.h );
  
  void viewport(final Rect r) => gl.viewport( r.x, r.y, r.w, r.h ); 
  
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
}
