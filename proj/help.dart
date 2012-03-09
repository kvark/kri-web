#library('help');
#import('dart:html', prefix:'dom');

class Enum	{
 final Map<String,int> polyTypes;

 Enum(): polyTypes = {
  	'1':  dom.WebGLRenderingContext.POINTS,
  	'2':  dom.WebGLRenderingContext.LINES,
  	'2l': dom.WebGLRenderingContext.LINE_LOOP,
  	'2s': dom.WebGLRenderingContext.LINE_STRIP,
  	'3':  dom.WebGLRenderingContext.TRIANGLES,
  	'3f': dom.WebGLRenderingContext.TRIANGLE_FAN,
  	'3s': dom.WebGLRenderingContext.TRIANGLE_STRIP
  };
}


dom.Float32Array toFloat32	(final List<double> li)	=> new dom.Float32Array	.fromList(li);
dom.Uint16Array toUint16	(final List<int> li)	=> new dom.Uint16Array	.fromList(li);
dom.Uint8Array toUint8		(final List<int> li)	=> new dom.Uint8Array	.fromList(li);
