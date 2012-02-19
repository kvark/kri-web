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
#import('tex.dart',   prefix:'tex');


class App {
  mesh.Mesh me = null;
  shade.Instance shader = null;
  dom.WebGLRenderingContext gl = null;
 
  App();
  
  void run() {
    final dom.Console log = dom.window.console;
    final dom.HTMLCanvasElement canvas = dom.document.getElementById('canvas');
    gl = canvas.getContext('experimental-webgl');
    
    gl.enable( dom.WebGLRenderingContext.DEPTH_TEST );
    gl.enable( dom.WebGLRenderingContext.CULL_FACE );
    gl.depthMask(true);
    
    final load.Loader loader = new load.Loader('http://demo.kvatom.com/');
    final String vertText = loader.getNow('shade/simple.glslv');
    final String fragText = loader.getNow('shade/simple.glslf');
    
    /*final String vertText = 'attribute vec3 a_position; uniform mat4 mx_mvp; ' +
 	   'void main() {gl_Position=mx_mvp*vec4(a_position,1.0);}';
    final String fragText = 'uniform lowp vec4 color; void main() {gl_FragColor=color;}';*/
    
    shade.Unit shVert = new shade.Unit.vertex( gl, vertText );
    shade.Unit shFrag = new shade.Unit.fragment( gl, fragText );
    shade.Effect effect = new shade.Effect( gl, [shVert,shFrag] );
    
    me = new gen.Mesh(gl).cubeUnit();

    // draw  scene
    final frame.Control con = new frame.Control(gl);
    con.clear( new frame.Color(0.0,0.5,1.0,1.0), 1.0, null );
    final frame.Rect rect = new frame.Rect( 0, 0, canvas.width, canvas.height );
    con.viewport( rect );
    
    final view.Camera camera = new view.Camera();
    camera.projector = new view.Projector.perspective( 60.0, rect.aspect(), 1.0, 10.0 );
    final space.Node node = new space.Node( 'model-node' );
    node.space = new space.Space.fromMoveScale( 0.0,0.0,5.0, 1.0 );
    final view.DataSource data = new view.DataSource( node, camera );

    final tex.Manager texLoader = new tex.Manager( gl, 'http://demo.kvatom.com/image/' );
    final tex.Texture texWhite = new gen.Texture(gl).white();
    final tex.Texture carTexture = texLoader.load( 'CAR.TGA', texWhite );
    final tex.Binding texBind = new tex.Binding.tex2d(gl);
    texBind.state( carTexture, false, false, 0 );
    log.debug( carTexture );
    
    shader = new shade.Instance( effect );
    shader.dataSources.add( data );
    shader.parameters['u_color'] = new math.Vector(1.0,0.0,0.0,1.0);
    shader.parameters['t_main'] = carTexture;
    me.draw( gl, shader );
    log.debug( shader );
    
    int err = gl.getError();
    if(err!=0)
      log.debug("Error: $err");
    
    dom.window.setInterval(frame, 20);
  }
  
  void frame()	{
  	final Date date = new Date.now();
  	double time = date.value.toDouble() / 1000.0;
	final frame.Control con = new frame.Control(gl);
    con.clear( new frame.Color(0.0,0.5,1.0,1.0), 1.0, null );
    final view.DataSource data = shader.dataSources[0];
    data.modelNode.space = new space.Space( data.modelNode.space.position,
      new math.Quaternion.fromAxis(new math.Vector.unitY(),time), 1.0 );
    me.draw( gl, shader );
  }
}


void main() {
  new App().run();
}
