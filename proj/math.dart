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
}


class Matrix  {
  final Vector v0,v1,v2,v3;
}


class Quaternion  {
  final double x,y,z,w;
  
  List<double> toList() => [x,y,z,w];
  
  Quaternion( this.x, this.y, this.z, this.w );
  
  Vector rotate(final Vector v) {
    final Vector base = new Vector(x,y,z,0.0);
    final Vector tmp = base.cross(v) + v.scale(w);
    return v + base.cross(tmp).scale(2.0);
  }
  
  Quaternion inverse() => new Quaternion(-x,-y,-z,w);
}