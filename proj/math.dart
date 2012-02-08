#library('math');


class Vector {
  final double x,y,z,w;
  
  List<double> toList() => [x,y,z,w];
  
  Vector( this.x, this.y, this.z, this.w );
  Vector.zero():  this(0.0,0.0,0.0,0.0);
  Vector.one():   this(1.0,1.0,1.0,1.0);
  Vector.unitX(): this(1.0,0.0,0.0,0.0);
  Vector.unitY(): this(0.0,1.0,0.0,0.0);
  Vector.unitZ(): this(0.0,0.0,1.0,0.0);
  Vector.unitW(): this(0.0,0.0,0.0,1.0);
  
  Vector operator+(final Vector v) => new Vector( x+v.x, y+v.y, z+v.z, w+v.w );
  Vector operator*(final Vector v) => new Vector( x*v.x, y*v.y, z*v.z, w*v.w );
  Vector scale(double val)    => new Vector( x*val, y*val, z*val, w*val );
  double dot(final Vector v)  => x*v.x + y*v.y + z*v.z + w*v.w;
  double lengthSquare() => dot( this );
  
  Vector cross(final Vector v)  {
    assert( w==0.0 && v.w==0.0 );
    return new Vector( y*v.z - z*v.y, z*v.x - x*v.z, x*v.y - y*v.z, 0.0 );
  }
  
  Vector normalize()  {
    final double len2 = lengthSquare();
    return len2>0.0 ? scale(1.0/Math.sqrt(len2)) : this;
  }
}


class Matrix  {
  final Vector x,y,z,w;
  
  Matrix( this.x, this.y, this.z, this.w );
  Matrix.affine( this.x, this.y, this.z ): w=new Vector.unitW();
  Matrix.identity(): this( new Vector.unitX(), new Vector.unitY(), new Vector.unitZ(), new Vector.unitW() );
  Matrix.zero(): this( new Vector.zero(), new Vector.zero(), new Vector.zero(), new Vector.zero() );

  Matrix.fromQuat( final Quaternion q, final double s, final Vector p ):
      x = new Vector( 2.0*s*(0.5 - q.y*q.y - q.z*q.z), 2.0*q.x*q.y - 2.0*q.z*q.w, 2.0*q.x*q.z + 2.0*q.y*q.w, p.x ),
      y = new Vector( 2.0*q.x*q.y + 2.0*q.z*q.w, 2.0*s*(0.5 - q.x*q.x - q.z*q.z), 2.0*q.y*q.y - 2.0*q.x*q.w, p.y ),
      z = new Vector( 2.0*q.x*q.z - 2.0*q.y*q.w, 2.0*q.y*q.z + 2.0*q.x*q.w, 2.0*s*(0.5 - q.x*q.x - q.y*q.y), p.z ),
      w = new Vector.unitW();
  
  Matrix operator+(final Matrix m) => new Matrix( x + m.x, y + m.y, z + m.z, w + m.w );
  
  Matrix operator*(final Matrix m) {
    final Matrix t = m.transpose();
    return new Matrix(
      new Vector( x.dot(t.x), x.dot(t.y), x.dot(t.z), x.dot(t.w) ),
      new Vector( y.dot(t.x), y.dot(t.y), y.dot(t.z), y.dot(t.w) ),
      new Vector( z.dot(t.x), z.dot(t.y), z.dot(t.z), z.dot(t.w) ),
      new Vector( w.dot(t.x), w.dot(t.y), w.dot(t.z), w.dot(t.w) ));
  }
  
  Matrix transpose() => new Matrix(
    new Vector(x.x,y.x,z.x,w.x),
    new Vector(x.y,y.y,z.y,w.y),
    new Vector(x.z,y.z,z.z,w.z),
    new Vector(x.w,y.w,z.w,w.w));
  
  Matrix scale(double val) => new Matrix( x.scale(val), y.scale(val), z.scale(val), w.scale(val) );
  Vector mul(final Vector v) => new Vector( v.dot(x), v.dot(y), v.dot(z), v.dot(w) );
  //double det3()
  //double det4()
  
  //Matrix inverseAffine()
  //Matrix inverseProj()
  //bool isAffine()
  //bool isOrthogonal()
  //bool isOrthonormal()
}


class Quaternion  {
  final double x,y,z,w;
  
  List<double> toList() => [x,y,z,w];
  
  Quaternion( this.x, this.y, this.z, this.w );
  Quaternion.identity(): this(0.0,0.0,0.0,1.0);
  Quaternion.fromBase( final Vector v, this.w ): x=v.x, y=v.y, z=v.z;
  
  Quaternion.fromAxis( double ax, double ay, double az, double angle )  {
    final double sin = Math.sin( 0.5*angle );
    w = Math.cos( 0.5*angle );
    x = ax*sin; y = ay*sin; z = az*sin;
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
  
  Vector base() => new Vector(x,y,z,0.0);
  Quaternion inverse() => new Quaternion(-x,-y,-z,w);
  double lengthSquare() => x*x + y*y + z*z + w*w;
  
  Quaternion normalize()  {
    final double len2 = lengthSquare();
    if (len2<=1e-6)
      return this;
    final double k = 1.0 / Math.sqrt(len2);
    return new Quaternion( x*k, y*k, z*k, w*k );
  }
  
  Quaternion lerp(final Quaternion q, final double t) {
    final double r = 1.0 - t;
    return new Quaternion( r*x+t*q.x, r*y+t*q.y, r*z+t*q.z, r*w+t*q.w ); 
  }
}