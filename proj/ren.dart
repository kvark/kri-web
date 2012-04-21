#library('kri:ren');
#import('dart:html',	prefix:'dom');
#import('mesh.dart',	prefix:'m');
#import('shade.dart',	prefix:'shade');
#import('frame.dart',	prefix:'frame');


interface IPipe	{
	// mode is: 0 for raster operations (Blit,Clear)
	// 1 - points, 2 - lines, 3 - triangles
	//IPipe activate(	final dom.WebGLRenderingContext gl, final int mode, final IPipe cache );
	void verify(	final dom.WebGLRenderingContext gl );
}

interface IEntity extends shade.IDataSource	{
	m.Mesh			getMesh();
	shade.Effect	getEffect();
	RasterState		getState();
}

interface ICall	{
	bool issue( final frame.Control control, final RasterState cache );
}

final Map<String,int> comparison = const{
	'never':	dom.WebGLRenderingContext.NEVER,
	'always':	dom.WebGLRenderingContext.ALWAYS,
	'<':		dom.WebGLRenderingContext.LESS,
	'<=':		dom.WebGLRenderingContext.LEQUAL,
	'==':		dom.WebGLRenderingContext.EQUAL,
	'>=':		dom.WebGLRenderingContext.GEQUAL,
	'>':		dom.WebGLRenderingContext.GREATER,
	'!=':		dom.WebGLRenderingContext.NOTEQUAL
};

final Map<String,int> operation = const{
	'':		dom.WebGLRenderingContext.KEEP,
	'0':	dom.WebGLRenderingContext.ZERO,
	'=':	dom.WebGLRenderingContext.REPLACE,
	'+':	dom.WebGLRenderingContext.INCR,
	'-':	dom.WebGLRenderingContext.DECR,
	'~':	dom.WebGLRenderingContext.INVERT,
	'++':	dom.WebGLRenderingContext.INCR_WRAP,
	'--':	dom.WebGLRenderingContext.DECR_WRAP
};

final Map<String,int> blendFactor = const{
	'0':	dom.WebGLRenderingContext.ZERO,
	'1':	dom.WebGLRenderingContext.ONE,
	'Sc':	dom.WebGLRenderingContext.SRC_COLOR,
	'1-Sc':	dom.WebGLRenderingContext.ONE_MINUS_SRC_COLOR,
	'Dc':	dom.WebGLRenderingContext.DST_COLOR,
	'1-Dc':	dom.WebGLRenderingContext.ONE_MINUS_DST_COLOR,
	'Sa':	dom.WebGLRenderingContext.SRC_ALPHA,
	'1-Sa':	dom.WebGLRenderingContext.ONE_MINUS_SRC_ALPHA,
	'Da':	dom.WebGLRenderingContext.DST_ALPHA,
	'1-Da':	dom.WebGLRenderingContext.ONE_MINUS_DST_ALPHA,
	'Cc':	dom.WebGLRenderingContext.CONSTANT_COLOR,
	'1-Cc':	dom.WebGLRenderingContext.ONE_MINUS_CONSTANT_COLOR,
	'Ca':	dom.WebGLRenderingContext.CONSTANT_ALPHA,
	'1-Ca':	dom.WebGLRenderingContext.ONE_MINUS_CONSTANT_ALPHA,
	'SaS':	dom.WebGLRenderingContext.SRC_ALPHA_SATURATE
};


class Primitive implements IPipe	{
	static final int stateId = dom.WebGLRenderingContext.CULL_FACE;
	final bool frontCw, cull;
	final int cullMode;
	final double lineWidth;
	
	Primitive( this.frontCw, this.cull, this.cullMode, this.lineWidth );
	Primitive.show( bool front, bool back, bool clockwise ):
		this( clockwise, !front || !back,
			(front && !back ? dom.WebGLRenderingContext.BACK :
			(back && !front ? dom.WebGLRenderingContext.FRONT :
			dom.WebGLRenderingContext.FRONT_AND_BACK )),
			1.0 );
	Primitive.ccw(): this.show(true,false,false);
	Primitive.line(double width): this(false,false,0,width);
	
	Primitive _changeWidth(double width) => new Primitive( frontCw, cull, cullMode, width );
	
	Primitive activate( final dom.WebGLRenderingContext gl, final Primitive cache, final String mode ){
		if (mode.startsWith('3'))	{
			if (cache==null || frontCw != cache.frontCw)
				gl.frontFace( frontCw ? dom.WebGLRenderingContext.CW : dom.WebGLRenderingContext.CCW );
			if (!cull && (cache==null || cache.cull))	{
				gl.disable(	stateId );
			}
			if (cull && (cache==null || !cache.cull))
				gl.enable( stateId );
			if (cull && (cache==null || cullMode != cache.cullMode))
				gl.cullFace( cullMode );
			return new Primitive( frontCw, cull, cullMode,
				cache!=null ? cache.lineWidth :null );
		}
		if (mode.startsWith('2'))	{
			if (cache==null || lineWidth != cache.lineWidth)
				gl.lineWidth( lineWidth );
			return cache!=null ? cache._changeWidth(lineWidth) : null;
		}
		return cache;
	}

	void verify( final dom.WebGLRenderingContext gl ){
		final int realFront	= gl.getParameter( dom.WebGLRenderingContext.FRONT_FACE );
		assert( (realFront == dom.WebGLRenderingContext.CW) == frontCw );
		assert( gl.isEnabled(stateId) == cull );
		assert( gl.getParameter(dom.WebGLRenderingContext.CULL_FACE_MODE) == cullMode );
		assert( gl.getParameter(dom.WebGLRenderingContext.LINE_WIDTH) == lineWidth );
	}
}


class Offset implements IPipe	{
	static final int stateId = dom.WebGLRenderingContext.POLYGON_OFFSET_FILL;
	final bool on;
	final double factor, units;
	
	Offset( this.on, this.factor, this.units );
	Offset.none(): this(false,0.0,0.0);
	
	Offset disabled() => new Offset( false, factor, units );
	
	Offset activate( final dom.WebGLRenderingContext gl, final Offset cache ){
		if (!on && (cache==null || cache.on))
			gl.disable(	stateId );
		if (!on)
			return cache!=null ? cache.disabled() : null;
		if (cache==null || !cache.on)
			gl.enable(	stateId );
		if (cache==null || factor!=cache.factor || units!=cache.units)
			gl.polygonOffset( factor, units );
		return this;
	}

	void verify( final dom.WebGLRenderingContext gl ){
		assert( gl.isEnabled(stateId) == on );
		assert( gl.getParameter(dom.WebGLRenderingContext.POLYGON_OFFSET_FACTOR) == factor );
		assert( gl.getParameter(dom.WebGLRenderingContext.POLYGON_OFFSET_UNITS) == units );
	}
}


class Scissor implements IPipe	{
	static final int stateId = dom.WebGLRenderingContext.SCISSOR_TEST;
	final bool on;
	final frame.Rect area;
	
	Scissor( this.on, this.area );
	Scissor.off(): this( false, null );

	Scissor disabled() => new Scissor( false, area );
	
	Scissor activate( final dom.WebGLRenderingContext gl, final Scissor cache ){
		if (!on && (cache==null || cache.on))
			gl.disable( stateId );
		if (!on)
			return cache!=null ? cache.disabled() : null;
		if (cache==null || !cache.on)
			gl.enable( stateId );
		if (cache==null || area != cache.area)
			gl.scissor( area.x, area.y, area.w, area.h );
		return this;
	}
	
	void verify( final dom.WebGLRenderingContext gl ){
		assert( gl.isEnabled(stateId) == on );
		final List<double> box = gl.getParameter( dom.WebGLRenderingContext.SCISSOR_BOX );
		assert( area.x==box[0] && area.y==box[1] && area.w==box[2] && area.h==box[3] );
	}
}


class MultiSample implements IPipe	{
	MultiSample();
	MultiSample.off();
	
	MultiSample activate( final dom.WebGLRenderingContext gl, final MultiSample cache ){
		return cache;
	}
	void verify( final dom.WebGLRenderingContext gl ){
	}
}


class StencilChannel	{
	final int function, refValue;
	final int readMask;
	final int opFail, opDepthFail, opPass;
	
	StencilChannel( String funCode, this.refValue, this.readMask,
		String fail, String depthFail, String pass ):
		function = comparison[funCode],		opFail = operation[fail],
		opDepthFail = operation[depthFail], opPass = operation[pass]{
		assert (function!=null && opFail!=null && opDepthFail!=null && opPass!=null );
	}
	
	StencilChannel activate( final dom.WebGLRenderingContext gl, final int face, final StencilChannel cache ){
		if (cache==null || function!=cache.function || refValue!=cache.refValue || readMask!=cache.readMask)
			gl.stencilFuncSeparate( face, function, refValue, readMask );
		if (cache==null || opFail!=cache.opFail || opDepthFail!=cache.opDepthFail || opPass!=cache.opPass)
			gl.stencilOpSeparate( face, opFail, opDepthFail, opPass );
		return this;
	}
}


class Stencil implements IPipe	{
	static final int stateId = dom.WebGLRenderingContext.STENCIL_TEST;
	final bool on;
	final StencilChannel front, back;
	
	Stencil( this.on, this.front, this.back );
	Stencil.off(): this( false, null, null );
	Stencil.simple( StencilChannel chan ): this( true, chan, chan );
	
	Stencil _disabled()	=> new Stencil( false, front, back );

	Stencil activate( final dom.WebGLRenderingContext gl, final Stencil cache ){
		if (!on && (cache==null || cache.on))
			gl.disable( stateId );
		if (!on)
			return cache!=null ? cache._disabled() : null;
		if (cache==null || !cache.on)
			gl.enable( stateId );
		if (front==back)	{
			final StencilChannel both = front.activate( gl,
				dom.WebGLRenderingContext.FRONT_AND_BACK,
				cache!=null ? cache.front :null);
			return new Stencil( on, both, both );
		}
		return new Stencil( on,
			front	.activate( gl, dom.WebGLRenderingContext.FRONT, cache!=null ? cache.front :null),
			back	.activate( gl, dom.WebGLRenderingContext.BACK, cache!=null ? cache.back :null) );
	}

	void verify( final dom.WebGLRenderingContext gl ){
		assert( gl.isEnabled(stateId) == on );
		// front
		assert( gl.getParameter(dom.WebGLRenderingContext.STENCIL_FUNC)				== front.function );
		assert( gl.getParameter(dom.WebGLRenderingContext.STENCIL_REF)				== front.refValue );
		assert( gl.getParameter(dom.WebGLRenderingContext.STENCIL_VALUE_MASK)		== front.readMask );
		assert( gl.getParameter(dom.WebGLRenderingContext.STENCIL_FAIL)				== front.opFail );
		assert( gl.getParameter(dom.WebGLRenderingContext.STENCIL_PASS_DEPTH_FAIL)	== front.opDepthFail );
		assert( gl.getParameter(dom.WebGLRenderingContext.STENCIL_PASS_DEPTH_PASS)	== front.opPass );
		// back
		assert( gl.getParameter(dom.WebGLRenderingContext.STENCIL_BACK_FUNC)			== back.function );
		assert( gl.getParameter(dom.WebGLRenderingContext.STENCIL_BACK_REF)				== back.refValue );
		assert( gl.getParameter(dom.WebGLRenderingContext.STENCIL_BACK_VALUE_MASK)		== back.readMask );
		assert( gl.getParameter(dom.WebGLRenderingContext.STENCIL_BACK_FAIL)			== back.opFail );
		assert( gl.getParameter(dom.WebGLRenderingContext.STENCIL_BACK_PASS_DEPTH_FAIL)	== back.opDepthFail );
		assert( gl.getParameter(dom.WebGLRenderingContext.STENCIL_BACK_PASS_DEPTH_PASS)	== back	.opPass );
	}
}


class Depth implements IPipe	{
	static final int stateId = dom.WebGLRenderingContext.DEPTH_TEST;
	final bool on;
	final int compare;
	
	Depth( this.on, this.compare );
	
	Depth.on( final String funCode ): this( true, comparison[funCode] ){
		assert( compare != null );
	}
	Depth.off(): this(false,0);
	
	Depth activate( final dom.WebGLRenderingContext gl, final Depth cache ){
		if (!on && (cache==null || cache.on))
			gl.disable( stateId );
		if (on && (cache==null || !cache.on))
			gl.enable( stateId );
		if (on && (cache==null || compare != cache.compare))
			gl.depthFunc( compare );
		return this;
	}
	void verify( final dom.WebGLRenderingContext gl ){
		assert( gl.isEnabled(stateId) == on );
		assert( gl.getParameter(dom.WebGLRenderingContext.DEPTH_FUNC) == compare );
	}
}


class BlendChannel	{
	final int equation, source, destination;

	BlendChannel.empty(): equation=0, source=0, destination=0;

	BlendChannel( this.equation, String src, String dst ):
		source = blendFactor[src], destination = blendFactor[dst]	{
		assert( source!=null && destination!=null );
	}
	BlendChannel.add( String src, String dst ):
		this( dom.WebGLRenderingContext.FUNC_ADD, src, dst );
	BlendChannel.sub( String src, String dst ):
		this( dom.WebGLRenderingContext.FUNC_SUBTRACT, src, dst );
	BlendChannel.revSub( String src, String dst ):
		this( dom.WebGLRenderingContext.FUNC_REVERSE_SUBTRACT, src, dst );
}

class Blend implements IPipe	{
	static final int stateId = dom.WebGLRenderingContext.BLEND;
	final bool on;
	final BlendChannel color, alpha;
	final frame.Color refValue;
	
	Blend( this.on, this.color, this.alpha, this.refValue );
	Blend.simple( BlendChannel chan ): this( true, chan, chan, new frame.Color.black() );
	Blend.off(): this(false,null,null,null);
	
	Blend _disabled() => new Blend( false, color, alpha, refValue );

	Blend activate( final dom.WebGLRenderingContext gl, final Blend cache ){
		if (!on && (cache==null || cache.on))
			gl.disable( stateId );
		if (!on)
			return cache!=null ? cache._disabled() : null;
		if (cache==null || !cache.on)
			gl.enable( stateId );
		//TODO: overload equality operator when language has support for it
		assert( color!=null && alpha!=null && refValue!=null );
		if (cache==null || color != cache.color || alpha != cache.alpha)	{
			if (color.equation == alpha.equation)
				gl.blendEquation( color.equation );
			else
				gl.blendEquationSeparate( color.equation, alpha.equation );
			if (color.source == alpha.source && color.destination == alpha.destination)
				gl.blendFunc( color.source, color.destination );
			else
				gl.blendFuncSeparate( color.source, color.destination, alpha.source, alpha.destination );
		}
		if (cache==null || refValue != cache.refValue)
			gl.blendColor( refValue.r, refValue.g, refValue.b, refValue.a );
		return this;
	}

	void verify( final dom.WebGLRenderingContext gl ){
		assert( gl.isEnabled(stateId) == on );
		assert( gl.getParameter(dom.WebGLRenderingContext.BLEND_EQUATION_RGB) == color.equation );
		assert( gl.getParameter(dom.WebGLRenderingContext.BLEND_SRC_RGB) == color.source );
		assert( gl.getParameter(dom.WebGLRenderingContext.BLEND_DST_RGB) == color.destination );
		assert( gl.getParameter(dom.WebGLRenderingContext.BLEND_EQUATION_ALPHA) == alpha.equation );
		assert( gl.getParameter(dom.WebGLRenderingContext.BLEND_SRC_ALPHA) == alpha.source );
		assert( gl.getParameter(dom.WebGLRenderingContext.BLEND_DST_ALPHA) == alpha.destination );
		//TODO: find a way to check the constant color
	}
}


class PixelMask implements IPipe	{
	final bool depth;
	final int stencilFront,stencilBack;
	final bool red,green,blue,alpha;
	
	PixelMask( this.depth, this.stencilFront, this.stencilBack, this.red, this.green, this.blue, this.alpha );
	PixelMask.withColor( bool d, int sf, int sb ): this( d,sf,sb,true,true,true,true );
	PixelMask.all(): this( true, -1,-1, true,true,true,true );
	
	bool hasColor()	=> red || green || blue || alpha;
	
	PixelMask activate( final dom.WebGLRenderingContext gl, final PixelMask cache ){
		gl.depthMask( depth );
		// stencil
		if (stencilFront!=stencilBack)	{
			gl.stencilMaskSeparate( dom.WebGLRenderingContext.FRONT, stencilFront );
			gl.stencilMaskSeparate( dom.WebGLRenderingContext.BACK, stencilBack );
		}else
			gl.stencilMask( stencilFront );
		// color
		gl.colorMask( red, green, blue, alpha );
		return cache;
	}

	void verify( final dom.WebGLRenderingContext gl ){
		assert( gl.getParameter(dom.WebGLRenderingContext.DEPTH_WRITEMASK) == depth );
		assert( gl.getParameter(dom.WebGLRenderingContext.STENCIL_WRITEMASK)		== stencilFront );
		assert( gl.getParameter(dom.WebGLRenderingContext.STENCIL_BACK_WRITEMASK)	== stencilBack );
	}
}


class RasterState implements IPipe	{
	final Primitive		primitive;
	final Offset		offset;
	final Scissor		scissor;
	final MultiSample	multiSample;
	final Stencil		stencil;
	final Depth			depth;
	final Blend			blend;
	final PixelMask		mask;
	
	RasterState( this.primitive, this.offset, this.scissor, this.multiSample, this.stencil, this.depth, this.blend, this.mask );
	RasterState.initial(): this( new Primitive.ccw(), new Offset.none(), new Scissor.off(), new MultiSample.off(),
		new Stencil.off(), new Depth.on('<='), new Blend.off(), new PixelMask.all() );
	
	RasterState changePixel( final Scissor newScissor, final PixelMask newMask ) => new RasterState( primitive, offset,
		newScissor, multiSample, stencil, depth, blend, newMask );
	
	RasterState activate( final dom.WebGLRenderingContext gl, final RasterState cache, final String polyType ){
		return new RasterState(
			primitive	.activate( gl, cache!=null ? cache.primitive :null, polyType ),
			offset		.activate( gl, cache!=null ? cache.offset :null ),
			scissor		.activate( gl, cache!=null ? cache.scissor :null ),
			multiSample	.activate( gl, cache!=null ? cache.multiSample :null ),
			stencil		.activate( gl, cache!=null ? cache.stencil :null ),
			depth		.activate( gl, cache!=null ? cache.depth :null ),
			blend		.activate( gl, cache!=null ? cache.blend :null ),
			mask		.activate( gl, cache!=null ? cache.mask :null ));
	}
	
	void verify( final dom.WebGLRenderingContext gl ){
		if (primitive!=null)
			primitive	.verify( gl );
		if (offset!=null)
			offset		.verify( gl );
		if (scissor!=null)
			scissor		.verify( gl );
		if (multiSample!=null)
			multiSample	.verify( gl );
		if (stencil!=null)
			stencil		.verify( gl );
		if (depth!=null)
			depth		.verify( gl );
		if (blend!=null)
			blend		.verify( gl );
		if (mask!=null)
			mask		.verify( gl );
	}
}


class Build	{
	Primitive	_primitive	= null;
	Offset		_offset		= null;
	Scissor		_scissor	= null;
	MultiSample	_multi		= null;
	Stencil		_stencil	= null;
	Depth		_depth		= null;
	Blend		_blend		= null;
	PixelMask	_mask		= null;
	
	Build offset(double units, double factor)	{
		_offset = new Offset( true, units, factor );
		return this;
	}
	Build scissor(frame.Rect rect)	{
		_scissor = new Scissor( true, rect );
		return this;
	}
	Build multiSample()	{
		return this;
	}
	Build stencil(StencilChannel chan)	{
		_stencil = new Stencil.simple(chan);
		return this;
	}
	Build depth(String funCode)	{
		_depth = new Depth.on(funCode);
		return this;
	}
	Build blend(BlendChannel chan)	{
		_blend = new Blend.simple(chan);
		return this;
	}
	Build mask(bool color, bool depth, int stencil)	{
		_mask = new PixelMask( depth, stencil, stencil, color, color, color, color );
		return this;
	}
	
	RasterState end() => new RasterState(
			_primitive	!=null ? _primitive	: new Primitive.ccw(),
			_offset		!=null ? _offset	: new Offset.none(),
			_scissor	!=null ? _scissor	: new Scissor.off(),
			_multi		!=null ? _multi		: new MultiSample.off(),
			_stencil	!=null ? _stencil	: new Stencil.off(),
			_depth		!=null ? _depth		: new Depth.off(),
			_blend		!=null ? _blend		: new Blend.off(),
			_mask		!=null ? _mask		: new PixelMask.all() );
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

	void verify( final dom.WebGLRenderingContext gl ){
		//todo
	}
}


class EntityBase implements IEntity	{
	m.Mesh mesh			= null;
	shade.Effect shader	= null;
	RasterState state	= null;
	final Map<String,Object> data;
	
	EntityBase():
		data = new Map<String,Object>();

	m.Mesh getMesh()			=> mesh;
	shade.Effect getEffect()	=> shader;
	RasterState getState()		=> state;

	void fillData( final Map<String,Object> block ){
		for (String key in data.getKeys())
			block[key] = data[key];
	}
}


class Material implements shade.IDataSource	{
	RasterState state;
	final shade.Effect effect;
	final Map<String,Object> data;
	
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
	final RasterState state;
	// constructor
	CallDraw(this.target, this.mesh, this.shader, this.state):
		parameters = new Map<String,Object>();
	// implementation
	RasterState issue( final frame.Control control, final RasterState cache ){
		target.activate( control );
		RasterState newState = state.activate( control.gl, cache, mesh.polyType );
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
	final Scissor scissor;
	final PixelMask pixelMask;
	// constructor
	CallClear( this.buffer, this.valueColor, this.valueDepth, this.valueStencil, this.scissor, this.pixelMask );
	// implementation
	RasterState issue( final frame.Control control, final RasterState cache ){
		control.bind( buffer );
		final Scissor newScissor = scissor	.activate( control.gl, cache!=null ? cache.scissor :null );
		final PixelMask newMask = pixelMask	.activate( control.gl, cache!=null ? cache.mask :null );
		control.clear(
			pixelMask.hasColor()		? valueColor	: null,
			pixelMask.depth				? valueDepth	: null,
			pixelMask.stencilFront != 0	? valueStencil	: null);
		return cache!=null ? cache.changePixel( newScissor, newMask ) :
			new RasterState(null,null,newScissor,null,null,null,null,newMask);
	}
}

class CallBlit implements ICall	{}

class CallTransform implements ICall	{}



class Process	{
	final List<ICall> batches;
	RasterState _cache = null;
	final bool useCache;
	
	Process(this.useCache): batches = new List<ICall>();

	void resetCache()	{ _cache = null; }
	
	void draw( Target target, IEntity ent ){
		final CallDraw call = new CallDraw( target, ent.getMesh(), ent.getEffect(), ent.getState() );
		ent.fillData( call.parameters );
		batches.add(call);
	}
	
	void clear( frame.Buffer buffer, frame.Color vColor, double vDepth, int vStencil, frame.Rect rect, PixelMask mask ){
		batches.add(new CallClear( buffer, vColor, vDepth, vStencil, new Scissor(rect!=null,rect), mask ));
	}
	
	int abort()	{
		int num = batches.length;
		batches.clear();
		return num;
	}

	int flush(final dom.WebGLRenderingContext gl)	{
		final frame.Control control = new frame.Control(gl);
		for (final ICall call in batches)	{
			if (!useCache)
				_cache = null;
			_cache = call.issue( control, _cache );
		}
		return abort();
	}
}
