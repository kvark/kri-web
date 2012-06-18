#library('kri:ren');
//#import('dart:html',	prefix:'dom');	//need only for WebGLRenderingContext
#import('frame.dart',	prefix:'frame');
#import('mesh.dart',	prefix:'me');
#import('rast.dart',	prefix:'rast');
#import('shade.dart',	prefix:'shade');


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


// Calls argument conventions: target, what, how

class CallDraw implements ICall	{
	final Target target;
	// data
	final me.Mesh mesh;
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
	
	void draw( Target target, me.Mesh mesh, shade.Effect effect, rast.State state, shade.IDataSource source ){
		final CallDraw call = new CallDraw( target, mesh, effect, state );
		source.fillData( call.parameters );
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
