#library('kri:load');
#import('dart:html',	prefix:'dom');
#import('math.dart',	prefix:'math');
#import('space.dart',	prefix:'space');


class Manager<Type>	{
	final bool callAsync = true;
	final String home, dataType;
	final Map<String,Type> _cache;
	
	abstract Type spawn( Type fallback );
	abstract void fill( final Type target, final data );
	
	Manager( this.home, this.dataType ):
	  _cache = new Map<String,Type>();
	
	Manager.text	( String path ): this( path, 'text' );
	Manager.buffer	( String path ): this( path, 'arraybuffer' );
	
	Type load( final String name, final Type fallback ){
		Type result = _cache[name];
		if (result==null)	{
			_cache[name] = result = spawn( fallback );
			// send AJAX request
			final dom.XMLHttpRequest req = new dom.XMLHttpRequest();
			req.open( 'GET', home+name, callAsync );
			req.overrideMimeType('text/plain; charset=x-user-defined');
			//req.responseType = dataType;
			req.on.load.add((e) {
				if (dataType=='arraybuffer')
					//fill( result, req.response );
					fill( result, new TextReader(req.responseText) );
				else
					fill( result, req.responseText );
			});
			req.send();
		}
    	return result;
	}
}


class IntReader	{
	final dom.Iterator<int> _iter;
	int _offset = 0;
	
	IntReader( this._iter );
	
	int tell() => _offset;
	abstract dom.Uint8Array getArray(int size);

	int getByte()	{
		++_offset;
		return _iter.next() & 0xFF;
	}
	
	int getLarge(int num)	{
		int result = 0;
		for(int i=0; i<num; ++i)
			result += getByte() << (i<<3);
		return result;
	}
	
	void skip(int num)	{
		while(num>0)	{
			getByte();
			--num;
		}
	}
	
	List<int> getMultiple(int num)	{
		final List<int> rez = [];
		for(int i=0; i<num; ++i)
			rez.addLast( getByte() );
		return rez;
	}
	
	String getStringFixed(final int num) =>
		new String.fromCharCodes( getMultiple(num) );
	
	String getString() => getStringFixed( getByte() );
	
	double getReal()	{
		//todo: use Float32Array to extract doubles
		final List<int> bytes = getMultiple(4);
		final int power = ((bytes[3]&0x7F)<<1) + (bytes[2]>>7) - 127;
		final double sign = bytes[3]<0x80 ? 1.0 : -1.0;
		final int mant = bytes[0] + (bytes[1]<<8) + ((bytes[2]|0x80)<<16);
		return sign * mant * Math.pow( 0.5, 23-power );
	}
	
	List<double> getMultiReal(int num)	{
		final List<double> rez = [];
		for(int i=0; i<num; ++i)
			rez.addLast( getReal() );
		return rez;
		//final dom.Uint8Array blob = getArray(num*4);
		//return new dom.Float32Array.fromBuffer( blob.buffer );
	}
	
	math.Vector getVector3()	{
		final List<double> l = getMultiReal(3);
		return new math.Vector(l[0],l[1],l[2],0.0);
	}
	
	math.Quaternion getQuaternion()	{
		final List<double> l = getMultiReal(4);
		return new math.Quaternion(l[1],l[2],l[3],l[0]);
	}
	
	space.Space getSpace()	{
		final List<double> l = getMultiReal(8);
		return new space.Space(
			new math.Vector(l[0],l[1],l[2],0.0),
			new math.Quaternion(l[4],l[5],l[6],l[7]),
			l[3] );
	}
	
	bool empty() => !_iter.hasNext();
}


class Chunk	{
	final String name;
	final int end;
	Chunk( this.name, this.end );
}

class ChunkReader extends IntReader	{
	final List<Chunk> chunks;
	final String zeroChar;
	static final int nameSize = 8;
	
	ChunkReader( final dom.Iterator<int> it ):
		chunks = new List<Chunk>(),
		zeroChar = new String.fromCharCodes([0]),
		super(it);
	
	String enter()	{
		final String str = getStringFixed(nameSize).replaceAll(zeroChar,'');
		final int size = getLarge(4);
		chunks.addLast(new Chunk( str, tell()+size ));
		return str;
	}
	
	String leave()	{
		final Chunk ch = chunks.removeLast();
		assert( ch.end == tell() );
		skip( ch.end - tell() );
		return ch.name;
	}
	
	bool hasMore() => chunks.last().end > tell();
	
	void finish()	{
		leave();
		assert( empty() && chunks.length==0 );
	}
}



class BinaryReader extends ChunkReader	{
	final dom.Uint8Array array;
	
	BinaryReader( final dom.ArrayBuffer buffer ):
		array = new dom.Uint8Array.fromBuffer(buffer),
		super( array.iterator() );
	
	dom.Uint8Array getArray(int size)	{
		skip(size);
		return array.subarray(_offset-size,_offset);
	}
}


class TextReader extends ChunkReader	{
	final String text;
	
	TextReader( this.text ):
		super( text.charCodes().iterator() );

	dom.Uint8Array getArray(int size)	{
		final String sub = text.substring( _offset, _offset+size );
		skip(size);
		return new dom.Uint8Array.fromList( sub.charCodes() );
	}
}



class Loader {
  final String home;
  Loader( this.home );
  
  dom.XMLHttpRequest makeRequestMime( String path, String responseType, String mimeType ){
    final req = new dom.XMLHttpRequest();
    bool async = responseType!=null;
    req.open( 'GET', home+path, async );
    if (async)
	    req.responseType = responseType;
    if (mimeType!=null)
	    req.overrideMimeType(mimeType);
    return req;
  }
  
  dom.XMLHttpRequest makeRequest( String path, String type )=>
  	makeRequestMime( path, type, 'text/plain; charset=x-user-defined' );
  
  String getNowText( String path ){
    final req = makeRequest( path, null );
    req.send();
    if (req.status != 200)
      return null;
    return req.responseText;
  }

  dom.Document getNowXML( String path ){
    final req = makeRequestMime( path, 'document', 'text/xml' );
    req.send();
    if (req.status != 200)
      return null;
    return req.responseXML;
  }
  
  dom.XMLHttpRequest getLater( String path, void callback(String text) ){
    final req = makeRequest( path, 'text' );
    req.onreadystatechange = () {
      //if (req.readyState==req.DONE)
      callback( req.responseText );
    };
    req.send();
    return req;
  }
}
