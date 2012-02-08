#library('space');
#import('math.dart');

class Space {
  final Vector position;
  final Quaternion orientation;
  final double scale;
  
  Space( this.position, this.orientation, this.scale );
  Space.identity(): this( Vector.zero(), Quaternion.identity(), 1.0 );
  
  Space operator*(final Space c) => new Space( c.transform(position), c.orientation * orientation, c.scale * scale);
  
  Matrix assemble() => new Matrix.fromQuat( orientation, scale, position );
  Vector transform(final Vector v) => position + orientation.rotate(v).scale(scale);
  
  Space inverse() {
    final Quaternion q = orientation.inverse();
    final double s = 1.0 / scale;
    return new Space( q.rotate(position).scale(s), q, s );
  }
}


class Node  {
  Space space;
  Node parent;
  
  Node();
  
  Matrix getTransorm()  {
    final Matrix local = space==null ? new Matrix.identity() : space.assemble();
    return parent==null ? local : parent.getTransorm() * local; 
  }
}
