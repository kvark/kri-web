#library('kri:parse');
#import('dart:html',	prefix:'dom');
#import('rast.dart');
#import('frame.dart',	prefix:'frame');

// Rasterization State Builder

class Build	{
	Primitive	primitive	= null;
	Offset		offset		= null;
	Scissor		scissor		= null;
	MultiSample	multiSample	= null;
	Stencil		stencil		= null;
	Depth		depth		= null;
	Blend		blend		= null;
	Mask		mask		= null;
	
	Build setOffset(double units, double factor)	{
		offset = new Offset( true, units, factor );
		return this;
	}
	Build setScissor(frame.Rect rect)	{
		scissor = new Scissor( true, rect );
		return this;
	}
	Build setMultiSample()	{
		return this;
	}
	Build setStencil(StencilChannel chan)	{
		stencil = new Stencil.simple(chan);
		return this;
	}
	Build setDepth(String funCode)	{
		depth = new Depth.on(funCode);
		return this;
	}
	Build setBlend(BlendChannel chan)	{
		blend = new Blend.simple(chan);
		return this;
	}
	Build setMask(bool color, bool depth, int stencil)	{
		mask = new Mask( depth, stencil, stencil, color, color, color, color );
		return this;
	}
	
	State end() => new State(
			primitive	!=null ? primitive	: new Primitive.ccw(),
			offset		!=null ? offset		: new Offset.none(),
			scissor		!=null ? scissor	: new Scissor.off(),
			multiSample	!=null ? multiSample: new MultiSample.off(),
			stencil		!=null ? stencil	: new Stencil.off(),
			depth		!=null ? depth		: new Depth.off(),
			blend		!=null ? blend		: new Blend.off(),
			mask		!=null ? mask		: new Mask.all() );
}


// Rasterization State Parser

final Map<String,int> faceCode = const{
	'front':	dom.WebGLRenderingContext.FRONT,
	'back':		dom.WebGLRenderingContext.BACK,
	'all':		dom.WebGLRenderingContext.FRONT_AND_BACK
};


class Parse	{
	Primitive rastPrimitive( final dom.Element root ){
		// read front type
		bool frontCw = false;
		String front = root.attributes['front'];
		switch (front)	{
			case null	:
			case 'cw'	: frontCw = true; break;
			case 'ccw'	: frontCw = false; break;
			default: print("Unknown face direction: ${front}");
		}
		// read cull face
		int cullFace = null;
		String cull = root.attributes['cull'];
		if (cull!=null)
			cullFace = faceCode[cull];
		// read line width
		String line		= root.attributes['line'];
		return new Primitive( frontCw, cullFace!=null, cullFace,
			line!=null ? Math.parseDouble(line) : 1.0 );
	}
	
	Offset rastOffset( final dom.Element root ){
		String units	= root.attributes['units'];
		String factor	= root.attributes['factor'];
		return new Offset( true,
			units!=null ? Math.parseDouble(units) : 0.0,
			factor!=null? Math.parseDouble(factor): 0.0);
	}
	
	Scissor rastScissor( final dom.Element root ){
		return null;
	}
	MultiSample rastMultiSample( final dom.Element root ){
		return null;
	}
	Stencil rastStencil( final dom.Element root ){
		return null;
	}
	Depth rastDepth( final dom.Element root ){
		return null;
	}
	Blend rastBlend( final dom.Element root ){
		return null;
	}
	Mask rastMask( final dom.Element root ){
		return null;
	}

	State rast( final dom.Element root ){
		final Build b = new Build();
		//for (final dom.Element el in root.elements)	{
		for (final dom.Element el in root.nodes)	{
			if (el is! dom.Element)
				continue;
			switch (el.tagName)	{
				case 'kri:Primitive'	: b.primitive	= rastPrimitive		(el); break;
				case 'kri:Offset'		: b.offset		= rastOffset		(el); break;
				case 'kri:Scissor'		: b.scissor		= rastScissor		(el); break;
				case 'kri:MultiSample'	: b.multiSample = rastMultiSample	(el); break;
				case 'kri:Stencil'		: b.stencil		= rastStencil		(el); break;
				case 'kri:Depth'		: b.depth		= rastDepth			(el); break;
				case 'kri:Blend'		: b.blend		= rastBlend			(el); break;
				case 'kri:Mask'			: b.mask		= rastMask			(el); break;
				default: print("Unknown XML tag: ${el.tagName}");
			}
		}
		return b.end();
	}
}
