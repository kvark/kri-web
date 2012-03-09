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
	final frame.Rect viewport;
	final int faceCull;
	DepthStencilColor dsc;
}


class Call	{
	final State state;
	final m.Mesh mesh;
	final shade.Instance shader;
}
