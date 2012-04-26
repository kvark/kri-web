#library('kri:rast');
#import('dart:html',	prefix:'dom');
#import('frame.dart',	prefix:'frame');


interface IPipe	{
	// mode is: 0 for raster operations (Blit,Clear)
	// 1 - points, 2 - lines, 3 - triangles
	//IPipe activate(	final dom.WebGLRenderingContext gl, final int mode, final IPipe cache );
	void verify( final dom.WebGLRenderingContext gl );
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

final Map<String,int> blendEquation = const{
	's+d':	dom.WebGLRenderingContext.FUNC_ADD,
	's-d':	dom.WebGLRenderingContext.FUNC_SUBTRACT,
	'd-s':	dom.WebGLRenderingContext.FUNC_REVERSE_SUBTRACT
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
	static final int stateAlpha	= dom.WebGLRenderingContext.SAMPLE_ALPHA_TO_COVERAGE;
	static final int stateCover	= dom.WebGLRenderingContext.SAMPLE_COVERAGE;

	final bool alpha,cover,invert;
	final int value;

	MultiSample( this.alpha, this.cover, this.value, this.invert );
	MultiSample.alpha( bool a ): this( a, false, 0, false );
	MultiSample.off(): this.alpha(false);
	
	MultiSample activate( final dom.WebGLRenderingContext gl, final MultiSample cache ){
		if (cache==null || alpha != cache.alpha)	{
			if (alpha)
				gl.enable(stateAlpha);
			else
				gl.disable(stateAlpha);
		}
		if (!cover && (cache==null || cache.cover))	{
			gl.disable(stateCover);
			return new MultiSample( alpha, false, cache.value, cache.invert );
		}
		if (cover && (cache==null || !cache.cover))
			gl.enable(stateCover);
		if (cache==null || value!=cache.value || invert!=cache.invert)
			gl.sampleCoverage( value, invert );
		return new MultiSample( alpha, true, value, invert );
	}
	void verify( final dom.WebGLRenderingContext gl ){
		assert( gl.isEnabled(stateAlpha) == alpha );
		assert( gl.isEnabled(stateCover) == cover );
		assert( gl.getParameter(dom.WebGLRenderingContext.SAMPLE_COVERAGE_VALUE)	== value );
		assert( gl.getParameter(dom.WebGLRenderingContext.SAMPLE_COVERAGE_INVERT)	== invert );
	}
}


class StencilChannel	{
	final int function, refValue;
	final int readMask;
	final int onFail, onDepthFail, onPass;
	
	StencilChannel( String funCode, this.refValue, this.readMask,
		String fail, String depthFail, String pass ):
		function = comparison[funCode],		onFail = operation[fail],
		onDepthFail = operation[depthFail], onPass = operation[pass]{
		assert (function!=null && onFail!=null && onDepthFail!=null && onPass!=null );
	}
	
	StencilChannel activate( final dom.WebGLRenderingContext gl, final int face, final StencilChannel cache ){
		if (cache==null || function!=cache.function || refValue!=cache.refValue || readMask!=cache.readMask)
			gl.stencilFuncSeparate( face, function, refValue, readMask );
		if (cache==null || onFail!=cache.onFail || onDepthFail!=cache.onDepthFail || onPass!=cache.onPass)
			gl.stencilOpSeparate( face, onFail, onDepthFail, onPass );
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
		assert( gl.getParameter(dom.WebGLRenderingContext.STENCIL_FAIL)				== front.onFail );
		assert( gl.getParameter(dom.WebGLRenderingContext.STENCIL_PASS_DEPTH_FAIL)	== front.onDepthFail );
		assert( gl.getParameter(dom.WebGLRenderingContext.STENCIL_PASS_DEPTH_PASS)	== front.onPass );
		// back
		assert( gl.getParameter(dom.WebGLRenderingContext.STENCIL_BACK_FUNC)			== back.function );
		assert( gl.getParameter(dom.WebGLRenderingContext.STENCIL_BACK_REF)				== back.refValue );
		assert( gl.getParameter(dom.WebGLRenderingContext.STENCIL_BACK_VALUE_MASK)		== back.readMask );
		assert( gl.getParameter(dom.WebGLRenderingContext.STENCIL_BACK_FAIL)			== back.onFail );
		assert( gl.getParameter(dom.WebGLRenderingContext.STENCIL_BACK_PASS_DEPTH_FAIL)	== back.onDepthFail );
		assert( gl.getParameter(dom.WebGLRenderingContext.STENCIL_BACK_PASS_DEPTH_PASS)	== back.onPass );
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
		assert( equation!=null && source!=null && destination!=null );
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


class Mask implements IPipe	{
	final int stencilFront,stencilBack;
	final bool depth;
	final bool red,green,blue,alpha;
	
	Mask( this.stencilFront, this.stencilBack, this.depth, this.red, this.green, this.blue, this.alpha );
	Mask.withColor( int sf, int sb, bool d ): this( sf,sb,d, true,true,true,true );
	Mask.all(): this( -1,-1,true, true,true,true,true );
	Mask.fromString( int sf, int sb, bool d, String c ):
		this( sf,sb,d, c.contains('R'), c.contains('G'), c.contains('B'), c.contains('A') );
	
	bool hasColor()	=> red || green || blue || alpha;
	
	Mask activate( final dom.WebGLRenderingContext gl, final Mask cache ){
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


class State implements IPipe	{
	final Primitive		primitive;
	final Offset		offset;
	final Scissor		scissor;
	final MultiSample	multiSample;
	final Stencil		stencil;
	final Depth			depth;
	final Blend			blend;
	final Mask			mask;
	
	State( this.primitive, this.offset, this.scissor, this.multiSample, this.stencil, this.depth, this.blend, this.mask );
	State.initial(): this( new Primitive.ccw(), new Offset.none(), new Scissor.off(), new MultiSample.off(),
		new Stencil.off(), new Depth.on('<='), new Blend.off(), new Mask.all() );
	
	State changePixel( final Scissor newScissor, final Mask newMask ) => new State( primitive, offset,
		newScissor, multiSample, stencil, depth, blend, newMask );
	
	State activate( final dom.WebGLRenderingContext gl, final State cache, final String polyType ){
		return new State(
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
