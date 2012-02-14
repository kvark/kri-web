#import('dart:dom',   prefix:'dom');
#import('shade.dart', prefix:'shade');
#import('buff.dart',  prefix:'buff');
#import('mesh.dart',  prefix:'mesh');
#import('math.dart',  prefix:'math');
#import('space.dart', prefix:'space');
#import('frame.dart', prefix:'frame');
#import('view.dart',  prefix:'view');
#import('load.dart',  prefix:'load');
#import('gen.dart',	  prefix:'gen');


class App {
  mesh.Mesh me = null;
  shade.Instance shader = null;
  dom.WebGLRenderingContext gl = null;
 
  App();
  
  void run() {
    dom.Console log = dom.window.console;
    dom.HTMLCanvasElement canvas = dom.document.getElementById('canvas');
    gl = canvas.getContext('experimental-webgl');
    
    gl.disable( dom.WebGLRenderingContext.DEPTH_TEST );
    gl.disable( dom.WebGLRenderingContext.CULL_FACE );
    
    final String vertText = 'attribute vec3 a_position; uniform mat4 mx_mvp; ' +
 	   'void main() {gl_Position=mx_mvp*vec4(a_position,1.0);}';
    shade.Unit shVert = new shade.Unit.vertex( gl, vertText );
    final String fragText = 'uniform lowp vec4 color; void main() {gl_FragColor=color;}';
    shade.Unit shFrag = new shade.Unit.fragment( gl, fragText );
    shade.Effect effect = new shade.Effect( gl, [shVert,shFrag] );
    log.debug( 'vert: ' + shVert.getLog() );
    log.debug( 'frag: ' + shFrag.getLog() );
    log.debug( 'prog: ' + (effect.isReady() ? 'Ok' : effect.getLog()) );
    
    me = new gen.Generator(gl).cubeUnit();

    // draw  scene
    final con = new frame.Control(gl);
    con.clear( new frame.Color(0.0,0.5,1.0,1.0), 1.0, null );
    final rect = new frame.Rect( 0, 0, canvas.width, canvas.height );
    con.viewport( rect );
    
    final camera = new view.Camera();
    camera.projector = new view.Projector.perspective( 60.0, rect.aspect(), 1.0, 10.0 );
    final node = new space.Node( 'camNode' );
    node.space = new space.Space.fromMoveScale( 0.0,0.0,5.0, 1.0 );
    final data = new view.DataSource( node, camera );
    
    shader = new shade.Instance( effect );
    shader.dataSources.add( data );
    shader.parameters['color'] = new math.Vector(1.0,0.0,0.0,1.0);
    me.draw( gl, shader );
    
    int err = gl.getError();
    if(err!=0)
      log.debug("Error: $err");
    
    dom.window.setTimeout((){drawTime(0.0);}, 100);
    
    //final loader = new load.Loader(''); 
    //final binary = loader.getNow('sample.bin');
    //log.debug("Loaded: " + binary);
  }
  
  void drawTime(double time)	{
	final con = new frame.Control(gl);
    con.clear( new frame.Color(0.0,0.5,1.0,1.0), 1.0, null );
    final data = shader.dataSources[0];
    data.modelNode.space = new space.Space( data.modelNode.space.position,
      new math.Quaternion.fromAxis(new math.Vector.unitY(),time), 1.0 );
    //data.modelNode.space = new space.Space.fromMoveScale( Math.sin(2.0*time), Math.cos(2.0*time), 5.0, 1.0 );
    me.draw( gl, shader );
    dom.window.setTimeout(() { drawTime(time+0.02); }, 20);
  }
}


void main() {
  new App().run();
}
