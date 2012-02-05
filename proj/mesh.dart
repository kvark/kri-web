#library('mesh');
#import('dart:dom');
#import('buff.dart',  prefix:'buff');
#import('shade.dart', prefix:'shade');


class Elem  {
  final buff.Unit buffer;
  final int type;
  final bool normalized;
  final int count;
  final int offset, stride;
  
  Elem( this.buffer, this.type, this.normalized, this.count, this.offset, this.stride );
  
  void bind(WebGLRenderingContext gl, int loc)  {
    gl.vertexAttribPointer( loc, count, type, normalized, offset, stride );
  }
}


class Mesh {
  final HashMap<String,Elem> elements;
  Elem indices = null;
  int nVert = 0;
  int nPoly = 0;
  int polyType = WebGLRenderingContext.TRIANGLES;
  
  Mesh(): elements = new HashMap<String,Elem>();
  
  bool contains(final WebGLActiveInfo info)  {
    final Elem el = elements[info.name];
    return el!=null;  //todo: check all fields
  }
  
  bool draw(WebGLRenderingContext gl, final shade.Effect effect)  {
    // check consistency
    if (!effect.isReady())
      return false;
    for (final WebGLActiveInfo info in effect.attributes.getValues()) {
      if(!contains(info))
        return false;
    }
    // helpers
    buff.Binding bindArray = new buff.Binding.array();
    buff.Binding bindIndex = new buff.Binding.index();
    shade.Program zeroProg = new shade.Program.invalid();
    // prepare
    effect.attributes.forEach((int loc, final WebGLActiveInfo info) {
      final Elem el = elements[info.name];
      bindArray.put( gl, el.buffer );
      el.bind( gl, loc );
      gl.enableVertexAttribArray( loc );
    });
    effect.bind( gl );
    // draw
    gl.drawArrays( polyType, 0, nVert );
    // cleanup
    for(int loc in effect.attributes.getKeys()) {
      gl.disableVertexAttribArray( loc );
    }
    zeroProg.bind( gl );
    return true;
  }
}
