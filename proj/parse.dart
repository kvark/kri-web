#library('kri:parse');
#import('rast.dart');
#import('frame.dart',	prefix:'frame');


class Build	{
	Primitive	_primitive	= null;
	Offset		_offset		= null;
	Scissor		_scissor	= null;
	MultiSample	_multi		= null;
	Stencil		_stencil	= null;
	Depth		_depth		= null;
	Blend		_blend		= null;
	Mask		_mask		= null;
	
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
		_mask = new Mask( depth, stencil, stencil, color, color, color, color );
		return this;
	}
	
	State end() => new State(
			_primitive	!=null ? _primitive	: new Primitive.ccw(),
			_offset		!=null ? _offset	: new Offset.none(),
			_scissor	!=null ? _scissor	: new Scissor.off(),
			_multi		!=null ? _multi		: new MultiSample.off(),
			_stencil	!=null ? _stencil	: new Stencil.off(),
			_depth		!=null ? _depth		: new Depth.off(),
			_blend		!=null ? _blend		: new Blend.off(),
			_mask		!=null ? _mask		: new Mask.all() );
}
