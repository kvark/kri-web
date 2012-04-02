#library('math');

final double epsilon = 1.0e-5; 

interface IDoubleList  {
  List<double> toList();
}

final double degreesToHalfRadians = Math.PI / 360.0 ;


class Vector implements IDoubleList {
  final double x,y,z,w;
  
  List<double> toList() => [x,y,z,w];
  String toString() => "(${x},${y},${z},${w})";
  
  Vector( this.x, this.y, this.z, this.w );
  Vector.mono(double d): this(d,d,d,d);
  Vector.zero():  this.mono(0.0);
  Vector.one():   this.mono(1.0);
  Vector.unitX(): this(1.0,0.0,0.0,0.0);
  Vector.unitY(): this(0.0,1.0,0.0,0.0);
  Vector.unitZ(): this(0.0,0.0,1.0,0.0);
  Vector.unitW(): this(0.0,0.0,0.0,1.0);
  
  Vector operator+(final Vector v) => new Vector( x+v.x, y+v.y, z+v.z, w+v.w );
  Vector operator-(final Vector v) => new Vector( x-v.x, y-v.y, z-v.z, w-v.w );
  Vector operator*(final Vector v) => new Vector( x*v.x, y*v.y, z*v.z, w*v.w );
  
  Vector scale(double val)    => new Vector( x*val, y*val, z*val, w );
  double dot(final Vector v)  => x*v.x + y*v.y + z*v.z + w*v.w;
  double lengthSquare() => dot( this );
  double length() => Math.sqrt( dot(this) );
  
  Vector perspective() => scale( 1.0/w );
  
  bool isZero() => lengthSquare() < epsilon;
  
  Vector inverse() => new Vector( 1.0/x, 1.0/y, 1.0/z, w );
  
  Vector cross(final Vector v)  {
    assert( w==0.0 && v.w==0.0 );
    return new Vector( y*v.z - z*v.y, z*v.x - x*v.z, x*v.y - y*v.x, 0.0 );
  }
  
  Vector normalize()  {
    final double len2 = lengthSquare();
    return len2>0.0 ? scale(1.0/Math.sqrt(len2)) : this;
  }
}



class Matrix implements IDoubleList  {
  final Vector x,y,z,w;
  
  Matrix( this.x, this.y, this.z, this.w );
  Matrix.affine( this.x, this.y, this.z ): w=new Vector.unitW();
  Matrix.identity(): this( new Vector.unitX(), new Vector.unitY(), new Vector.unitZ(), new Vector.unitW() );

  Matrix.translation(final Vector v): this(
      new Vector(1.0,0.0,0.0,v.x),
      new Vector(0.0,1.0,0.0,v.y),
      new Vector(0.0,0.0,1.0,v.z),
      new Vector(0.0,0.0,0.0,1.0));
  
  Matrix.diagonal(final Vector v): this(
      new Vector(v.x,0.0,0.0,0.0),
      new Vector(0.0,v.y,0.0,0.0),
      new Vector(0.0,0.0,v.z,0.0),
      new Vector(0.0,0.0,0.0,v.w));
  
  factory Matrix.zero() {
    final Vector v = new Vector.zero();
    return new Matrix(v,v,v,v);
  }

  Matrix.fromQuat( final Quaternion q, final double s, final Vector p ): this(
      new Vector( 2.0*s*(0.5 - q.y*q.y - q.z*q.z), 2.0*s*(q.x*q.y - q.z*q.w), 2.0*s*(q.x*q.z + q.y*q.w), p.x ),
      new Vector( 2.0*s*(q.x*q.y + q.z*q.w), 2.0*s*(0.5 - q.z*q.z - q.x*q.x), 2.0*s*(q.y*q.z - q.x*q.w), p.y ),
      new Vector( 2.0*s*(q.x*q.z - q.y*q.w), 2.0*s*(q.y*q.z + q.x*q.w), 2.0*s*(0.5 - q.x*q.x - q.y*q.y), p.z ),
      new Vector.unitW() );
  
  List<double> toList() => [x.x,y.x,z.x,w.x, x.y,y.y,z.y,w.y, x.z,y.z,z.z,w.z, x.w,y.w,z.w,w.w];
  String toString()	{
  	final Matrix t = transpose();
  	return "(x=${t.x},y=${t.y},z=${t.z},w=${t.w}";
  }
  
  Matrix operator+(final Matrix m) => new Matrix( x + m.x, y + m.y, z + m.z, w + m.w );
  Matrix operator-(final Matrix m) => new Matrix( x - m.x, y - m.y, z - m.z, w - m.w );
  
  Matrix operator*(final Matrix m) {
    final Matrix t = m.transpose();
    return new Matrix(
      new Vector( x.dot(t.x), x.dot(t.y), x.dot(t.z), x.dot(t.w) ),
      new Vector( y.dot(t.x), y.dot(t.y), y.dot(t.z), y.dot(t.w) ),
      new Vector( z.dot(t.x), z.dot(t.y), z.dot(t.z), z.dot(t.w) ),
      new Vector( w.dot(t.x), w.dot(t.y), w.dot(t.z), w.dot(t.w) ));
  }
  
  Vector columnX()  => new Vector( x.x, y.x, z.x, w.x );
  Vector columnY()  => new Vector( x.y, y.y, z.y, w.y );
  Vector columnZ()  => new Vector( x.z, y.z, z.z, w.z );
  Vector columnW()  => new Vector( x.w, y.w, z.w, w.w );
  Vector diagonal() => new Vector( x.x, y.y, z.z, w.w );
  
  Matrix transpose() => new Matrix( columnX(), columnY(), columnZ(), columnW() );
  
  double lengthSquare() => x.lengthSquare() + y.lengthSquare() + z.lengthSquare() + w.lengthSquare();
  
  bool isAffine() {
    final Vector p0 = new Vector.unitW();
    final double dist = (w-p0).lengthSquare();
    return dist < epsilon;
  }
  
  bool isOrthogonal() {
    final Matrix mzero = new Matrix.zero();
    final Matrix m1 = this * transpose();
    final Matrix m2 = new Matrix.diagonal( m1.diagonal() );
    final double dist = (m1-m2).lengthSquare();
    return dist < epsilon;
  }
  
  bool isOrthonormal()  {
    final Matrix result = this * transpose();
    final Matrix mid = new Matrix.identity();
    final double dist = (result-mid).lengthSquare();
    return dist < epsilon;
  }
  
  Matrix scale(double val) => new Matrix( x.scale(val), y.scale(val), z.scale(val), w.scale(val) );
  Vector transform(final Vector v) => new Vector( v.dot(x), v.dot(y), v.dot(z), v.dot(w) );
  //double det3()
  //double det4()
  
  Matrix inverseAffine()  {
    return this;
  }

  Matrix inverseProj()  {
    return this;
  }
  
  // general method, should automatically choose
  // the fastest way to calculate inversion
  Matrix inverse()  {

    return inverseProj();
  }
}



class Quaternion implements IDoubleList  {
  final double x,y,z,w;
  
  List<double> toList() => [x,y,z,w];
  String toString() => "(${x},${y},${z},${w})";
  
  Quaternion( this.x, this.y, this.z, this.w );
  Quaternion.identity(): this(0.0,0.0,0.0,1.0);
  Quaternion.fromBase( final Vector v, this.w ): x=v.x, y=v.y, z=v.z;
  
  factory Quaternion.fromSum( final Quaternion a, final double wa, final Quaternion b, final double wb) =>
  	new Quaternion( wa*a.x+wb*b.x, wa*a.y+wb*b.y, wa*a.z+wb*b.z, wa*a.w+wb*b.w );

  static Quaternion lerp( final Quaternion a, final Quaternion b, double t )
  	=> new Quaternion.fromSum( a, 1.0-t, b, t ).normalize();
  
  static Quaternion slerp( final Quaternion a, final Quaternion b, double t ){
    final double cosHalf = a.dot(b);
    if (cosHalf+epsilon>1.0 || cosHalf-epsilon<-1.0)
    	return a;
    final double halfAngle = Math.acos( cosHalf.abs() );
    final double ka = Math.sin(halfAngle * (1.0-t));
    final double kb = Math.sin(halfAngle * t);
    return new Quaternion.fromSum( a, ka, cosHalf<0 ? b.negative() : b, kb ).normalize();
  }
  
  factory Quaternion.fromAxis( final Vector axis, double angleDegrees ){
  	final double halfRadians = degreesToHalfRadians * angleDegrees;
    final double sin = Math.sin( halfRadians );
    final double cos = Math.cos( halfRadians );
    return new Quaternion.fromBase( axis.scale(sin), cos );
  }
  
  factory Quaternion.fromNormal( final Vector normal ){
    if (normal.z > 0.0) {
      final double d = Math.sqrt(2.0 + 2.0*normal.z);
      return new Quaternion( -normal.y/d, normal.x/d, 0.0, 0.5*d );
    }else {
      final double d = Math.sqrt(2.0 - 2.0*normal.z);
      return new Quaternion( 0.0, 0.5*d, normal.y/d, normal.x/d );
    }
  }
  
  Vector rotate(final Vector v) {
    final Vector b = base();
    final Vector tmp = b.cross(v) + v.scale(w);
    return v + b.cross(tmp).scale(2.0);
  }
  
  Quaternion operator*(final Quaternion q)  {
    final Vector a = base(), b = q.base();
    final Vector v = a.cross(b) + a.scale(q.w) + b.scale(w);
    final double e = w*q.w - a.dot(b);
    return new Quaternion.fromBase(v,e);  
  }
  
  double dot(final Quaternion q) => x*q.x + y*q.y + z*q.z + w*q.w;
  
  Vector base() => new Vector(x,y,z,0.0);
  Quaternion inverse()	=> new Quaternion(-x,-y,-z,w);
  Quaternion negative()	=> new Quaternion(-x,-y,-z,-w);
  double lengthSquare() => x*x + y*y + z*z + w*w;
  
  Quaternion normalize()  {
    final double len2 = lengthSquare();
    if (len2<epsilon)
      return this;
    final double k = 1.0 / Math.sqrt(len2);
    return new Quaternion( x*k, y*k, z*k, w*k );
  }
}
