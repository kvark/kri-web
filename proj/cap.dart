#library('kri:cap');
#import('dart:html',	prefix:'dom');


class System	{
	final int nVertexAttribs;
	final int nVertexUniformVectors;
	final int nFragmentUniformVectors;
	final int nVaryingVectors;
	final int nCombinedTextureUnits;
	final int nVertexTextureUnits;
	final int nTextureUnits;
	
	final int nRenderbufferSize;
	final int nTextureSize;
	//final int nCubeTextureSize;
	final int nViewportDims;
	
	//final List<int> compressedTextureFormats;
	//final List<int> shaderBinaryFormats;
	//final bool shaderCompiler;

	//final String extensions;
	final String renderer;
	final String shadingLanguageVersion;
	final String vendor;
	final String version;
	
	System( final dom.WebGLRenderingContext gl ):
		nVertexAttribs			= gl.getParameter( dom.WebGLRenderingContext.MAX_VERTEX_ATTRIBS ),
		nVertexUniformVectors	= gl.getParameter( dom.WebGLRenderingContext.MAX_VERTEX_UNIFORM_VECTORS ),
		nFragmentUniformVectors	= gl.getParameter( dom.WebGLRenderingContext.MAX_FRAGMENT_UNIFORM_VECTORS ),
		nVaryingVectors			= gl.getParameter( dom.WebGLRenderingContext.MAX_VARYING_VECTORS ),
		nCombinedTextureUnits	= gl.getParameter( dom.WebGLRenderingContext.MAX_COMBINED_TEXTURE_IMAGE_UNITS ),
		nVertexTextureUnits		= gl.getParameter( dom.WebGLRenderingContext.MAX_VERTEX_TEXTURE_IMAGE_UNITS ),
		nTextureUnits			= gl.getParameter( dom.WebGLRenderingContext.MAX_TEXTURE_IMAGE_UNITS ),

		nRenderbufferSize		= gl.getParameter( dom.WebGLRenderingContext.MAX_RENDERBUFFER_SIZE ),
		nTextureSize			= gl.getParameter( dom.WebGLRenderingContext.MAX_TEXTURE_SIZE ),
		//nCubeTextureSize		= gl.getParameter( dom.WebGLRenderingContext.MAX_CUBE_TEXTURE_SIZE ),
		nViewportDims			= gl.getParameter( dom.WebGLRenderingContext.MAX_VIEWPORT_DIMS ),
	
		//compressedTextureFormats	= gl.getParameter( dom.WebGLRenderingContext.COMPRESSED_TEXTURE_FORMATS ),
		//shaderBinaryFormats		= gl.getParameter( dom.WebGLRenderingContext.SHADER_BINARY_FORMATS ),
		//shaderCompiler				= gl.getParameter( dom.WebGLRenderingContext.SHADER_COMPILER ),
		
		//extensions			= gl.getParameter( dom.WebGLRenderingContext.EXTENSIONS ),
		renderer				= gl.getParameter( dom.WebGLRenderingContext.RENDERER ),
		shadingLanguageVersion	= gl.getParameter( dom.WebGLRenderingContext.SHADING_LANGUAGE_VERSION ),
		vendor					= gl.getParameter( dom.WebGLRenderingContext.VENDOR ),
		version					= gl.getParameter( dom.WebGLRenderingContext.VERSION )
	{}
	
	String toString() => "Vendor:${vendor}, Version:${version}, Renderer:${renderer}"
		"\nUniforms vectors: vertex=${nVertexUniformVectors}, fragment=${nFragmentUniformVectors}";
}
