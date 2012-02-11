#library('space');
#import('math.dart');


interface ITransform  {
  Matrix getMatrix();
}


class Space implements ITransform {
  final Vector position;
  final Quaternion orientation;
  final double scale;
  
  Space( this.position, this.orientation, this.scale );
  Space.identity(): this( Vector.zero(), Quaternion.identity(), 1.0 );
  
  Space operator*(final Space c) => new Space( c.transform(position), c.orientation * orientation, c.scale * scale);
  
  Matrix getMatrix() => new Matrix.fromQuat( orientation, scale, position );
  Vector transform(final Vector v) => position + orientation.rotate(v).scale(scale);
  
  Space inverse() {
    final Quaternion q = orientation.inverse();
    final double s = 1.0 / scale;
    return new Space( q.rotate(position).scale(s), q, s );
  }
}


class Node {
  final String name;
  Space space;
  Node parent;
  
  Node(this.name);
  
  Space getWorld()  {
    final Space local = space==null ? new Space.identity() : space;
    return parent==null ? local : parent.getWorld() * local; 
  }
}
