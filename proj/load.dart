#library('load');
#import('dart:dom', prefix:'dom');


class Loader {
  final String home;
  Loader( this.home );
  
  dom.XMLHttpRequest makeRequest(String path, bool async)  {
    final req = new dom.XMLHttpRequest();
    req.open( 'GET', home+path, async );
    req.overrideMimeType('text/plain; charset=x-user-defined');
    return req;
  }
  
  var getNow(String path) {
    final req = makeRequest( path, false );
    req.send();
    if (req.status != 200)
      return null;
    return req.responseText;
  }
  
  void getLater(String path, var callback)  {
    final req = makeRequest( path, true );
    req.onreadystatechange = () {
      //if (req.readyState==req.DONE)
      callback( req.responseText );
    };
    req.send();
  }
}
