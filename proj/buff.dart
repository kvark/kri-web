#library('buff');
#import('dart:html', prefix:'dom');
#import('core.dart', prefix:'core');


dom.Float32Array toFloat32	(final List<double> li)	=> new dom.Float32Array	.fromList(li);
dom.Uint16Array toUint16	(final List<int> li)	=> new dom.Uint16Array	.fromList(li);
dom.Uint8Array toUint8		(final List<int> li)	=> new dom.Uint8Array	.fromList(li);


class Unit extends core.Handle<dom.WebGLBuffer>  {
  Unit( final dom.WebGLRenderingContext gl, final Unit fallback ): super( gl.createBuffer(), fallback );
}


class Binding {
  final dom.WebGLRenderingContext gl;
  final int target;

  Binding( this.gl, this.target );
  
  Binding.array( dom.WebGLRenderingContext context ):
    this( context, dom.WebGLRenderingContext.ARRAY_BUFFER );
  Binding.index( dom.WebGLRenderingContext context ):
    this( context, dom.WebGLRenderingContext.ELEMENT_ARRAY_BUFFER );

  void _bind (dom.WebGLBuffer handle) {
    gl.bindBuffer( target, handle );
  }
  void _initRaw (int size)	{
	gl.bufferData( target, size, dom.WebGLRenderingContext.STATIC_DRAW );
  }
  void _loadRaw (final dom.ArrayBufferView data) {
    gl.bufferData( target, data, dom.WebGLRenderingContext.STATIC_DRAW );
  }
  
  void bindRead (final Unit unit)	=> _bind( unit.getLiveHandle() );
  void unbind()	=> _bind( null );
  
  void init (final Unit unit, int size)	{
  	_bind( unit.getInitHandle() );
  	_initRaw( size );
  	unit.setAllocated();
  	_bind( null );
  }
  
  void load (final Unit unit, final dom.ArrayBufferView data)	{
   	_bind( unit.getInitHandle() );
  	_loadRaw( data );
  	unit.setFull();
  	_bind( null );
  }
  
  Unit spawn (final dom.ArrayBufferView data) {
    final Unit unit = new Unit(gl,null);
    load( unit, data );
    return unit;
  }
}
