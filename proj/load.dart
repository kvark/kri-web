#library('load');
#import('dart:html', prefix:'dom');


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
		return _iter.next();
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
			rez.add( getByte() );
		return rez;
	}
	
	String getString()	{
		final int num = getByte();
		return new String.fromCharCodes( getMultiple(num) );
	}
	
	bool empty() => !_iter.hasNext();
}

class BinaryReader extends IntReader	{
	final dom.Uint8Array array;
	
	BinaryReader( final dom.ArrayBuffer buffer ):
		array = new dom.Uint8Array.fromBuffer(buffer),
		super( array.iterator() );
	
	dom.Uint8Array getArray(int size)	{
		skip(size);
		return array.subarray(_offset-size,_offset);
	}
}

class TextReader extends IntReader	{
	final String text;
	
	TextReader( this.text ):
		super( text.charCodes().iterator() );

	dom.Uint8Array getArray(int size)	{
		final String sub = text.substring( _offset, _offset+size );
		skip(size);
		return new dom.Uint8Array.from( sub.charCodes() );
	}
}



class Loader {
  final String home;
  Loader( this.home );
  
  dom.XMLHttpRequest makeRequest( String path, bool async ){
    final req = new dom.XMLHttpRequest();
    req.open( 'GET', home+path, async );
    req.overrideMimeType('text/plain; charset=x-user-defined');
    return req;
  }
  
  var getNow( String path ){
    final req = makeRequest( path, false );
    req.send();
    if (req.status != 200)
      return null;
    return req.responseText;
  }
  
  dom.XMLHttpRequest getLater( String path, var callback ){
    final req = makeRequest( path, true );
    req.onreadystatechange = () {
      //if (req.readyState==req.DONE)
      callback( req.responseText );
    };
    req.send();
    return req;
  }
}
