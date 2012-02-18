#library('load');
#import('dart:dom', prefix:'dom');


class Manager<Type>	{
	final bool callAsync = true;
	final String home;
	final Map<String,Type> _cache;
	
	abstract Type spawn( Type fallback );
	abstract void fill( Type target, String data );
	
	Manager( this.home ):
	  _cache = new Map<String,Type>();
	
	Type load( String name, Type fallback ){
		Type result = _cache[name];
		if (result!=null)
			return result;
		_cache[name] = result = spawn( fallback );
		// send AJAX request
		final req = new dom.XMLHttpRequest();
		req.open( 'GET', home+name, callAsync );
	    req.overrideMimeType('text/plain; charset=x-user-defined');
		req.onreadystatechange = () {
   	  		if (req.readyState==req.DONE)
   				fill( result, req.responseText );
   			// check error
    	};
    	req.send();
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
