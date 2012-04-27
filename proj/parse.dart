#library('kri:parse');
#import('dart:html',	prefix:'dom');
#import('frame.dart',	prefix:'frame');
#import('rast.dart');
#import('ren.dart',		prefix:'ren');
#import('shade.dart',	prefix:'shade');


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
	final String prefix;
	Parse( this.prefix );

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
			case 'false':	case '0':	return false;
			case 'true':	case '1':	return true;
			case null:	return fallback;
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
		bool coverage = false, invert = false;
		int coverValue = 0;
		bool alpha = readBool(root,'alpha',false);
		for (final dom.Element el in root.nodes)	{
			if (el is! dom.Element)
				continue;
			assert( el.tagName == "${prefix}:Coverage" );
			coverage = true;
			coverValue = readInt(el,'value',coverValue);
			invert = readBool(el,'invert',invert);
			break;
		}
		return new MultiSample( alpha, coverage, coverValue, invert );
	}
	
	
	StencilChannel rastStencilChannel( final dom.Element root ){
		String func=''; int ref=0, mask=-1;
		String onFail='',onDepthFail='',onPass='';
		for (final dom.Element el in root.nodes)	{
			if (el is! dom.Element)
				continue;
			switch (el.tagName)	{
				case "${prefix}:Test":
					func		= el.attributes['func'];
					ref			= readInt(el,'ref',ref);
					mask		= readInt(el,'mask',mask);
					break;
				case "${prefix}:Operation":
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
			assert( el.tagName == "${prefix}:Channel" );
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
			if (el.tagName == "${prefix}:Ref")	{
				ref = frameColor(el);
				continue;
			}
			assert( el.tagName == "${prefix}:Channel" );
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
				case "${prefix}:Primitive"	: b.primitive	= rastPrimitive		(el); break;
				case "${prefix}:Offset"		: b.offset		= rastOffset		(el); break;
				case "${prefix}:Scissor"	: b.scissor		= rastScissor		(el); break;
				case "${prefix}:MultiSample": b.multiSample = rastMultiSample	(el); break;
				case "${prefix}:Stencil"	: b.stencil		= rastStencil		(el); break;
				case "${prefix}:Depth"		: b.depth		= rastDepth			(el); break;
				case "${prefix}:Blend"		: b.blend		= rastBlend			(el); break;
				case "${prefix}:Mask"		: b.mask		= rastMask			(el); break;
				default: print("Unknown XML tag: ${el.tagName}");
			}
		}
		return b.end();
	}
	
	shade.Effect matProgram( final dom.Element root, final shade.Manager man ){
		final List<shade.Unit> units = new List<shade.Unit>();
		List<String> pathList = new List<String>();
		for (final dom.Element el in root.nodes)	{
			if (el is! dom.Element)
				continue;
			assert( el.tagName=="{prefix}:Object" );
			final String stype = el.attributes['type'];
			final int itype =
				(stype=='vertex' 	? dom.WebGLRenderingContext.VERTEX_SHADER	: 
				(stype=='fragment'	? dom.WebGLRenderingContext.FRAGMENT_SHADER	: 
				0));
			final String path = el.attributes['path'];
			shade.Unit un = null;
			if (path!=null)	{
				if (pathList!=null)
					pathList.add(path);
				un = man.loadUnit(path,itype);
			}else	{
				pathList = null;
				un = new shade.Unit( man.gl, itype, el.nodes[0].text );
			}
			units.add(un);
		}
		return pathList != null ? man.assemble( pathList ):
			new shade.Effect( man.gl, units );
	}
	
	ren.Technique matTechnique( final dom.Element root, final shade.Manager man ){
		State state = null;
		shade.Effect prog = null;
		for (final dom.Element el in root.nodes)	{
			if (el is! dom.Element)
				continue;
			switch (el.tagName)	{
				case "${prefix}:State":		state = rast(el);			break;
				case "${prefix}:Program":	prog = matProgram(el,man);	break;
				default: print("Unknown technique node: ${el.tagName}");
			}
		}
		return new ren.Technique(state,prog);
	}
	
	ren.Material material( final dom.Element root ){
		final ren.Material mat = new ren.Material( root.attributes['name'] );
		return mat;
	}
}
