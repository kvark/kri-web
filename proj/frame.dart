#library('frame');
#import('dart:dom');

class Color {
  double r,g,b,a;

  Color( this.r, this.g, this.b, this.a );
}


class Plane {
  int width, height, depth;
  int samples;
  
  Plane(): width=0, height=0, depth=0, samples=0;
}


class Surface extends Plane  {
  final WebGLRenderbuffer handle;
  
  Surface(WebGLRenderingContext gl): handle = gl.CreateRenderbuffer();
  Surface.zero(): handle = null;
}


class Texture extends Plane  {
  final WebGLTexture handle;
  
  Texture(WebGLRenderingContext gl): handle = gl.CreateTexture();
  Texture.zero(): handle = null;
}


interface IRender  {
  Plane getPlane();
  void bind(WebGLRenderingContext gl, int point);
}

class RenderSurface implements IRender {
  final Surface surface;
  
  RenderSurface( this.surface );
  RenderSurface.zero(): this( new Surface.zero() );
  
  Plane getPlane() => surface;
  void bind(WebGLRenderingContext gl, int point)  {
    gl.framebufferRenderbuffer( WebGLRenderingContext.FRAMEBUFFER, point, WebGLRenderingContext.RENDERBUFFER, surface.handle );
  }
}

class RenderTexture implements IRender {
  final Texture texture;
  final int level;
  final int side;
  
  RenderTexture( this.texture, this.level ): side = WebGLRenderingContext.TEXTURE2D;
  RenderTexture.fromCube( this.texture, this.level, this.side );
  
  Plane getPlane() => texture;
  void bind(WebGLRenderingContext gl, int point)  {
    gl.framebufferTexture2D( WebGLRenderingContext.FRAMEBUFFER, point, side, texture.handle, level );
  }
}


class Buffer {
  final WebGLFramebuffer handle;
  final Map<String,IRender> _attachments;
  final List<String> _namesChanged;
  final IRender nullRender;
  
  Buffer(WebGLRenderingContext gl):
    handle = gl.createFramebuffer(),
    _attachments = new Map<String,IRender>(),
    _namesChanged = new List<String>(),
    nullRender = new RenderSurface.zero();
  Buffer.main(): handle = null;
  
  void assign(String name, IRender target)  {
    assert( handle != null );
    _namesChanged.add( name );
    _attachments[name] = target;
  }
  
  IRender query(String name)  {
    return _attachments[name];
  }
  
  List<String> flushPending()  {
    final rez = _namesChanged;
    _namesChanged.clear();
    return rez;
  }
}


class Control  {
  final WebGLRenderingContext gl;
  
  static final Map<String,int> translation = {
    'd'   : WebGLRenderingContext.DEPTH_ATTACHMENT,
    's'   : WebGLRenderingContext.STENCIL_ATTACHMENT,
    'ds'  : WebGLRenderingContext.DEPTH_STENCIL_ATTACHMENT,
    'c0'  : WebGLRenderingContext.COLOR_ATTACHMENT0,
    'c1'  : WebGLRenderingContext.COLOR_ATTACHMENT1,
    'c2'  : WebGLRenderingContext.COLOR_ATTACHMENT2,
    'c3'  : WebGLRenderingContext.COLOR_ATTACHMENT3,
  };
  
  Control( this.gl );
  
  void put(final Buffer buf)  {
    gl.bindFramebuffer( WebGLRenderingContext.FRAMEBUFFER, buf.handle );
    if (!buf.handle)
      return;
    for (name in buf.flushPending()) {
      final int point = translation[name];
      final IRender target = buf.query(name);
      if (point!=null && target!=null)
        target.bind( gl, point );
    }
  }
  
  void clear()  {
    gl.bindFramebuffer( WebGLRenderingContext.FRAMEBUFFER, null );
  }
  
  // helper functions
  
  void clearScreen(Color color, double depth, int stencil) {
    int mask = 0;
    if (color != null) {
      mask += WebGLRenderingContext.COLOR_BUFFER_BIT;
      gl.clearColor( color.r, color.g, color.b, color.a );
    }
    if (depth != null)  {
      mask += WebGLRenderingContext.DEPTH_BUFFER_BIT;
      gl.clearDepth( depth );
    }
    if (stencil != null)  {
      mask += WebGLRenderingContext.STENCIL_BUFFER_BIT;
      gl.clearStencil( stencil );
    }
    gl.clear( mask );
  }
}
