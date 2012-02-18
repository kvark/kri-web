#library('gen');
#import('core.dart', prefix:'core');
#import('math.dart', prefix:'math');
#import('mesh.dart', prefix:'mesh');
#import('buff.dart', prefix:'buff');


class Generator	{
  final buff.Binding bArr, bInd;

  Generator(gl):
  	bArr = new buff.Binding.array(gl),
  	bInd = new buff.Binding.index(gl);

  mesh.Mesh cube(final math.Vector size) {
  	final vertices = bArr.toFloat32([
  	 -size.x,-size.y,-size.z,
  	  size.x,-size.y,-size.z,
  	 -size.x, size.y,-size.z,
  	  size.x, size.y,-size.z,
  	 -size.x,-size.y, size.z,
  	  size.x,-size.y, size.z,
  	 -size.x, size.y, size.z,
  	  size.x, size.y, size.z
  	]);
  	final indices = bInd.toUint8([
  	  0,1,4,5,7,1,3,0,2,4,6,7,2,3	//tri-strip
  	  //0,4,5,1, 4,6,7,5, 6,2,3,7, 2,0,1,3, 2,6,4,0, 1,5,7,3
  	]);

	buff.Unit vBuffer = bArr.spawn( vertices );
    buff.Unit vIndex  = bInd.spawn( indices );
    final vElem = new mesh.Elem.float32( 3, vBuffer,0,0 );
    final iElem = new mesh.Elem.index8( vIndex,0 );
 
    final me = new mesh.Mesh('3s');
    me.nVert = vertices.length;
    me.nInd = indices.length;
    me.elements['a_position'] = vElem;
    me.indices = iElem;
    return me;
  }

  mesh.Mesh cubeUnit() {
    return cube( new math.Vector.one() );
  }
}
