#library('mesh');
#import('dart:dom');
#import('buff.dart',  prefix:'buff');
#import('shade.dart', prefix:'shade');


class Elem  {
  // semantics
  final int type;
  final bool normalized;
  final int count;
  // location
  final buff.Unit buffer;
  final int offset, stride;
  
  Elem( this.type, this.normalized, this.count, this.buffer, this.offset, this.stride );
  Elem.float32(this.count, this.buffer, this.offset, this.stride)
  : type = WebGLRenderingContext.FLOAT, normalized=false;
  Elem.index16(this.buffer, this.offset)
  : type = WebGLRenderingContext.UNSIGNED_SHORT, stride=0, count=0, normalized=false;
  
  void bind(WebGLRenderingContext gl, int loc)  {
    gl.vertexAttribPointer( loc, count, type, normalized, offset, stride );
  }
}


class Mesh {
  final Map<String,Elem> elements;
  Elem indices = null;
  int nVert = 0, nInd = 0;
  int polyType = WebGLRenderingContext.TRIANGLES;
  
  Mesh(): elements = new Map<String,Elem>();
  
  bool contains(final WebGLActiveInfo info)  {
    final Elem el = elements[info.name];
    return el!=null;  //todo: check all fields
  }
  
  bool draw(WebGLRenderingContext gl, final shade.Instance shader)  {
    // check consistency
    for (final WebGLActiveInfo info in shader.effect.attributes.getValues()) {
      if(!contains(info))
        return false;
    }
    if (!shader.activate(gl))
      return false;
    // prepare
    buff.Binding bindArray = new buff.Binding.array();
    shader.effect.attributes.forEach((int loc, final WebGLActiveInfo info) {
      final Elem el = elements[info.name];
      bindArray.put( gl, el.buffer );
      el.bind( gl, loc );
      gl.enableVertexAttribArray( loc );
    });
    bindArray.clear( gl );
    // draw
    if (indices != null)  {
      buff.Binding bindIndex = new buff.Binding.index();
      bindIndex.put( gl, indices.buffer );
      gl.drawElements( polyType, nInd, indices.type, 0 );
      bindIndex.clear( gl );
    }else {
      gl.drawArrays( polyType, 0, nVert ); 
    }
    // cleanup
    for(int loc in shader.effect.attributes.getKeys()) {
      gl.disableVertexAttribArray( loc );
    }
    new shade.Program.invalid().bind( gl );
    return true;
  }
}
