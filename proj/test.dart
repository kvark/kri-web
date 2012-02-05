#import('dart:dom');
#import('shade.dart', prefix:'shade');
#import('buff.dart',  prefix:'buff');
#import('mesh.dart',  prefix:'mesh');



class test {
 
  test();
  
  void run() {
    final HTMLCanvasElement canvas = document.getElementById('canvas');
    final WebGLRenderingContext gl = canvas.getContext('experimental-webgl');
    
    gl.viewport( 0, 0, canvas.width, canvas.height );
    gl.clearColor( 0.0, 0.5, 1.0, 1.0 );
    gl.enable( WebGLRenderingContext.DEPTH_TEST );
    
    final String vertText = 'attribute vec3 a_position; void main() {gl_Position=vec4(a_position,1.0);}';
    shade.Unit shVert = new shade.Unit.vertex( gl, vertText );
    final String fragText = 'void main() {gl_FragColor=vec4(1.0,0.0,0.0,1.0);}';
    shade.Unit shFrag = new shade.Unit.fragment( gl, fragText );
    shade.Effect effect = new shade.Effect( gl, [shVert,shFrag] );
    write( effect.isReady() ? 'yes' : 'no' );
    
    List<double> vertices = [
                    0.0,  1.0,  0.0,
                   -1.0, -1.0,  0.0,
                    1.0, -1.0,  0.0
               ];
    final Float32Array vData = new Float32Array.fromList(vertices);
    List<int> indices = [0,1,2];
    final Int16Array iData = new Int16Array.fromList(indices);
    
    buff.Unit vBuffer = new buff.Unit( gl );
    gl.bindBuffer( WebGLRenderingContext.ARRAY_BUFFER, vBuffer.handle );
    gl.bufferData( WebGLRenderingContext.ARRAY_BUFFER, vData, WebGLRenderingContext.STATIC_DRAW );
    buff.Unit vIndex = new buff.Unit( gl );
    gl.bindBuffer( WebGLRenderingContext.ELEMENT_ARRAY_BUFFER, vIndex.handle );
    gl.bufferData( WebGLRenderingContext.ELEMENT_ARRAY_BUFFER, iData, WebGLRenderingContext.STATIC_DRAW );
    
    mesh.Elem vElem = new mesh.Elem.float( 3, vBuffer,0,0 );
    mesh.Elem iElem = new mesh.Elem.index( vIndex,0 );
    mesh.Mesh me = new mesh.Mesh();
    me.nVert = 3;
    me.nInd = 3;
    me.elements['a_position'] = vElem;
    me.indices = iElem;
    
    // draw  scene
    gl.clear( WebGLRenderingContext.COLOR_BUFFER_BIT | WebGLRenderingContext.DEPTH_BUFFER_BIT );
    me.draw( gl, effect );
    
    int err = gl.getError();
    if(err!=0)
      write("Error: $err");
  }
  
  void write(String message) {
    // the HTML library defines a global "document" variable
    HTMLLabelElement  l = document.getElementById('status'); //  = message;
    l.innerText = message;
  }
}


void main() {
  new test().run();
}