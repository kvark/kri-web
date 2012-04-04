#library('ren');
#import('dart:html',	prefix:'dom');
#import('mesh.dart',	prefix:'m');
#import('shade.dart',	prefix:'shade');
#import('frame.dart',	prefix:'frame');


class Blending	{
	int eqColor, eqAlpha;
	int kSource, kSecond;
}

class DepthStencilColor	{
	bool depthTest, stencilTest, depthMask;
	int depthFun, stencilPassFun, stencilDepthFailFun, stencilFailFun;
	int stencilMask, stencilRefValue;
	int colorRedMask, colorGreenMask, colorBlueMask, colorAlphaMask;
}


class State	{
	final Blending blend;
	final int faceCull;
	DepthStencilColor dsc;
}


class Target	{
	final frame.Buffer buffer;
	final frame.Rect viewport, scissor;
	
	Target( this.buffer, this.viewport, this.scissor );
	
	void activate(final frame.Control control)	{
		control.bind( buffer );
		control.viewport(viewport);
		control.scissor(scissor);
	}
}


interface IEntity extends shade.IDataSource	{
	m.Mesh			getMesh();
	shade.Effect	getEffect();
	State			getState();
}

class EntityBase implements IEntity	{
	m.Mesh mesh			= null;
	shade.Effect shader	= null;
	State state			= null;
	final Map<String,Object> data;
	
	EntityBase():
		data = new Map<String,Object>();

	m.Mesh getMesh()			=> mesh;
	shade.Effect getEffect()	=> shader;
	State getState()			=> state;

	void fillData(final Map<String,Object> block)	{
		for (String key in block.getKeys())
			data[key] = block[key];
	}
}


class Material implements shade.IDataSource	{
	State state;
	final shade.Effect effect;
	final Map<String,Object> data;
	
	void fillData(final Map<String,Object> block)	{
		for (String key in block.getKeys())
			data[key] = block[key];
	}
}


interface ICall	{
	bool issue( final dom.WebGLRenderingContext gl );
}

class CallDraw implements ICall	{
	// data
	final m.Mesh mesh;
	// program
	final shade.Effect shader;
	final Map<String,Object> parameters;
	// environment
	final State state;
	final Target target;
	// constructor
	CallDraw(this.mesh, this.shader, this.state, this.target):
		parameters = new Map<String,Object>();
	// implementation
	bool issue( final dom.WebGLRenderingContext gl ){
		//activate state & target
		mesh.draw( gl, shader, parameters );
		return true;
	}
}

class CallClear implements ICall	{
	// environment
	final State state;
	final Target target;
	// values
	final frame.Color valueColor;
	final double valueDepth;
	final int valueStencil;
	// constructor
	CallClear( this.state, this.target, this.valueColor, this.valueDepth, this.valueStencil );
	// implementation
	bool issue( final dom.WebGLRenderingContext gl ){
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
	
	void clear( State state, Target target, frame.Color vColor, double vDepth, int vStencil ){
		batches.add(new CallClear( state, target, vColor, vDepth, vStencil ));
	}
	
	int abort()	{
		int num = batches.length;
		batches.clear();
		return num;
	}

	int flush(final dom.WebGLRenderingContext gl)	{
		for (final ICall call in batches)	{
			call.issue(gl);
		}
		return abort();
	}
}
