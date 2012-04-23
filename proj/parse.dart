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
	int readInt( dom.Element root, String name, int fallback )	{
		String str = root.attributes[name];
		return str!=null ? Math.parseInt(str) : fallback;
	}
	double readDouble( dom.Element root, String name, double fallback )	{
		String str = root.attributes[name];
		return str!=null ? Math.parseDouble(str) : fallback;
	}
	bool readBool( dom.Element root, String name, bool fallback )	{
		String str = root.attributes[name];
		switch (str)	{
			case 'true':	return true;
			case 'false':	return false;
			case null:		return fallback;
			default: print("Unknown bool: ${str}");
				return fallback;
		}
	}
	
	frame.Color frameColor( final dom.Element root )=>
		new frame.Color(
			readDouble(root,'r',0.0),
			readDouble(root,'g',0.0),
			readDouble(root,'b',0.0),
			readDouble(root,'a',0.0)
			);

	
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
		// return
		return new Primitive( frontCw, cullFace!=null, cullFace,
			readDouble( root, 'lineWidth', 1.0 ));
	}
	
	
	Offset rastOffset( final dom.Element root ) =>
		new Offset( true,
			readDouble(root, 'units', 0.0),
			readDouble(root, 'factor', 0.0)
			);
	
	
	Scissor rastScissor( final dom.Element root ) =>
		new Scissor( true, new frame.Rect(
			readInt(root,'x',0),
			readInt(root,'y',0),
			readInt(root,'w',1),
			readInt(root,'h',1)
			));
	
	
	MultiSample rastMultiSample( final dom.Element root ){
		return null;
	}
	
	
	StencilChannel rastStencilChannel( final dom.Element root ){
		String func=''; int ref=0, mask=-1;
		String onFail='',onDepthFail='',onPass='';
		for (final dom.Element el in root.nodes)	{
			if (el is! dom.Element)
				continue;
			switch (el.tagName)	{
				case 'kri:Test':
					func		= el.attributes['func'];
					ref			= readInt(el,'ref',ref);
					mask		= readInt(el,'mask',mask);
					break;
				case 'kri:Operation':
					onFail		= el.attributes['fail'];
					onDepthFail	= el.attributes['depthFail'];
					onPass		= el.attributes['pass'];
					break;
			}
		}
		return new StencilChannel( func,ref,mask, onFail,onDepthFail,onPass );
	}
	
	Stencil rastStencil( final dom.Element root ){
		StencilChannel front=null, back=null;
		for (final dom.Element el in root.nodes)	{
			if (el is! dom.Element)
				continue;
			assert( el.tagName == 'kri:Channel' );
			String face = el.attributes['face'];
			StencilChannel chan = rastStencilChannel(el);
			switch (face)	{
				case 'front':	assert( front==null );
					front=chan;	break;
				case 'back':	assert( back==null );
					back=chan;	break;
				case 'all': case null:
					assert( front==null && back==null );
					front=back=chan; break;
				default: print("Unknown stencil channel: ${face}");
			}
		}
		assert( front!=null && back!=null );
		return new Stencil( true, front, back );
	}
	

	Depth rastDepth( final dom.Element root ) =>
		new Depth.on( root.attributes['func'] );
	

	BlendChannel rastBlendChannel( final dom.Element root )	{
		String s = root.attributes['source'];
		String d = root.attributes['destination'];
		String e = root.attributes['equation'];
		switch (e)	{
			case 's+d':	case 'd+s':
				return new BlendChannel.add(s,d);
			case 's-d':
				return new BlendChannel.sub(s,d);
			case 'd-s':
				return new BlendChannel.revSub(s,d);
			default: print("Unknown blend equation: ${e}");
				return null;
		};
	}

	Blend rastBlend( final dom.Element root ){
		BlendChannel color=null, alpha=null;
		frame.Color ref = new frame.Color.black();
		for (final dom.Element el in root.nodes)	{
			if (el is! dom.Element)
				continue;
			if (el.tagName == 'kri:Ref')	{
				ref = frameColor(el);
				continue;
			}
			assert( el.tagName == 'kri:Channel' );
			String on = el.attributes['on'];
			BlendChannel chan = rastBlendChannel(el);
			switch (on)	{
				case 'color':	assert( color==null );
					color=chan;	break;
				case 'alpha':	assert( alpha==null );
					alpha=chan;	break;
				case 'both': case null:
					assert( color==null && alpha==null );
					color=alpha=chan; break;
				default: print("Unknown blend channel: ${on}");
			}
		}
		assert( color!=null && alpha!=null && ref!=null );
		return new Blend( true, color, alpha, ref );
	}
	

	Mask rastMask( final dom.Element root ){
		int sf = readInt(root,'stencilFront',-1);
		int sb = readInt(root,'stencilBack',-1);
		bool d = readBool(root,'depth',true);
		String color	= root.attributes['color'];
		// return
		return color!=null ?
			new Mask.fromString	(sf,sb,d,color) :
			new Mask.withColor	(sf,sb,d);
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
