#library('buff');
#import('dart:dom');


class Unit  {
  final WebGLBuffer handle;
  
  Unit(WebGLRenderingContext gl): handle = gl.createBuffer();
  Unit.zero(): handle = null;
}


class Binding {
  WebGLRenderingContext gl;
  final int target;
 
  Binding( this.gl, this.target );
  
  Binding.array(WebGLRenderingContext context):
    this( context, WebGLRenderingContext.ARRAY_BUFFER );
  Binding.index(WebGLRenderingContext context):
    this( context, WebGLRenderingContext.ELEMENT_ARRAY_BUFFER );

  void put(final Unit unit) {
    gl.bindBuffer( target, unit.handle );
  }
  void clear() {
    gl.bindBuffer( target, null );
  }
  void load(var data_OR_size) {
    gl.bufferData( target, data_OR_size, WebGLRenderingContext.STATIC_DRAW );
  }
  
  Unit spawn(var data_OR_size) {
    Unit unit = new Unit( gl );
    put( unit );
    load( data_OR_size );
    clear();
    return unit;
  }
}