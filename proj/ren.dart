#library('kri:ren');
//#import('dart:html',	prefix:'dom');	//need only for WebGLRenderingContext
#import('frame.dart',	prefix:'frame');
#import('mesh.dart',	prefix:'m');
#import('rast.dart',	prefix:'rast');
#import('shade.dart',	prefix:'shade');


interface IEntity extends shade.IDataSource	{
	m.Mesh			getMesh();
	shade.Effect	getEffect();
	rast.State		getState();
}

interface ICall	{
	rast.State issue( final frame.Control control, final rast.State cache );
}


class Target	{
	final frame.Buffer buffer;
	final frame.Rect viewRect;
	final double depthMin, depthMax;
	
	Target( this.buffer, this.viewRect, this.depthMin, this.depthMax );
	
	void activate( final frame.Control control ){
		control.bind( buffer );
		control.viewport( viewRect, depthMin, depthMax );
	}

	void verify( final /*dom.WebGLRenderingContext*/ gl ){
		//todo
	}
}


class EntityBase implements IEntity	{
	m.Mesh mesh			= null;
	shade.Effect shader	= null;
	rast.State state	= null;
	final Map<String,Object> data;
	
	EntityBase():
		data = new Map<String,Object>();

	m.Mesh getMesh()			=> mesh;
	shade.Effect getEffect()	=> shader;
	rast.State getState()		=> state;

	void fillData( final Map<String,Object> block ){
		for (String key in data.getKeys())
			block[key] = data[key];
	}
}

class Technique	{
	final rast.State state;
	final shade.Effect effect;
}

class Material implements shade.IDataSource	{
	final String name;
	final Map<String,Object> data;
	final Map<String,Technique> techniques;
	
	Material( this.name ):
		data = new Map<String,Object>(),
		techniques = new Map<String,Technique>();
	
	void fillData(final Map<String,Object> block)	{
		for (String key in block.getKeys())
			data[key] = block[key];
	}
}

// Calls argument conventions: target, what, how

class CallDraw implements ICall	{
	final Target target;
	// data
	final m.Mesh mesh;
	// program
	final shade.Effect shader;
	final Map<String,Object> parameters;
	// environment
	final rast.State state;
	// constructor
	CallDraw(this.target, this.mesh, this.shader, this.state):
		parameters = new Map<String,Object>();
	// implementation
	rast.State issue( final frame.Control control, final rast.State cache ){
		target.activate( control );
		rast.State newState = state.activate( control.gl, cache, mesh.polyType );
		mesh.draw( control.gl, shader, parameters );
		return newState;
	}
}

class CallClear implements ICall	{
	final frame.Buffer buffer;
	// values
	final frame.Color valueColor;
	final double valueDepth;
	final int valueStencil;
	// environment
	final rast.Scissor scissor;
	final rast.Mask pixelMask;
	// constructor
	CallClear( this.buffer, this.valueColor, this.valueDepth, this.valueStencil, this.scissor, this.pixelMask );
	// implementation
	rast.State issue( final frame.Control control, final rast.State cache ){
		control.bind( buffer );
		final rast.Scissor newScissor = scissor	.activate( control.gl, cache!=null ? cache.scissor :null );
		final rast.Mask newMask = pixelMask		.activate( control.gl, cache!=null ? cache.mask :null );
		control.clear(
			pixelMask.hasColor()		? valueColor	: null,
			pixelMask.depth				? valueDepth	: null,
			pixelMask.stencilFront != 0	? valueStencil	: null);
		return cache!=null ? cache.changePixel( newScissor, newMask ) :
			new rast.State(null,null,newScissor,null,null,null,null,newMask);
	}
}

class CallBlit implements ICall	{}

class CallTransform implements ICall	{}



class Process	{
	final List<ICall> batches;
	rast.State _cache = null;
	final bool useCache;
	
	Process(this.useCache): batches = new List<ICall>();

	void resetCache()	{ _cache = null; }
	
	void draw( Target target, IEntity ent ){
		final CallDraw call = new CallDraw( target, ent.getMesh(), ent.getEffect(), ent.getState() );
		ent.fillData( call.parameters );
		batches.add(call);
	}
	
	void clear( frame.Buffer buffer, frame.Color vColor, double vDepth, int vStencil, frame.Rect rect, rast.Mask mask ){
		batches.add(new CallClear( buffer, vColor, vDepth, vStencil, new rast.Scissor(rect!=null,rect), mask ));
	}
	
	int abort()	{
		int num = batches.length;
		batches.clear();
		return num;
	}

	int flush(final /*WebGLRenderingContext*/ gl)	{
		final frame.Control control = new frame.Control(gl);
		for (final ICall call in batches)	{
			if (!useCache)
				_cache = null;
			_cache = call.issue( control, _cache );
		}
		return abort();
	}
}
