#library('load');
#import('dart:dom', prefix:'dom');


class Manager<Type>	{
	final bool callAsync = true;
	final String home, dataType;
	final Map<String,Type> _cache;
	
	abstract Type spawn( Type fallback );
	abstract void fill( Type target, final data );
	
	Manager( this.home, this.dataType ):
	  _cache = new Map<String,Type>();
	
	Manager.text	( String path ): this( path, 'text' );
	Manager.buffer	( String path ): this( path, 'arraybuffer' );
	
	Type load( String name, Type fallback ){
		Type result = _cache[name];
		if (result==null)	{
			_cache[name] = result = spawn( fallback );
			// send AJAX request
			final req = new dom.XMLHttpRequest();
			req.open( 'GET', home+name, callAsync );
			req.overrideMimeType('text/plain; charset=x-user-defined');
			req.responseType = dataType;
			req.addEventListener('load', (event) {
				fill( result, req.response );
			});
			req.send();
		}
    	return result;
	}
}


class BinaryReader	{
	final dom.Uint8Array array;
	final dom.Iterator<int> _iter;
	int _offset = 0;
	
	BinaryReader( final dom.ArrayBuffer buffer ):
		array = new dom.Uint8Array.fromBuffer(buffer),
		_iter = array.iterator();
	
	int getOffset() => _offset;
	dom.Uint8Array getSubArray(int size) => array.subarray(_offset,_offset+size);

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
