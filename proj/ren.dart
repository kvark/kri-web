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


class Face implements IState	{
	final bool front, back;
	
	Face( this.front, this.back );
	
	void activate( final dom.WebGLRenderingContext gl ){
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
	final int equation, source, dest;
	BlendChannel( this.equation, this.source, this.dest );
}

class Blend implements IState	{
	final BlendChannel color, alpha;
	final frame.Color refValue;
	
	Blend( this.color, this.alpha, this.refValue );

	void activate( final dom.WebGLRenderingContext gl ){
		if (color!=null && alpha!=null)	{
			gl.enable(	dom.WebGLRenderingContext.BLEND );
			if (color.equation == alpha.equation)
				gl.blendEquation( color.equation );
			else
				gl.blendEquationSeparate( color.equation, alpha.equation );
			if (color.source == alpha.source && color.dest == alpha.dest)
				gl.blendFunc( color.source, color.dest );
			else
				gl.blendFuncSeparate( color.source, color.dest, alpha.source, alpha.dest );
			if (refValue != null)
				gl.blendColor( refValue.r, refValue.g, refValue.b, refValue.a );
		}else
			gl.disable( dom.WebGLRenderingContext.BLEND );
	}
}


class PixelMask implements IState	{
	final bool depth;
	final int stencil;
	final bool red,green,blue,alpha;
	
	PixelMask( this.depth, this.stencil, this.red, this.green, this.blue, this.alpha );
	PixelMask.withColor( bool d, int s ): this( d,s,true,true,true,true );
	PixelMask.all(): this( true, -1, true,true,true,true );
	
	bool hasColor()	=> red || green || blue || alpha;
	
	void activate( final dom.WebGLRenderingContext gl ){
		gl.depthMask( depth );
		gl.stencilMask( stencil );
		gl.colorMask( red, green, blue, alpha );
	}
}


class Stencil	{
	final int function, refValue, mask;
	final int opFail, opDepthFail, opPass;
	
	Stencil( this.function, this.refValue, this.mask, this.opFail, this.opDepthFail, this.opPass );

	void activate( final dom.WebGLRenderingContext gl, int face ){
		gl.stencilFuncSeparate( face, function, refValue, mask );
		gl.stencilOpSeparate( face, opFail, opDepthFail, opPass );
	}
}


class PixelTest implements IState	{
	final int depthFun;
	final Stencil front, back;
	
	PixelTest( this.depthFun, this.front, this.back );

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


class RasterState implements IState	{
	final Face face;
	final Blend blend;
	final PixelMask mask;
	final PixelTest test;
	
	RasterState( this.face, this.blend, this.mask, this.test );
	
	void activate( final dom.WebGLRenderingContext gl ){
		if (face != null)
			face.activate( gl );
		if (blend != null)
			blend.activate( gl );
		if (mask != null)
			mask.activate( gl );
		if (test != null)
			test.activate( gl );
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
			pixelMask.hasColor()	? valueColor	: null,
			pixelMask.depth			? valueDepth	: null,
			pixelMask.stencil != 0	? valueStencil	: null);
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
