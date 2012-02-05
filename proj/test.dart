#import('dart:dom');
#source('shade.dart');



class test {
 
  test() {}
  
  void run() {
    write("Hello World!");
    
    final HTMLCanvasElement canvas = document.getElementById("canvas");
    final WebGLRenderingContext gl = canvas.getContext("experimental-webgl");
    
    gl.viewport(0, 0, canvas.width, canvas.height);
    gl.clearColor(0.0, 0.5, 1.0, 1.0);
    gl.enable(WebGLRenderingContext.DEPTH_TEST);
    
    // draw  scene
    gl.clear(WebGLRenderingContext.COLOR_BUFFER_BIT | WebGLRenderingContext.DEPTH_BUFFER_BIT);
  }
  
  void write(String message) {
    // the HTML library defines a global "document" variable
    //document.query('#status').innerHTML = message;
    HTMLLabelElement  l = document.getElementById('status'); //  = message;
    l.innerText = message;
  }
}


void main() {
  new test().run();
}