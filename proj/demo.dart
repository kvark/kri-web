#import('dart:html',	prefix:'dom');
#import('shade.dart',	prefix:'shade');
#import('buff.dart',	prefix:'buff');
#import('mesh.dart',	prefix:'mesh');
#import('math.dart',	prefix:'math');
#import('space.dart',	prefix:'space');
#import('frame.dart',	prefix:'frame');
#import('view.dart',	prefix:'view');
#import('load.dart',	prefix:'load');
#import('gen.dart',		prefix:'gen');
#import('tex.dart',		prefix:'tex');
#import('arm.dart',		prefix:'arm');
#import('ani.dart',		prefix:'ani');
#import('ren.dart',		prefix:'ren');


class App {
  view.DataSource viewData = null;
  dom.WebGLRenderingContext gl = null;
  dom.CanvasElement canvas = null;
  space.Node controlNode = null;
  arm.Armature skeleton = null;
  int timerHandle = -1;
  int canvasOffX = 0, canvasOffY = 0;
  static final localOnly = false;
  
  mesh.Mesh axisMesh = null;
  shade.Effect axisShader = null;
  
  final ren.EntityBase entity;
  final ren.Process process;
 
  App():
  	entity = new ren.EntityBase(),
  	process = new ren.Process(true)
  {
  	entity.state = new ren.Build().depth('<=').end();
  }
  
  void run() {
    final dom.Console log = dom.window.console;
    canvas = dom.document.query('#canvas');
    gl = canvas.getContext('experimental-webgl');
    canvas.rect.then((final dom.ElementRect rect)	{
    	canvasOffX = rect.offset.left;
    	canvasOffY = rect.offset.top;
    });
    
    log.debug(gl);

    entity.mesh = new gen.Mesh(gl).cubeUnit();
    tex.Texture texture = new gen.Texture(gl).white();

    final view.Camera camera = new view.Camera();
    final frame.Rect rect = new frame.Rect( 0, 0, canvas.width, canvas.height );
    camera.projector = new view.Projector.perspective( 60.0, rect.aspect(), 1.0, 10.0 );
    final space.Node node = new space.Node( 'model-node' );
		node.space = new space.Space.fromMoveScale(0.0,0.0,-5.0,1.0);    	
    final space.Node child = new space.Node('child');
    child.parent = node;
    child.space = new space.Space(
    	new math.Vector(0.0,2.0,0.0,0.0),
    	new math.Quaternion.fromAxis(new math.Vector.unitY(),180.0) *
    	new math.Quaternion.fromAxis(new math.Vector.unitX(),90.0),
    	2.0 );
    //child.space = new space.Space.identity();
    viewData = new view.DataSource( child, camera );
    viewData.fillData( entity.data );
    controlNode = node;
	
    if (!localOnly)	{
    	final String home = '';
    	final tex.Manager texLoader = new tex.Manager( gl, "${home}/image/" );
    	//texture = texLoader.load( 'CAR.TGA', texture );
    	texture = texLoader.load( 'SexyFem_Texture.tga', texture );
    	final tex.Binding texBind = new tex.Binding.tex2d(gl);
    	texBind.state( texture, false, false, 0 );
    	//log.debug( texture );
    	final mesh.Manager meLoader = new mesh.Manager( gl, "${home}/mesh/" );
    	//me = meLoader.load( 'cube.k3mesh', me );
    	entity.mesh = meLoader.load( 'jazz_dancing.k3mesh', entity.mesh );
    	final arm.Manager arLoader = new arm.Manager( "${home}/arm/" );
    	//skeleton = arLoader.load( 'cube.k3arm', null );
    	skeleton = arLoader.load( 'jazz_dancing.k3arm', skeleton );
	    final shade.Manager shMan = new shade.Manager( "${home}/shade/");
	    entity.shader = shMan.assemble( gl, ['simple-arm.glslv','simple.glslf'] );
	    //entity.shader = shMan.assemble( gl, ['simple.glslv','simple.glslf'] );
    }else	{
    	String vertText = 'attribute vec3 a_position; uniform mat4 mx_mvp; ' +
			'void main() {gl_Position=mx_mvp*vec4(a_position,1.0);}';
		String fragText = 'void main() {gl_FragColor=vec4(1.0);}';
		shade.Unit shVert = new shade.Unit.vertex( gl, vertText );
	    shade.Unit shFrag = new shade.Unit.fragment( gl, fragText );
    	entity.shader = new shade.Effect( gl, [shVert,shFrag] );
    }

    entity.data['u_color'] = new math.Vector(1.0,0.0,0.0,1.0);
    entity.data['pos_light'] = new math.Vector(1.0,2.0,-3.0,1.0);
    entity.data['t_main'] = texture;
    //log.debug( shader );
    
	/* rudimentary direct access routines
	gl.enable( dom.WebGLRenderingContext.DEPTH_TEST );
    gl.enable( dom.WebGLRenderingContext.CULL_FACE );
    gl.depthMask(true);
    con.clear( new frame.Color(0.0,0.5,1.0,1.0), 1.0, null );
    me.draw( gl, shader, block );*/
    
    int err = gl.getError();
    if(err!=0)
      print("Error: ${err}");
    
    timerHandle = dom.window.setInterval(frame, 20);
    dom.window.on.mouseMove.add( mouseMove );
    dom.window.on.mouseDown.add( mouseDown );
    dom.window.on.mouseUp.add( mouseUp );
  }
  
  int gripX, gripY;
  math.Quaternion gripBase = null;
  
  void mouseMove( final dom.MouseEvent e ){
  	// move light
    final double dist = 5.0; //controlNode.getWorld().position.z;
  	final double hx = canvas.width.toDouble() * 0.5;
  	final double hy = canvas.height.toDouble()* 0.5;
  	final math.Vector v = new math.Vector(
  		((e.clientX-canvasOffX).toDouble() - hx) / (hx/dist),
  		(hy - (e.clientY-canvasOffY).toDouble())  / (hy/dist),
  		0.0, 1.0 );
  	entity.data['pos_light'] = v;
  	// move object
  	if (controlNode!=null && gripBase != null && (e.clientX!=gripX || e.clientY!=gripY))	{
  		final math.Vector voff = new math.Vector(
  			(e.clientX-gripX).toDouble(),
  			(gripY-e.clientY).toDouble(),
  			0.0,0.0);
  		final math.Vector axis = voff.normalize().cross(new math.Vector.unitZ());
  		final double angle = voff.length();
  		math.Quaternion rot = new math.Quaternion.fromAxis(axis,angle);
  		if (controlNode.parent!=null)	{
  			final math.Quaternion wq = controlNode.parent.getWorld().rotation;
  			rot = wq.inverse() * rot * wq;
		}			
		controlNode.space = new space.Space( controlNode.space.movement,
	    	  rot * gripBase, controlNode.space.scale );
		viewData.fillData( entity.data );
  	}
  }
  
  void mouseDown( final dom.MouseEvent e ){
  	gripX = e.clientX; gripY = e.clientY;
  	gripBase = controlNode.space.rotation;
  }
  
  void mouseUp( final dom.MouseEvent e ){
  	gripBase = null;
  }
  
  void frame()	{
  	final Date dateNow = new Date.now();
  	double time = dateNow.value.toDouble() / 1000.0;

    if (skeleton!=null)	{
    	final String aniName = /*'samba_dancing_2'*/ 'DefaultAction.002';
    	final ani.Record rec = skeleton.records[aniName];
    	if (rec != null)	{
    		double t1 = time - (time/rec.length).floor() * rec.length;
    		skeleton.setMoment( aniName, t1 );
    	}
    	skeleton.update();
    	skeleton.fillData( entity.data );
    }
    //final view.DataSource data = shader.dataSources[0];
    //data.modelNode.space = new space.Space( data.modelNode.space.position,
    //  new math.Quaternion.fromAxis(new math.Vector.unitY(),time), 1.0 );
   	//controlNode.space.rotation = new math.Quaternion.fromAxis(new math.Vector(1.0,0.0,0.0,0.0),time);
   	//controlNode.space.movement = new math.Vector(0.0,Math.sin(time*0.01),5.0,0.0);
   	//me.draw( gl, shader, block );

    final frame.Rect rect = new frame.Rect( 0, 0, canvas.width, canvas.height );
   	final ren.PixelMask mask = new ren.PixelMask.all();
   	final ren.Target target = new ren.Target( new frame.Buffer.main(), rect, 0.0, 1.0 );
   	process.clear( null, mask, target, new frame.Color(0.0,0.0,0.0,0.0), 1.0, null );
   	process.draw( entity, target );
   	process.flush( gl );
  }
}


void main() {
  new App().run();
}
