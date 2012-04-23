#import('unittest.dart',		prefix:'unit');
#import('dart:html',			prefix:'dom');
#import('../proj/buff.dart',	prefix:'buff');
#import('../proj/cap.dart',		prefix:'cap');
#import('../proj/frame.dart',	prefix:'frame');
#import('../proj/load.dart',	prefix:'load');
#import('../proj/math.dart',	prefix:'math');
#import('../proj/mesh.dart',	prefix:'mesh');
#import('../proj/parse.dart',	prefix:'parse');
#import('../proj/rast.dart',	prefix:'rast');
#import('../proj/ren.dart',		prefix:'ren');
#import('../proj/shade.dart',	prefix:'shade');


void main()	{
	unit.group('Math:', (){
		final double scalar = 2.5;
		final math.Vector vector = new math.Vector(1.0,2.0,3.0,0.1);
		final math.Quaternion quat = new math.Quaternion.fromAxis(vector,10.0).normalize();

		unit.test('Vector operators', (){
			math.Vector rez = vector*(new math.Vector.one()) + new math.Vector.zero();
			Expect.isTrue( rez.isEqual(vector) );
			double val = new math.Vector.unitX().dot(new math.Vector.unitY());
			Expect.isTrue( math.isScalarZero( val ));
			val = vector.length()*scalar - vector.scale(scalar).length();
			Expect.isTrue( math.isScalarZero( val ));
			rez = new math.Vector.unitX();
			Expect.isTrue( rez.normalize().isEqual(rez) );
		});
		unit.test('Matrix identity', (){
			math.Matrix mx = new math.Matrix.identity();
			Expect.isTrue( mx.isAffine() && mx.isOrthogonal() && mx.isOrthonormal() );
			Expect.isTrue( mx.inverse().isEqual(mx) );
		});
		unit.test('Quaternion interpolation', (){
			math.Quaternion qid = new math.Quaternion.identity();
			Expect.isTrue( quat.isEqual(qid*quat) && quat.isEqual(quat*qid) );
			Expect.isTrue( math.Quaternion.slerp(quat,quat,0.3).isEqual(quat) );
			Expect.isTrue( math.Quaternion.lerp(quat,quat,0.7).isEqual(quat) );
		});
		unit.test('Matrix and Quaternion', (){
			math.Vector vz = new math.Vector.zero();
			math.Matrix mx = new math.Matrix.fromQuat( quat, 1.0, vz );
			math.Vector v2 = vector.setW(0.0);
			Expect.isTrue( quat.rotate(v2).isEqual(mx.transform(v2)) );
			math.Quaternion q2 = new math.Quaternion.fromAxis(vector.inverse3(),0.1).normalize();
			math.Matrix m2 = new math.Matrix.fromQuat( q2, 1.0, vz );
			math.Matrix mult = new math.Matrix.fromQuat( quat * q2, 1.0, vz );
			Expect.isTrue( mult.isEqual(mx*m2) );
		});
	});
	unit.group('Render:', (){
		final dom.CanvasElement canvas = dom.document.query('#canvas');
		final dom.WebGLRenderingContext gl = canvas.getContext('experimental-webgl');
		
		final ren.EntityBase entity = new ren.EntityBase();
		entity.state = new parse.Build().setDepth('<=').end();
		final frame.Rect rect = new frame.Rect( 0, 0, canvas.width, canvas.height );
		
		unit.test('Capabilities', (){
			new cap.System(gl);
		});
 		
  		unit.test('Vertex buffer', (){
			final buff.Binding bufBuilder = new buff.Binding.array(gl);
  			final math.Vector position = new math.Vector.zero();
	  		final buff.Unit buffer = bufBuilder.spawn( buff.toFloat32(position.toList()) );
  			entity.mesh = new mesh.Mesh(null);
  			entity.mesh.init('1',1,0);
  			entity.mesh.elements['a_pos'] = new mesh.Element.float32(3,buffer,0,0);
  		});
		
		unit.test('Shader link', (){
			final String textVert = 'attribute vec3 a_pos; void main() {gl_Position=vec4(a_pos,1.0);}';
			final String textFrag = 'void main() {gl_FragColor=vec4(1.0);}';
	  		entity.shader = new shade.Effect(gl, [
  				new shade.Unit.vertex(gl,textVert),
  				new shade.Unit.fragment(gl,textFrag)
  				]);
  		});

		unit.test('Render', (){
   			final ren.Target target = new ren.Target( new frame.Buffer.main(), rect, 0.0, 1.0 );
	   		final ren.Process process = new ren.Process(false);
		   	process.clear( target.buffer,
		   		new frame.Color(0.0,0.0,0.0,0.0), 1.0, null,
		   		null, entity.state.mask );
	   		process.draw( target, entity );
	   		process.flush( gl );
	   	});
	   	
	   	unit.test('Read back', (){
		   	final frame.Control control = new frame.Control(gl);
	   		final dom.Uint8Array result = control.readUint8( rect, 'rgba' );
	   		for (int x in result)
	   			Expect.isTrue( x==0xFF );
	   	});
	});
	unit.group('XML:', (){
		final dom.DOMParser parser = new dom.DOMParser();
		String text = '';
		unit.test('Load', (){
			text = new load.Loader('schema/').getNow('test.xml');
			Expect.isTrue( text!=null && text!='' );
		});
		unit.test('Parse', (){
			final dom.Document doc = parser.parseFromString(text,'text/xml');
			final rast.State state = new parse.Parse().rast( doc.documentElement );
			print( "${state}" );
		});
	});
}
