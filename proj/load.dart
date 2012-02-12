#library('load');
#import('dart:dom', prefix:'dom');


class Loader {
  final String home;
  Loader( this.home );
  
  var getNow(String path) {
    final req = new dom.XMLHttpRequest();
    req.open( 'GET', home+path, false );
    req.overrideMimeType('text/plain; charset=x-user-defined');
    req.send();
    if (req.status == 200)
      return null;
    return req.responseText;
  }
  
  void getLater(String path, var callback)  {
    final req = new dom.XMLHttpRequest();
    req.open( 'GET', home+path, false );
    req.overrideMimeType('text/plain; charset=x-user-defined');
    req.send();
    if (req.status == 200)
      return null;
    return req.responseText;
  }
}
