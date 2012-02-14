#library('help');
#import('dart:dom', prefix:'dom');

class Enum	{
 final Map<String,int> polyTypes, frameAttachments;

 Enum(): polyTypes = {
  	'1':  dom.WebGLRenderingContext.POINTS,
  	'2':  dom.WebGLRenderingContext.LINES,
  	'2l': dom.WebGLRenderingContext.LINE_LOOP,
  	'2s': dom.WebGLRenderingContext.LINE_STRIP,
  	'3':  dom.WebGLRenderingContext.TRIANGLES,
  	'3f': dom.WebGLRenderingContext.TRIANGLE_FAN,
  	'3s': dom.WebGLRenderingContext.TRIANGLE_STRIP
  }, frameAttachments = {
    'd'   : dom.WebGLRenderingContext.DEPTH_ATTACHMENT,
    's'   : dom.WebGLRenderingContext.STENCIL_ATTACHMENT,
    'ds'  : dom.WebGLRenderingContext.DEPTH_STENCIL_ATTACHMENT,
    'c0'  : dom.WebGLRenderingContext.COLOR_ATTACHMENT0+0,
    'c1'  : dom.WebGLRenderingContext.COLOR_ATTACHMENT0+1,
    'c2'  : dom.WebGLRenderingContext.COLOR_ATTACHMENT0+2,
    'c3'  : dom.WebGLRenderingContext.COLOR_ATTACHMENT0+3,
  };
}
