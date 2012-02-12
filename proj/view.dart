#library('view');
#import('math.dart');
#import('space.dart', prefix:'space');
#import('shade.dart', prefix:'shade');


final double degreesToHalfRadians = 90.0 / Math.PI;


class Projector implements space.ITransform {
  space.Node node;
  bool perspective;
  Vector c0,c1; // frustum corners
  
  Projector(): perspective=false,
    c0 = new Vector(-1.0,-1.0,1.0,0.0),
    c1 = new Vector(+1.0,+1.0,100.0,1.0);
  
  void setFov(double fovDegreesX, double fovDegreesY) {
    double fx = fovDegreesX * degreesToHalfRadians;
    double fy = fovDegreesY * degreesToHalfRadians;
    c0 = new Vector(-fx,-fy, c0.z, 0.0 );
    c1 = new Vector( fx, fy, c1.z, 1.0 );
    perspective = true;
  }
  
  void setRange(double near, double far)  {
    c0 = new Vector( c0.x, c0.y, near, 0.0 );
    c1 = new Vector( c1.x, c1.y, far, 1.0 );
  }
  
  Matrix getPerspectiveMatrix()  {
    final Vector den = (c1-c0).inverse(), sum = c1+c0;
    return new Matrix(
      new Vector( 2.0*c0.z * den.x, 0.0, sum.x * den.x, 0.0 ),
      new Vector( 0.0, 2.0*c0.z * den.y, sum.y * den.y, 0.0 ),
      new Vector( 0.0, 0.0, -sum.z * den.z, -2.0*c0.z*c1.z * den.z ),
      new Vector( 0.0, 0.0, -1.0, 0.0 ));
  }
  
  Matrix getOrthoMatrix() {
    final Vector den = (c1-c0).inverse(), sum = c1+c0;
    return new Matrix(
      new Vector( +2.0*den.x, 0.0, 0.0, -sum.x * den.x ),
      new Vector( 0.0, +2.0*den.y, 0.0, -sum.y * den.y ),
      new Vector( 0.0, 0.0, -2.0*den.z, -sum.z * den.z ),
      new Vector.unitW());
  }
  
  Matrix getMatrix() => (perspective ? getPerspectiveMatrix() : getOrthoMatrix());
  
  Matrix getInverseWorld()  {
    final Matrix local = getMatrix();
    if (node==null)
      return local;
    final Matrix base = node.getWorld().inverse().getMatrix();
    return getMatrix() * base;
  }
}



class Camera extends Projector  {
  Camera();
}


class Light extends Projector {
  Light();
}


class DataSource implements shade.IDataSource {
  final space.Node modelNode;
  final Projector projector;
  
  DataSource( this.modelNode, this.projector );
  
  Matrix getModelMatrix() => (modelNode==null ?
    new Matrix.identity() : modelNode.getWorld().getMatrix() );
  
  Object askData(String name) {
    switch(name) {
    case 'mx_model':
      return getModelMatrix();
    case 'mx_modelview':
      return (projector.node==null ? modelNode.getWorld() :
        modelNode.getWorld() * projector.node.getWorld().inverse()).
        getMatrix();
    case 'mx_viewproj':
      return projector.getInverseWorld();
    case 'mx_projection':
      return projector.getMatrix();
    case 'mx_mvp':
      return projector.getInverseWorld() * getModelMatrix();
    }
    return null;
  }
} 