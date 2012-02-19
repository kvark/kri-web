#library('frame');
#import('dart:dom',  prefix:'dom');
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
  final Map<int,ITarget> _attachments;
  final List<int> _slotsChanged;
  final ITarget nullRender;
  final help.Enum helpEnum;
  
  Buffer( final dom.WebGLRenderingContext gl ):
  	handle = gl.createFramebuffer(),
    _attachments = new Map<int,ITarget>(),
    _slotsChanged = new List<int>(),
    nullRender = new RenderSurface.zero(),
    helpEnum = new help.Enum();

  Buffer.main(): handle = null;
  
  bool attach(String name, ITarget target)  {
    final int point = helpEnum.frameAttachments[name];
    if (handle==null || point==null)
      return false;
    _slotsChanged.add( point );
    _attachments[point] = target;
    return true;
  }
  
  ITarget query(String name) => _attachments[helpEnum.frameAttachments[name]];
  
  void updateSlots(final dom.WebGLRenderingContext gl)  {
    for (int point in _slotsChanged) {
      final ITarget target = _attachments[point];
      (target!=null ? target : nullRender).bind( gl, point );
    }
    _slotsChanged.clear();
  }
}


class Control  {
  final dom.WebGLRenderingContext gl;
  
  Control( this.gl );
  
  Buffer spawn()  => new Buffer(gl);
  
  void bind(final Buffer buf)  {
    gl.bindFramebuffer( dom.WebGLRenderingContext.FRAMEBUFFER, buf.handle );
    buf.updateSlots( gl );
  }
  
  void unbind()  {
    gl.bindFramebuffer( dom.WebGLRenderingContext.FRAMEBUFFER, null );
  }
  
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
