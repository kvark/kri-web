#import('dart:dom');
#import('shade.dart', prefix:'shade');
#import('buff.dart',  prefix:'buff');
#import('mesh.dart',  prefix:'mesh');
#import('math.dart',  prefix:'math');
#import('space.dart', prefix:'space');
#import('frame.dart', prefix:'frame');



class test {
 
  test();
  
  void run() {
    final Console log = window.console;
    final HTMLCanvasElement canvas = document.getElementById('canvas');
    final WebGLRenderingContext gl = canvas.getContext('experimental-webgl');
    
    gl.viewport( 0, 0, canvas.width, canvas.height );
    gl.enable( WebGLRenderingContext.DEPTH_TEST );
    
    final String vertText = 'attribute vec3 a_position; void main() {gl_Position=vec4(a_position,1.0);}';
    shade.Unit shVert = new shade.Unit.vertex( gl, vertText );
    final String fragText = 'uniform lowp vec4 color; void main() {gl_FragColor=color;}';
    shade.Unit shFrag = new shade.Unit.fragment( gl, fragText );
    shade.Effect effect = new shade.Effect( gl, [shVert,shFrag] );
    log.debug( 'vert: ' + shVert.getLog() );
    log.debug( 'frag: ' + shFrag.getLog() );
    log.debug( 'prog: ' + (effect.isReady() ? 'Ok' : effect.getLog()) );
    
    List<double> vertices = [
                    0.0,  1.0,  0.0,
                   -1.0, -1.0,  0.0,
                    1.0, -1.0,  0.0
               ];
    final Float32Array vData = new Float32Array.fromList(vertices);
    List<int> indices = [0,1,2];
    final Int16Array iData = new Int16Array.fromList(indices);
    
    buff.Unit vBuffer = new buff.Binding.array(gl).spawn( vData );
    buff.Unit vIndex  = new buff.Binding.index(gl).spawn( iData );

    mesh.Elem vElem = new mesh.Elem.float32( 3, vBuffer,0,0 );
    mesh.Elem iElem = new mesh.Elem.index16( vIndex,0 );
    mesh.Mesh me = new mesh.Mesh();
    me.nVert = 3;
    me.nInd = 3;
    me.elements['a_position'] = vElem;
    me.indices = iElem;

    // draw  scene
    frame.Buffer fb = new frame.Buffer(gl);
    frame.Control con = new frame.Control(gl);
    con.clearScreen( new frame.Color(0.0,0.5,1.0,1.0), 1.0, null );
    
    shade.Instance shader = new shade.Instance(effect);
    shader.parameters['color'] = new Float32Array.fromList([1.0,0.0,0.0,1.0]);
    me.draw( gl, shader );
    
    int err = gl.getError();
    if(err!=0)
      log.debug("Error: $err");
  }
}


void main() {
  new test().run();
}