#import('dart:dom');
#import('shade.dart', prefix:'shade');
#import('buff.dart',  prefix:'buff');
#import('mesh.dart',  prefix:'mesh');



class test {
 
  test() {}
  
  void run() {
    //write("Hello World!");
    
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
    int atPos = gl.getAttribLocation( effect.handle, 'a_position' );
    
    List<double> vertices = [
                    0.0,  1.0,  0.0,
                   -1.0, -1.0,  0.0,
                    1.0, -1.0,  0.0
               ];
    Float32Array data = new Float32Array.fromList(vertices);
    
    buff.Unit buffer = new buff.Unit(gl);
    //WebGLBuffer buf = gl.createBuffer();
    gl.bindBuffer( WebGLRenderingContext.ARRAY_BUFFER, buffer.handle );
    gl.bufferData( WebGLRenderingContext.ARRAY_BUFFER, data, WebGLRenderingContext.STATIC_DRAW );
    //gl.vertexAttribPointer( atPos, 3, WebGLRenderingContext.FLOAT, false, 0, 0 );
    //gl.enableVertexAttribArray( atPos );
    
    mesh.Elem elem = new mesh.Elem( buffer, WebGLRenderingContext.FLOAT, false, 3, 0, 0 );
    mesh.Mesh me = new mesh.Mesh();
    me.nVert = 3;
    me.elements['a_position'] = elem;
    
    // draw  scene
    gl.clear( WebGLRenderingContext.COLOR_BUFFER_BIT | WebGLRenderingContext.DEPTH_BUFFER_BIT );
    //gl.useProgram( effect.handle );
    //gl.drawArrays( WebGLRenderingContext.TRIANGLES, 0, 3 );
    me.draw( gl, effect );
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