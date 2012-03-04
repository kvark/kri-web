#import('dart:html',  prefix:'dom');
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
  dom.CanvasElement canvas = null;
  int timerHandle = -1;
  int canvasOffX = 0, canvasOffY = 0;
  static final localOnly = false;
 
  App();
  
  void run() {
    final dom.Console log = dom.window.console;
    canvas = dom.document.query('#canvas');
    gl = canvas.getContext('experimental-webgl');
    canvas.rect.then((final dom.ElementRect rect)	{
    	canvasOffX = rect.offset.left;
    	canvasOffY = rect.offset.top;
    });
    
    log.debug(gl);
    
    gl.enable( dom.WebGLRenderingContext.DEPTH_TEST );
    gl.enable( dom.WebGLRenderingContext.CULL_FACE );
    gl.frontFace( dom.WebGLRenderingContext.CW );
    gl.depthMask(true);
    
    String vertText, fragText;
    
    if (localOnly)	{
    	vertText = 'attribute vec3 a_position; uniform mat4 mx_mvp; ' +
			'void main() {gl_Position=mx_mvp*vec4(a_position,1.0);}';
		fragText = 'void main() {gl_FragColor=vec4(1.0);}';
    }else	{
	    final load.Loader loader = new load.Loader('http://demo.kvatom.com/');
    	vertText = loader.getNow('shade/simple.glslv');
	    fragText = loader.getNow('shade/simple.glslf');
    }
    
    shade.Unit shVert = new shade.Unit.vertex( gl, vertText );
    shade.Unit shFrag = new shade.Unit.fragment( gl, fragText );
    shade.Effect effect = new shade.Effect( gl, [shVert,shFrag] );
    
    me = new gen.Mesh(gl).cubeUnit();
    tex.Texture texture = new gen.Texture(gl).white();

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
	
    if (!localOnly)	{
    	final tex.Manager texLoader = new tex.Manager( gl, 'http://demo.kvatom.com/image/' );
    	texture = texLoader.load( 'CAR.TGA', texture );
    	final tex.Binding texBind = new tex.Binding.tex2d(gl);
    	texBind.state( texture, false, false, 0 );
    	//log.debug( texture );
    	final mesh.Manager meLoader = new mesh.Manager( gl, 'http://demo.kvatom.com/mesh/' );
    	me = meLoader.load( 'cube.k3mesh', me );
    }
    
    shader = new shade.Instance( effect );
    shader.dataSources.add( data );
    shader.parameters['u_color'] = new math.Vector(1.0,0.0,0.0,1.0);
    shader.parameters['pos_light'] = new math.Vector(1.0,2.0,-3.0,1.0);
    shader.parameters['t_main'] = texture;
    me.draw( gl, shader );
    //log.debug( shader );
    
    int err = gl.getError();
    if(err!=0)
      log.debug("Error: $err");
    
    timerHandle = dom.window.setInterval(frame, 20);
    dom.window.on.mouseMove.add( mouseMove );
    dom.window.on.mouseDown.add( mouseDown );
    dom.window.on.mouseUp.add( mouseUp );
  }
  
  int gripX, gripY;
  math.Quaternion gripBase = null;
  
  void mouseMove( final dom.MouseEvent e ){
  	// move light
    final view.DataSource data = shader.dataSources[0];
    final double dist = data.modelNode.getWorld().position.z;
  	final double hx = canvas.width.toDouble() * 0.5;
  	final double hy = canvas.height.toDouble()* 0.5;
  	final math.Vector v = new math.Vector(
  		((e.clientX-canvasOffX).toDouble() - hx) / (hx/dist),
  		(hy - (e.clientY-canvasOffY).toDouble())  / (hy/dist),
  		0.0, 1.0 );
  	shader.parameters['pos_light'] = v;
  	// move object
  	if (gripBase != null && (e.clientX!=gripX || e.clientY!=gripY))	{
  		final math.Vector voff = new math.Vector(
  			(gripX-e.clientX).toDouble(),
  			(e.clientY-gripY).toDouble(),
  			0.0, 0.0 );
  		final math.Vector axis = voff.normalize().cross(new math.Vector.unitZ());
		final double angle = voff.length();
		data.modelNode.space = new space.Space( data.modelNode.space.position,
	    	  gripBase * new math.Quaternion.fromAxis(axis,angle), 1.0 );
  	}
  }
  
  void mouseDown( final dom.MouseEvent e ){
  	gripX = e.clientX; gripY = e.clientY;
    final view.DataSource data = shader.dataSources[0];
  	gripBase = data.modelNode.space.orientation;
  }
  
  void mouseUp( final dom.MouseEvent e ){
  	gripBase = null;
  }
  
  void frame()	{
  	final Date dateNow = new Date.now();
  	double time = dateNow.value.toDouble() / 10.0;
	final frame.Control con = new frame.Control(gl);
    con.clear( new frame.Color(0.0,0.5,1.0,1.0), 1.0, null );
    //final view.DataSource data = shader.dataSources[0];
    //data.modelNode.space = new space.Space( data.modelNode.space.position,
    //  new math.Quaternion.fromAxis(new math.Vector.unitY(),time), 1.0 );
    me.draw( gl, shader );
  }
}


void main() {
  new App().run();
}
