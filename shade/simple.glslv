attribute vec3 a_position;
attribute vec3 a_normal;
attribute vec2 a_tex0;

varying vec2 v_tex;
varying vec3 v_normal, v_light, v_camera;

uniform mat4 mx_mvp, mx_model;
uniform vec4 pos_camera, pos_light;


void main()	{
	v_normal = mat3(mx_model) * a_normal;
	v_tex = a_tex0;
	vec4 vw = mx_model * vec4(a_position,1.0);
	v_light = (pos_light - vw).xyz;
	v_camera = (pos_camera - vw).xyz;
	gl_Position = mx_mvp * vec4(a_position,1.0);
}
