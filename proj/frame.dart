#library('frame');
#import('dart:dom',  prefix:'dom');
#import('help.dart', prefix:'help');


class Color {
  final double r,g,b,a;
  Color( this.r, this.g, this.b, this.a );
}

class Rect  {
  final int x,y,w,h;
  Rect( this.x, this.y, this.w, this.h );
  double aspect() => w.toDouble() / h.toDouble();
}



class Plane {
  int width, height, depth;
  int samples;
  
  Plane(): width=0, height=0, depth=0, samples=0;
}


class Surface extends Plane  {
  final dom.WebGLRenderbuffer handle;
  
  Surface(dom.WebGLRenderingContext gl): handle = gl.CreateRenderbuffer();
  Surface.zero(): handle = null;
}


class Texture extends Plane  {
  final dom.WebGLTexture handle;
  
  Texture(dom.WebGLRenderingContext gl): handle = gl.CreateTexture();
  Texture.zero(): handle = null;
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
      point, dom.WebGLRenderingContext.RENDERBUFFER, surface.handle );
  }
}


class RenderTexture implements ITarget {
  final Texture texture;
  final int level;
  final int side;
  
  RenderTexture( this.texture, this.level ): side = dom.WebGLRenderingContext.TEXTURE2D;
  RenderTexture.fromCube( this.texture, this.level, this.side );
  
  void bind(dom.WebGLRenderingContext gl, int point)  {
    gl.framebufferTexture2D( dom.WebGLRenderingContext.FRAMEBUFFER, point, side, texture.handle, level );
  }
}


class Buffer {
  final dom.WebGLFramebuffer handle;
  final Map<int,ITarget> _attachments;
  final List<int> _slotsChanged;
  final ITarget nullRender;
  final help.Enum helpEnum;
  
  Buffer( this.handle ):
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
  
  void updateSlots(dom.WebGLRenderingContext gl)  {
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
  
  Buffer spawn()  => new Buffer( gl.createFramebuffer() );
  
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
  
  void clear(Color color, double depth, int stencil) {
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
