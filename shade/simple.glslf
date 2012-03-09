uniform lowp	vec4 u_color;
uniform sampler2D t_main;

varying lowp	vec2 v_tex;
varying highp	vec3 v_normal, v_light, v_camera;

const lowp float shininess	= 50.0;
const lowp float ambient = 0.2;
const lowp vec3 color_diffuse	= vec3(1.0,1.0,1.0);
const lowp vec3 color_specular	= vec3(1.0,1.0,1.0);


void main()	{
	highp vec3 normal = normalize(v_normal);
	highp float kdiff = dot( normal, normalize(v_light) );
	highp float kspec = dot( normal, normalize(v_light+v_camera) );
	highp float xd = max(0.0,kdiff) + ambient;
	highp float xs = pow(max(0.01,kspec),shininess);
	highp vec4 sample = texture2D(t_main,v_tex);
	lowp vec3 color = xd*color_diffuse*sample.zyx + xs*color_specular;
	
	gl_FragColor = vec4( color, sample.a );
	//gl_FragColor = vec4(v_tex, 0.0, 1.0);
	//gl_FragColor = u_color;
}
