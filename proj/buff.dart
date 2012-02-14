#library('buff');
#import('dart:dom', prefix:'dom');


class Unit  {
  final dom.WebGLBuffer handle;
  
  Unit(this.handle);
}


class Binding {
  dom.WebGLRenderingContext gl;
  final int target;
 
  Binding( this.gl, this.target );
  
  Binding.array(dom.WebGLRenderingContext context):
    this( context, dom.WebGLRenderingContext.ARRAY_BUFFER );
  Binding.index(dom.WebGLRenderingContext context):
    this( context, dom.WebGLRenderingContext.ELEMENT_ARRAY_BUFFER );

  void bind(final Unit unit) {
    gl.bindBuffer( target, unit.handle );
  }
  void unbind() {
    gl.bindBuffer( target, null );
  }
  void load(var data_OR_size) {
    gl.bufferData( target, data_OR_size, dom.WebGLRenderingContext.STATIC_DRAW );
  }
  
  static dom.Float32Array toFloat32(final List<double> li)	=> new dom.Float32Array.fromList(li);
  static dom.Int16Array toInt16(final List<int> li)			=> new dom.Int16Array.fromList(li);
  static dom.Int8Array toInt8(final List<int> li)			=> new dom.Int8Array.fromList(li);
  
  Unit spawn() => new Unit( gl.createBuffer() );
  
  Unit spawnLoad(var data_OR_size) {
    final Unit unit = spawn();
    bind( unit );
    load( data_OR_size );
    unbind();
    return unit;
  }
}
