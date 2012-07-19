uniform lowp		vec4 u_Color;
uniform sampler2D	t_Main;

varying mediump	vec2 v_Tex;
varying mediump	vec3 v_Light, v_Camera;
varying mediump	vec4 v_Color;

const lowp float shininess	= 50.0;
const lowp float ambient = 0.2;
const lowp vec3 colorDiffuse	= vec3(1.0,1.0,1.0);
const lowp vec3 colorSpecular	= vec3(1.0,1.0,1.0);


//%meta getAlpha getFinalColor

lowp float getAlpha()	{
	return texture2D(t_Main,v_Tex).a;
}

lowp vec4 getFinalColor(mediump vec3 normal)	{
	//return vec4(v_Tex.xy,1.0,1.0);
	mediump float kdiff = dot( normal, normalize(v_Light) );
	mediump float kspec = dot( normal, normalize(v_Light + v_Camera) );
	mediump float xd = max(0.0,kdiff) + ambient;
	mediump float xs = pow(max(0.01,kspec),shininess);
	lowp vec4 sample = texture2D(t_Main,v_Tex);
	lowp vec3 color = xd*colorDiffuse*sample.zyx + xs*colorSpecular;
	return vec4( color, sample.a );
}
