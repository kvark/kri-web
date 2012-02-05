#library('buff');
#import('dart:dom');


class Unit  {
  final WebGLBuffer handle;
  
  Unit(WebGLRenderingContext gl): handle = gl.createBuffer();
  Unit.invalid(): handle=null;
}


class Binding {
  final int target;
  
  Binding(int value): target=value;
  Binding.array(): this( WebGLRenderingContext.ARRAY_BUFFER );
  Binding.index(): this( WebGLRenderingContext.ELEMENT_ARRAY_BUFFER );

  void put( WebGLRenderingContext gl, Unit unit ) {
    gl.bindBuffer( target, unit.handle );
  }
}