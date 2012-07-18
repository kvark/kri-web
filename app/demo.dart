#import('dart:html',	prefix:'dom');
#import('../proj/ani.dart',		prefix:'ani');
#import('../proj/arm.dart',		prefix:'arm');
#import('../proj/buff.dart',	prefix:'buff');
#import('../proj/cap.dart',		prefix:'cap');
#import('../proj/draw.dart',	prefix:'draw');
#import('../proj/frame.dart',	prefix:'frame');
#import('../proj/gen.dart',		prefix:'gen');
#import('../proj/load.dart',	prefix:'load');
#import('../proj/math.dart',	prefix:'math');
#import('../proj/mesh.dart',	prefix:'mesh');
#import('../proj/parse.dart',	prefix:'parse');
#import('../proj/rast.dart',	prefix:'rast');
#import('../proj/ren.dart',		prefix:'ren');
#import('../proj/shade.dart',	prefix:'shade');
#import('../proj/space.dart',	prefix:'space');
#import('../proj/tex.dart',		prefix:'tex');
#import('../proj/view.dart',	prefix:'view');


class App {
	dom.WebGLRenderingContext gl = null;
	dom.CanvasElement canvas = null;
	space.Node controlNode = null;
	arm.Armature skeleton = null;
	int timerHandle = -1;
	int canvasOffX = 0, canvasOffY = 0;
	static final localOnly = false;
	
	mesh.Mesh axisMesh = null;
	shade.Effect axisShader = null;
	
	final draw.EntityBase entityBase;
	draw.Entity entity = null;
	final draw.Technique tech;
	
	final ren.Process process;
 	
 	App():
		entityBase = new draw.EntityBase(),
		tech = new draw.Technique(),
		process = new ren.Process(true)
	{
		entityBase.state = new parse.Build().setDepth('<=').end();
	}
  
  	void run() {
  		//if (!dom.window.WebGLRenderingContext) {
	    	// the browser doesn't even know what WebGL is
		//	dom.window.location = 'http://get.webgl.org';
		//	return;
		//}
		canvas = dom.document.query('#canvas');
		gl = canvas.getContext('webgl');
		if (gl==null) {
			print('Normal WebGL not detected. Trying experimental...');
			gl = canvas.getContext('experimental-webgl');
		}
		if (gl==null)	{
			print('Unable to get WebGL context.');
			dom.window.location = 'http://get.webgl.org/troubleshooting';
			return;
		}

		canvas.rect.then((final dom.ElementRect rect)	{
			canvasOffX = rect.offset.left;
			canvasOffY = rect.offset.top;
		});
		
		print( new cap.System(gl) );
		
		entityBase.mesh = new gen.Mesh(gl).cubeUnit();
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
		controlNode = node;
		
		if (!localOnly)	{
			final String home = '';
			final tex.Manager texLoader = new tex.Manager( gl, "${home}/image" );
			//texture = texLoader.load( 'CAR.TGA', texture );
			texture = texLoader.load( 'SexyFem_Texture.tga', texture );
			final tex.Binding texBind = new tex.Binding2D(gl);
			texBind.state( texture, false, false, 0 );
			//log.debug( texture );
			final mesh.Manager meLoader = new mesh.Manager( gl, "${home}/mesh" );
			//me = meLoader.load( 'cube.k3mesh', me );
			entityBase.mesh = meLoader.load( 'jazz_dancing.k3mesh', entityBase.mesh );
			final arm.Manager arLoader = new arm.Manager( "${home}/arm" );
			//skeleton = arLoader.load( 'cube.k3arm', null );
			skeleton = arLoader.load( 'jazz_dancing.k3arm', skeleton );
			final shade.Manager shMan = new shade.Manager( gl, "${home}/shade");
			entityBase.effect = shMan.assemble( ['simple-arm.glslv','simple.glslf'] );
			//entityBase.shader = shMan.assemble( ['simple.glslv','simple.glslf'] );
		}else	{
			String vertText = 'attribute vec3 a_position; uniform mat4 mx_mvp; ' +
				'void main() {gl_Position=mx_mvp*vec4(a_position,1.0);}';
			String fragText = 'void main() {gl_FragColor=vec4(1.0);}';
			shade.Unit shVert = new shade.Unit.vertex( gl, vertText );
			shade.Unit shFrag = new shade.Unit.fragment( gl, fragText );
			entityBase.effect = new shade.Effect( gl, [shVert,shFrag] );
		}
		
		entityBase.data['u_Color'] = new math.Vector(1.0,0.0,0.0,1.0);
		entityBase.data['u_PosLight'] = new math.Vector(1.0,2.0,-3.0,1.0);
		entityBase.data['t_Main'] = texture;
		//log.debug( shader );

		if (true)	{		
			final draw.Material mat = new draw.Material('test');
			mat.data['u_PosLight'] = new math.Vector(1.0,2.0,-3.0,1.0);
			mat.data['t_Main'] = texture;
			mat.metas.add('getFinalColor');

			final load.Loader ld = new load.Loader('/shade');
			//ld.getFutureText('mat/phong.glslv').then((text) { mat.codeVertex=text; });
			//ld.getFutureText('mat/phong.glslf').then((text) { mat.codeFragment=text; });
			//ld.getFutureText('tech/main.glslv').then((text) { tech.baseVertex=text; });
			//ld.getFutureText('tech/main.glslf').then((text) { tech.baseFragment=text; });
			
			mat.codeVertex		= ld.getNowText('mat/phong.glslv');
			mat.codeFragment	= ld.getNowText('mat/phong.glslf');
			
			String sv = ld.getNowText('tech/main.glslv');
			String sf = ld.getNowText('tech/main.glslf');
			tech.setShaders(sv,sf);

			final ren.Target target = new ren.Target( new frame.Buffer.main(), rect, 0.0, 1.0 );
			tech.setTargetState( camera, target, entityBase.state );
			skeleton.loadShaders( ld, true, false );

			entity = new draw.Entity( entityBase.mesh, mat, null );
			entity.node = child;
			entity.modifiers.add( skeleton );
		}
		
		/* rudimentary direct access routines
		gl.enable( dom.WebGLRenderingContext.DEPTH_TEST );
		gl.enable( dom.WebGLRenderingContext.CULL_FACE );
		gl.depthMask(true);
		con.clear( new frame.Color(0.0,0.5,1.0,1.0), 1.0, null );
		me.draw( gl, shader, block );*/
		
		int err = gl.getError();
		if(err!=0)
		  print("Error: ${err}");
		
		timerHandle = dom.window.setInterval(onFrame, 20);
		dom.window.on.mouseMove.add( onMouseMove );
		dom.window.on.mouseDown.add( onMouseDown );
		dom.window.on.mouseUp.add( onMouseUp );
	}
  
  int gripX, gripY;
  math.Quaternion gripBase = null;
  
  void onMouseMove( final dom.MouseEvent e ){
  	// move light
    final double dist = 5.0; //controlNode.getWorld().position.z;
  	final double hx = canvas.width.toDouble() * 0.5;
  	final double hy = canvas.height.toDouble()* 0.5;
  	final math.Vector v = new math.Vector(
  		((e.clientX-canvasOffX).toDouble() - hx) / (hx/dist),
  		(hy - (e.clientY-canvasOffY).toDouble())  / (hy/dist),
  		0.0, 1.0 );
  	entityBase.data['pos_light'] = v;
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
		//viewData.fillData( entity.data );
  	}
  }
  
  void onMouseDown( final dom.MouseEvent e ){
  	gripX = e.clientX; gripY = e.clientY;
  	gripBase = controlNode.space.rotation;
  }
  
  void onMouseUp( final dom.MouseEvent e ){
  	gripBase = null;
  }
  
  void onFrame()	{
  	final Date dateNow = new Date.now();
  	double time = dateNow.millisecondsSinceEpoch.toDouble() / 1000.0;

    if (skeleton!=null)	{
    	for(final String aniName in skeleton.records.getKeys())	{
    		final ani.Record rec = skeleton.records[aniName];
    		double t1 = time - (time/rec.length).floor() * rec.length;
    		skeleton.setMoment( aniName, t1 );
    		break;
    	}
    	skeleton.update();
    	skeleton.fillData( entityBase.data );
    }
    //final view.DataSource data = shader.dataSources[0];
    //data.modelNode.space = new space.Space( data.modelNode.space.position,
    //  new math.Quaternion.fromAxis(new math.Vector.unitY(),time), 1.0 );
   	//controlNode.space.rotation = new math.Quaternion.fromAxis(new math.Vector(1.0,0.0,0.0,0.0),time);
   	//controlNode.space.movement = new math.Vector(0.0,Math.sin(time*0.01),5.0,0.0);
   	//me.draw( gl, shader, block );
   	
   	if (gl.isContextLost())
   		return;

   	final rast.Mask mask = new rast.Mask.all();
   	process.clear( tech.getTarget().buffer,
   		new frame.Color(0.0,0.0,0.0,0.0), 1.0, null,
   		null, mask );
   	
   	if (0)	{
   		process.draw( tech.getTarget(), entityBase.mesh,
   			entityBase.effect, entityBase.state, entityBase );
   	}else	{
   		final shade.LinkHelp help = new shade.LinkHelp(gl);
   		tech.draw( help, [entity], process );
   	}

   	process.flush( gl );
  }
}


void main() {
    new App().run();
}
