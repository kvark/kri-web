#library('view');
#import('math.dart');
#import('space.dart', prefix:'space');
#import('shade.dart', prefix:'shade');


class Projector implements space.IMatrix  {
  final bool perspective;
  final Vector c0,c1;
  
  Projector( this.perspective, this.c0, this.c1 );
  Projector.identity(): this( false, new Vector.one().scale(-1.0), new Vector.one() );
  
  factory Projector.perspective (double fovDegreesY, double aspect, double near, double far)  {
    double fy = near * Math.tan( fovDegreesY * degreesToHalfRadians );
    double fx = aspect * fy;
    final c0 = new Vector(-fx,-fy, -near, 0.0 );
    final c1 = new Vector( fx, fy, -far, 1.0 );
    return new Projector( true, c0, c1 );
  }
  
  factory Projector.ortho (double width, double height, double near, double far) {
    final c0 = new Vector(-0.5*width,-0.5*height, -near, 0.0 );
    final c1 = new Vector( 0.5*width, 0.5*height, -far, 1.0 );
    return new Projector( false, c0, c1 );
  }
  
  Matrix _getPerspectiveMatrix()  {
    final Vector den = (c0-c1).inverse(), sum = c1+c0;
    // note: W has to be positive or it will not work at all
    return new Matrix(
      new Vector( 2.0*c0.z * den.x, 0.0, sum.x * den.x, 0.0 ),
      new Vector( 0.0, 2.0*c0.z * den.y, sum.y * den.y, 0.0 ),
      new Vector( 0.0, 0.0, -sum.z * den.z, -2.0*c0.z*c1.z * den.z ),
      new Vector( 0.0, 0.0, 1.0, 0.0 ));
  }
  
  Matrix _getOrthoMatrix() {
    final Vector den = (c1-c0).inverse(), sum = c1+c0;
    return new Matrix(
      new Vector( +2.0*den.x, 0.0, 0.0, -sum.x * den.x ),
      new Vector( 0.0, +2.0*den.y, 0.0, -sum.y * den.y ),
      new Vector( 0.0, 0.0, -2.0*den.z, -sum.z * den.z ),
      new Vector.unitW());
  }
  
  Matrix getMatrix() => (perspective ? _getPerspectiveMatrix() : _getOrthoMatrix());
}


class Camera  {
  space.Node node;
  Projector projector;
  
  Camera();
  
  Matrix getInverseWorld()  {
    final Matrix local = projector==null ? new Matrix.identity() : projector.getMatrix();
    if (node==null)
      return local;
    final Matrix base = node.getWorld().inverse().getMatrix();
    return local * base;
  }
}


class Light {
  Light();
}


class DataSource implements shade.IDataSource {
  final space.Node modelNode;
  final Camera camera;
  
  DataSource( this.modelNode, this.camera );
  
  Matrix getModelMatrix() => (modelNode==null ?
    new Matrix.identity() : modelNode.getWorld().getMatrix() );
  
  Object askData( final String name ){
    switch(name) {
    case 'mx_model':
      return getModelMatrix();
    case 'mx_modelview':
      return (camera.node==null ? modelNode.getWorld() :
        modelNode.getWorld() * camera.node.getWorld().inverse()).
        getMatrix();
    case 'mx_viewproj':
      return camera.getInverseWorld();
    case 'mx_projection':
      return camera.projector.getMatrix();
    case 'mx_mvp':
      return camera.getInverseWorld() * getModelMatrix();
    case 'pos_camera':
      return camera.node==null ? new Vector.zero() : camera.node.getWorld().movement;
    }
    return null;
  }
} 
