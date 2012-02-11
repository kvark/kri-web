#library('view');
#import('math.dart');
#import('space.dart', prefix:'space');
#import('shade.dart', prefix:'shade');


class Projector implements space.ITransform {
  final space.Node node;
  double fovDegrees, aspect;
  double rangeNear, rangeFar;
  Vector shear;
  
  Projector( this.node ):
    fovDegrees=45.0, aspect=4.0/3.0,
    rangeNear=1.0, rangeFar=100.0,
    shear=new Vector.zero();
  
  Matrix getMatrix()  {
    return new Matrix.zero();
  }
  
  Matrix getInverseWorld()  {
    final Matrix base = (node!=null ? node.getWorld().getMatrix() : new Matrix.identity());
    return (base * getMatrix()).inverseProj();
  }
}


class Camera extends Projector  {
  Camera(space.Node node): Projector(node);
}


class Light extends Projector {
  Light(space.Node node): Projector(node);
}