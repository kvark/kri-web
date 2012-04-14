#library('ren');
#import('dart:html',	prefix:'dom');
#import('mesh.dart',	prefix:'m');
#import('shade.dart',	prefix:'shade');
#import('frame.dart',	prefix:'frame');


interface IState	{
		void activate( final dom.WebGLRenderingContext gl );
}

interface IEntity extends shade.IDataSource	{
	m.Mesh			getMesh();
	shade.Effect	getEffect();
	RasterState		getState();
}

interface ICall	{
	bool issue( final frame.Control control );
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


class Face implements IState	{
	final bool front, back, clockwise;
	
	Face( this.front, this.back, this.clockwise );
	Face.ccw(): this(true,false,false);
	
	void activate( final dom.WebGLRenderingContext gl ){
		gl.frontFace( clockwise ? dom.WebGLRenderingContext.CW : dom.WebGLRenderingContext.CCW );
		if (!front || !back)	{
			gl.enable(	dom.WebGLRenderingContext.CULL_FACE );
			if (!front)
				gl.cullFace( dom.WebGLRenderingContext.FRONT );
			else if (!back)
				gl.cullFace( dom.WebGLRenderingContext.BACK );
			else
				gl.cullFace( dom.WebGLRenderingContext.FRONT_AND_BACK );
		}else
			gl.disable(	dom.WebGLRenderingContext.CULL_FACE );
	}
}


class BlendChannel	{
	final int equation, source, destination;

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

class Blend implements IState	{
	final BlendChannel color, alpha;
	final frame.Color refValue;
	
	Blend( this.color, this.alpha, this.refValue );
	Blend.none(): this( null, null, null );

	void activate( final dom.WebGLRenderingContext gl ){
		if (color!=null)	{
			gl.enable(	dom.WebGLRenderingContext.BLEND );
			if (alpha==null || color.equation == alpha.equation)
				gl.blendEquation( color.equation );
			else
				gl.blendEquationSeparate( color.equation, alpha.equation );
			if (color.source == alpha.source && color.destination == alpha.destination)
				gl.blendFunc( color.source, color.destination );
			else
				gl.blendFuncSeparate( color.source, color.destination, alpha.source, alpha.destination );
			if (refValue != null)
				gl.blendColor( refValue.r, refValue.g, refValue.b, refValue.a );
		}else
			gl.disable( dom.WebGLRenderingContext.BLEND );
	}
}


class PixelMask implements IState	{
	final bool depth;
	final int stencilFront,stencilBack;
	final bool red,green,blue,alpha;
	
	PixelMask( this.depth, this.stencilFront, this.stencilBack, this.red, this.green, this.blue, this.alpha );
	PixelMask.withColor( bool d, int sf, int sb ): this( d,sf,sb,true,true,true,true );
	PixelMask.all(): this( true, -1,-1, true,true,true,true );
	
	bool hasColor()	=> red || green || blue || alpha;
	
	void activate( final dom.WebGLRenderingContext gl ){
		gl.depthMask( depth );
		// stencil
		if (stencilFront!=stencilBack)	{
			gl.stencilMaskSeparate( dom.WebGLRenderingContext.FRONT, stencilFront );
			gl.stencilMaskSeparate( dom.WebGLRenderingContext.BACK, stencilBack );
		}else
			gl.stencilMask( stencilFront );
		// color
		gl.colorMask( red, green, blue, alpha );
	}
}


class Stencil	{
	final int function, refValue, mask;
	final int opFail, opDepthFail, opPass;
	
	Stencil( String funCode, this.refValue, this.mask, String fail, String depthFail, String pass ):
		function = comparison[funCode],		opFail = operation[fail],
		opDepthFail = operation[depthFail], opPass = operation[pass]{
		assert (function!=null && opFail!=null && opDepthFail!=null && opPass!=null );
	}

	void activate( final dom.WebGLRenderingContext gl, int face ){
		gl.stencilFuncSeparate( face, function, refValue, mask );
		gl.stencilOpSeparate( face, opFail, opDepthFail, opPass );
	}
}


class PixelTest implements IState	{
	final int depthFun;
	final Stencil front, back;
	
	PixelTest( String depthFunCode, this.front, this.back ):
		depthFun = depthFunCode!=null ? comparison[depthFunCode] : null	{
		assert (depthFunCode==null || depthFun != null);
	}
	PixelTest.none(): this( null, null, null );

	void activate( final dom.WebGLRenderingContext gl ){
		// set depth
		if (depthFun != null)	{
			gl.enable(	dom.WebGLRenderingContext.DEPTH_TEST );
			gl.depthFunc( depthFun );
		}else
			gl.disable(	dom.WebGLRenderingContext.DEPTH_TEST );
		// set front and back stencil
		if (front != null && back != null)	{
			gl.enable(	dom.WebGLRenderingContext.STENCIL_TEST );
			if (front != back)	{
				front	.activate( gl, dom.WebGLRenderingContext.FRONT );
				back	.activate( gl, dom.WebGLRenderingContext.BACK );
			}else
				front	.activate( gl, dom.WebGLRenderingContext.FRONT_AND_BACK );
		}else
			gl.disable(	dom.WebGLRenderingContext.STENCIL_TEST );
	}
}

class Offset implements IState	{
	final double factor, units;
	
	Offset( this.factor, this.units );
	Offset.none(): this(0.0,0.0);
	
	void activate( final dom.WebGLRenderingContext gl ){
		if (factor!=0.0 || units!=0.0)	{
			gl.enable(	dom.WebGLRenderingContext.POLYGON_OFFSET_FILL );
			gl.polygonOffset( factor, units );
		}else
			gl.disable(	dom.WebGLRenderingContext.POLYGON_OFFSET_FILL );
	}
}


class RasterState implements IState	{
	final Face face;
	final Blend blend;
	final PixelMask mask;
	final PixelTest test;
	final Offset offset;
	
	RasterState( this.face, this.blend, this.mask, this.test, this.offset );
	RasterState.initial(): this( new Face.ccw(), new Blend.none(),
		new PixelMask.all(), new PixelTest.none(), new Offset.none() );
	
	void activate( final dom.WebGLRenderingContext gl ){
		face.activate( gl );
		blend.activate( gl );
		mask.activate( gl );
		test.activate( gl );
		offset.activate( gl );
	}
}


class Target	{
	final frame.Buffer buffer;
	final frame.Rect viewport, scissor;
	
	Target( this.buffer, this.viewport, this.scissor );
	
	void activate( final frame.Control control ){
		control.bind( buffer );
		control.viewport(viewport);
		control.scissor(scissor);
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


class CallDraw implements ICall	{
	// data
	final m.Mesh mesh;
	// program
	final shade.Effect shader;
	final Map<String,Object> parameters;
	// environment
	final RasterState state;
	final Target target;
	// constructor
	CallDraw(this.mesh, this.shader, this.state, this.target):
		parameters = new Map<String,Object>();
	// implementation
	bool issue( final frame.Control control ){
		target.activate( control );
		state.activate( control.gl );
		mesh.draw( control.gl, shader, parameters );
		return true;
	}
}

class CallClear implements ICall	{
	// environment
	final PixelMask pixelMask;
	final Target target;
	// values
	final frame.Color valueColor;
	final double valueDepth;
	final int valueStencil;
	// constructor
	CallClear( this.pixelMask, this.target, this.valueColor, this.valueDepth, this.valueStencil );
	// implementation
	bool issue( final frame.Control control ){
		target.activate( control );
		pixelMask.activate( control.gl );
		control.clear(
			pixelMask.hasColor()		? valueColor	: null,
			pixelMask.depth				? valueDepth	: null,
			pixelMask.stencilFront != 0	? valueStencil	: null);
		return true;
	}
}

class CallBlit implements ICall	{}

class CallTransform implements ICall	{}



class Process	{
	final List<ICall> batches;
	
	Process(): batches = new List<ICall>();
	
	void draw(IEntity ent, Target target)	{
		final CallDraw call = new CallDraw( ent.getMesh(), ent.getEffect(), ent.getState(), target );
		ent.fillData( call.parameters );
		batches.add(call);
	}
	
	void clear( PixelMask mask, Target target, frame.Color vColor, double vDepth, int vStencil ){
		batches.add(new CallClear( mask, target, vColor, vDepth, vStencil ));
	}
	
	int abort()	{
		int num = batches.length;
		batches.clear();
		return num;
	}

	int flush(final dom.WebGLRenderingContext gl)	{
		final frame.Control control = new frame.Control(gl);
		for (final ICall call in batches)	{
			call.issue(control);
		}
		return abort();
	}
}
