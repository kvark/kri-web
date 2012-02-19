#library('gen');
#import('core.dart', prefix:'core');
#import('math.dart', prefix:'math');
#import('mesh.dart', prefix:'mesh');
#import('buff.dart', prefix:'buff');
#import('help.dart', prefix:'help');
#import('tex.dart',  prefix:'tex');


class Mesh	{
  final buff.Binding bArr, bInd;

  Mesh(gl):
  	bArr = new buff.Binding.array(gl),
  	bInd = new buff.Binding.index(gl);

  mesh.Mesh cube(final math.Vector size) {
  	final vertices = [
  	 -size.x,-size.y,-size.z,
  	  size.x,-size.y,-size.z,
  	 -size.x, size.y,-size.z,
  	  size.x, size.y,-size.z,
  	 -size.x,-size.y, size.z,
  	  size.x,-size.y, size.z,
  	 -size.x, size.y, size.z,
  	  size.x, size.y, size.z
  	];
  	final normals = [
      0.0,-1.0, 0.0,
  	  0.0, 0.0, 1.0,
  	  0.0, 1.0, 0.0,
  	  0.0, 0.0,-1.0,
  	 -1.0, 0.0, 0.0,
  	  1.0, 0.0, 0.0
  	];
  	final texCoords = [
  	  0.0, 0.0,
  	  1.0, 0.0,
  	  0.0, 1.0,
  	  1.0, 1.0
  	];
  	final order = [
  	  //0,1,4,5,7,1,3,0,2,4,6,7,2,3	// tri-strip indices
  	  0,4,5,1, 4,6,7,5, 6,2,3,7, 2,0,1,3, 2,6,4,0, 1,5,7,3
  	];
  	
  	final List<double> v2 = [];
  	for(int i=0; i<24; ++i)	{
  		final int id4 = (i>>2);
  		v2.addAll( vertices	.getRange(order[i]*3,3) );
  		v2.addAll( texCoords.getRange((i&3)*2,2) );
  		v2.addAll( normals	.getRange(id4*3,3) );
  	}
  	final offsets = [0,2,3,0,1,2];
  	final List<int> i2 = [];
  	for(int i=0; i<36; ++i)	{
  		final int id6 = (i/6).truncate();
  		i2.add( id6*4 + offsets[i%6] );
  	}

	buff.Unit vBuffer = bArr.spawn( help.toFloat32(v2) );
    buff.Unit vIndex  = bInd.spawn( help.toUint8(i2) );
 
    final me = new mesh.Mesh('3');
    me.nVert = v2.length;
    me.nInd = i2.length;
    me.elements['a_position']	= new mesh.Elem.float32( 3, vBuffer, 32,0 );
    me.elements['a_tex']		= new mesh.Elem.float32( 2, vBuffer, 32,12 );
    me.elements['a_normal']		= new mesh.Elem.float32( 3, vBuffer, 32,20 );
    me.indices					= new mesh.Elem.index8( vIndex,0 );;
    return me;
  }

  mesh.Mesh cubeUnit() {
    return cube( new math.Vector.one() );
  }
}


class Texture	{
	final tex.Binding bind;
	final tex.LevelInfo infoColor;

	Texture(gl): bind = new tex.Binding.tex2d(gl),
		infoColor = new tex.LevelInfo.color(1,1);
	
	tex.Texture white()	{
		final t = bind.spawn();
		final color = help.toUint8([
			0xFF,0xFF,0xFF,0xFF
		]);
		final texData = new tex.Data.color( color, true );
		bind.load( t, infoColor, texData );	
		bind.state( t, false, false, 0 );
		return t;
	}
	
		
}
