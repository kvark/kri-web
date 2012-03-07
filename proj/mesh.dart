#library('mesh');
#import('dart:html',  prefix:'dom');
#import('buff.dart',  prefix:'buff');
#import('shade.dart', prefix:'shade');
#import('help.dart',  prefix:'help');
#import('load.dart',  prefix:'load');


class Element  {
  // semantics
  final int type;
  final bool normalized, canInterpolate;
  final int count;
  // location
  final buff.Unit buffer;
  final int stride, offset;
  
  Element( this.type, this.normalized, this.canInterpolate, this.count, this.buffer, this.stride, this.offset );
  Element.float32( this.count, this.buffer, this.stride, this.offset ):
    type = dom.WebGLRenderingContext.FLOAT, normalized=false, canInterpolate=true;
  Element.index16( buff.Unit buf, int off ):
  	this( dom.WebGLRenderingContext.UNSIGNED_SHORT,	false, false, 0, buf, 0, off );
  Element.index8 ( buff.Unit buf, int off ):
  	this( dom.WebGLRenderingContext.UNSIGNED_BYTE,	false, false, 0, buf, 0, off );
  
  void bind( final dom.WebGLRenderingContext gl, int loc ){
    gl.vertexAttribPointer( loc, count, type, normalized, stride, offset );
  }
}


class Mesh {
  final Map<String,Element> elements;
  final Mesh fallback;
  Element indices = null;
  int nVert = 0, nInd = 0;
  final List<shade.Effect> blackList;
  int polyType = 0;
  
  Mesh( this.fallback ):
  	elements = new Map<String,Element>(),
  	blackList = new List<shade.Effect>();

  void setPolygons(final String type)	{
  	polyType = new help.Enum().polyTypes[type];
  }
  
  bool contains(final dom.WebGLActiveInfo info)  {
    final Element el = elements[info.name];
    return el!=null;  //todo: check all fields
  }
  
  bool draw( final dom.WebGLRenderingContext gl, final shade.Instance shader ){
  	// try fallback
  	if (nVert==0)	{
  		if (fallback!=null)
  			return fallback.draw(gl,shader);
  		return false;
  	}
	if (blackList.indexOf( shader.effect )>=0)
		return false;
    // check consistency
    for (final dom.WebGLActiveInfo info in shader.effect.attributes.getValues()) {
    	if(!contains(info))	{
    		dom.window.console.debug('Mesh does not contain required attribute: ' + info.name);
    		blackList.add( shader.effect );
    		return false;
    	}
    }
    if (!shader.activate(gl))	{
	    dom.window.console.debug('Mesh failed to activate the shader');
    	blackList.add( shader.effect );
    	return false;
    }
    // prepare
    buff.Binding bindArray = new buff.Binding.array(gl);
    shader.effect.attributes.forEach((int loc, final dom.WebGLActiveInfo info) {
      final Element el = elements[info.name];
      bindArray.bindRead( el.buffer );
      el.bind( gl, loc );
      gl.enableVertexAttribArray( loc );
    });
    bindArray.unbind();
    // draw
    assert (polyType > 0);
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


// Mesh K3M loader
class Manager extends load.Manager<Mesh>	{
	final dom.WebGLRenderingContext gl;
	
	Manager( this.gl, String path ): super.buffer(path);
	
	Mesh spawn(Mesh fallback) => new Mesh(fallback);
	
	void fill( final Mesh m, final load.IntReader br ){
		final buff.Binding arrayBinding = new buff.Binding.array(gl);
		final log = dom.window.console;
		if (br.getString() != 'k3m')	{
			log.debug('Mesh signature is bad, skipping');
			return;
		}
		m.nVert	= br.getLarge(4);
		m.nInd	= br.getLarge(4);
		log.debug(m.nVert);
		log.debug(m.nInd);
		m.setPolygons( br.getString() );
		final int numBuffers = br.getByte();
		for (int iBuf=0; iBuf<numBuffers; ++iBuf)	{
			final buff.Unit unit = new buff.Unit( gl, null );
			final int stride = br.getByte();
			final String format = br.getString();
			log.debug(':'+format);
			int offset = 0;
			for (int i=0; i<format.length; i+=2)	{
				final int count = Math.parseInt( format[i+0] );
				int type = 0, eSize = 0;
				switch( format[i+1] ){
				case 'b':	type = dom.WebGLRenderingContext.BYTE;
					eSize = 1; break;
				case 'B':	type = dom.WebGLRenderingContext.UNSIGNED_BYTE;
					eSize = 1; break;
				case 'h':	type = dom.WebGLRenderingContext.SHORT;
					eSize = 2; break;
				case 'H':	type = dom.WebGLRenderingContext.UNSIGNED_SHORT;
					eSize = 2; break;
				case 'l': case 'i':	type = dom.WebGLRenderingContext.INT;
					eSize = 4; break;
				case 'L': case 'I':	type = dom.WebGLRenderingContext.UNSIGNED_INT;
					eSize = 4; break;
				case 'f':	type = dom.WebGLRenderingContext.FLOAT;
					eSize = 4; break;
				}
				final String name = 'a_' + br.getString();
				final bool fixedPoint	= br.getByte() > 0;
				final bool interpolate	= br.getByte() > 0;
				log.debug(' ' + name);
				final Element elem = new Element( type, fixedPoint, interpolate, count, unit, stride, offset );
				if (stride==0)	{
					assert (count==1);
					m.indices = elem;
				}else	{
					m.elements[name] = elem;
				}
				offset += eSize * count;
			}
			assert (stride==0 || offset == stride);
			//log.debug('Offset before block: ' + br.tell().toString());
			if (stride==0)	{
				final buff.Binding indexBinding = new buff.Binding.index(gl);
				indexBinding.load( unit, br.getArray(offset * m.nInd) );
			}else	{
				arrayBinding.load( unit, br.getArray(stride * m.nVert) );
			}
			//log.debug('Offset after block: ' + br.tell().toString());
		}
		log.debug('nVert: ' + m.nVert.toString());
		assert (br.empty());
	}
}
