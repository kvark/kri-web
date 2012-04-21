#library('space');
#import('ani.dart', prefix:'ani');
#import('math.dart');


interface IMatrix  {
  Matrix getMatrix();
}


class Space implements IMatrix {
  final Vector movement;
  final Quaternion rotation;
  final double scale;
  
  Space( this.movement, this.rotation, this.scale );
  Space.identity(): this( new Vector.zero(), new Quaternion.identity(), 1.0 );
  Space.fromMoveScale(double x, double y, double z, double s):
    this( new Vector(x,y,z,0.0), new Quaternion.identity(), s );
  
  Space operator*(final Space c) => new Space( transform(c.movement), rotation * c.rotation, scale * c.scale);
  
  Matrix getMatrix() => new Matrix.fromQuat( rotation, scale, movement );
  Vector getMoveScale() => new Vector( movement.x, movement.y, movement.z, scale );
  Vector transform(final Vector v) => movement + rotation.rotate(v).scale(scale);
  
  Space inverse() {
    final Quaternion q = rotation.inverse();
    final double s = 1.0 / scale;
    return new Space( q.rotate(movement).scale(-s), q, s );
  }
  
  String toString() => "(m=${movement},r=${rotation},s=${scale}";
}


class Node extends ani.Player {
  final String name;
  Space space, _oldLocal=null, _parWorld=null, _world=null;
  Node parent, _oldParent=null;
  
  Node(this.name);
  
  Space getWorld()  {
    final Space local = space==null ? new Space.identity() : space;
    if (parent==null)
        return local;
    final Space parWorld = parent.getWorld();
    if (parent==_oldParent && parWorld==_parWorld)
        return _world;
    _oldParent = parent;
    _parWorld = parWorld;
    _world = parWorld * local;
    return _world;
  }
}



