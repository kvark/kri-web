#library('mesh');
#import('dart:dom',   prefix:'dom');
#import('buff.dart',  prefix:'buff');
#import('shade.dart', prefix:'shade');
#import('help.dart',  prefix:'help');
#import('load.dart',  prefix:'load');


class Elem  {
  // semantics
  final int type;
  final bool normalized;
  final int count;
  // location
  final buff.Unit buffer;
  final int offset, stride;
  
  Elem( this.type, this.normalized, this.count, this.buffer, this.offset, this.stride );
  Elem.float32( this.count, this.buffer, this.offset, this.stride ):
    type = dom.WebGLRenderingContext.FLOAT, normalized=false;
  Elem.index16( this.buffer, this.offset ):
    type = dom.WebGLRenderingContext.UNSIGNED_SHORT, stride=0, count=0, normalized=false;
  Elem.index8 ( this.buffer, this.offset ):
    type = dom.WebGLRenderingContext.UNSIGNED_BYTE,  stride=0, count=0, normalized=false;
  
  void bind(dom.WebGLRenderingContext gl, int loc)  {
    gl.vertexAttribPointer( loc, count, type, normalized, offset, stride );
  }
}


class Mesh {
  final Map<String,Elem> elements;
  Elem indices = null;
  int nVert = 0, nInd = 0;
  final int polyType;
  
  Mesh(final String type):
    elements = new Map<String,Elem>(),
  	polyType = new help.Enum().polyTypes[type];
  
  bool contains(final dom.WebGLActiveInfo info)  {
    final Elem el = elements[info.name];
    return el!=null;  //todo: check all fields
  }
  
  bool draw(final dom.WebGLRenderingContext gl, final shade.Instance shader)  {
    // check consistency
    for (final dom.WebGLActiveInfo info in shader.effect.attributes.getValues()) {
      if(!contains(info))
        return false;
    }
    if (!shader.activate(gl))
      return false;
    // prepare
    buff.Binding bindArray = new buff.Binding.array(gl);
    shader.effect.attributes.forEach((int loc, final dom.WebGLActiveInfo info) {
      final Elem el = elements[info.name];
      bindArray.bindRead( el.buffer );
      el.bind( gl, loc );
      gl.enableVertexAttribArray( loc );
    });
    bindArray.unbind();
    // draw
    if (indices != null)  {
      buff.Binding bindIndex = new buff.Binding.index(gl);
      bindIndex.bindRead( indices.buffer );
      gl.drawElements( polyType, nInd, indices.type, 0 );
      bindIndex.unbind();
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



class Manager extends load.Manager<Mesh>	{
	final dom.WebGLRenderingContext gl;
	
	Manager( this.gl, String path ): super(path);
	
	Mesh spawn(Mesh fallback) => new Mesh('3');
	
	void fill(Mesh m, String data)	{
		//do something!
	}
}
