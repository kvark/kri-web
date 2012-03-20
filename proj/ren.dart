#library('ren');
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


class Material	{
	State state;
	final shade.Effect effect;
	final Map<String,Object> data;
}


class Call	{
	// environment
	final State state;
	final Target target;
	// data
	final m.Mesh mesh;
	// program
	final shade.Effect shader;
	final Map<String,Object> parameters;
}


class Process	{
	final List<Call> batches;
	
	void add(final Call call)	{
		batches.add(call);
	}
	
	void flush()	{
		batches.clear();
	}
}
