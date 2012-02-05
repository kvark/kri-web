#library('buff');
#import('dart:dom');


class Unit  {
  final WebGLBuffer handle;
  
  Unit(WebGLRenderingContext gl): handle = gl.createBuffer();
}


class Binding {
  final int target;
  
  Binding(int value): target=value;
  
  Binding.array(): this( WebGLRenderingContext.ARRAY_BUFFER );
  Binding.index(): this( WebGLRenderingContext.ELEMENT_ARRAY_BUFFER );

  void put(WebGLRenderingContext gl, Unit unit) {
    gl.bindBuffer( target, unit.handle );
  }
  void clear(WebGLRenderingContext gl) {
    gl.bindBuffer( target, null );
  }
  void load(WebGLRenderingContext gl, var data_OR_size) {
    gl.bufferData( target, data_OR_size, WebGLRenderingContext.STATIC_DRAW );
  }
  
  Unit spawn(WebGLRenderingContext gl, var data_OR_size) {
    Unit unit = new Unit( gl );
    put( gl, unit );
    load( gl, data_OR_size );
    clear( gl );
    return unit;
  }
}