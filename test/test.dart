#import('unittest.dart',		prefix:'unit');
#import('../proj/math.dart',	prefix:'math');

void main()	{
	unit.group('Math:', (){
		final double scalar = 2.5;
		final math.Vector vector = new math.Vector(1.0,2.0,3.0,0.1);
		final math.Quaternion quat = new math.Quaternion.fromAxis(vector,10.0).normalize();

		unit.test('Vector operators', (){
			math.Vector rez = vector*(new math.Vector.one()) + new math.Vector.zero();
			Expect.isTrue( rez.isEqual(vector) );
			Expect.isTrue( math.isScalarZero( new math.Vector.unitX().dot(new math.Vector.unitY()) ));
			Expect.isTrue( math.isScalarZero(vector.length()*scalar - vector.scale(scalar).length()) );
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
}
