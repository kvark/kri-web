attribute vec3	a_position;
attribute vec4	a_quaternion;
attribute float	a_handedness;
attribute vec2	a_tex0;
attribute vec4	a_bone_ids;
attribute vec4	a_bone_weights;

varying vec2 v_tex;
varying vec3 v_normal, v_light, v_camera;
varying vec4 v_color;

uniform mat4 mx_mvp, mx_model;
uniform vec4 pos_camera, pos_light;

struct Spatial	{ vec4 pos, rot; };
uniform Spatial bones[20];


//rotate vector
vec3 qrot(vec4 q, vec3 v)	{
	return v + 2.0*cross(q.xyz, cross(q.xyz,v) + q.w*v);
}


void main()	{
	vec3 normal = qrot(a_quaternion,vec3(0.0,0.0,1.0));
	normal.x *= a_handedness;
	v_normal = mat3(mx_model) * normal;
	//v_normal = normal;
	v_tex = a_tex0;
	vec4 vw = mx_model * vec4(a_position,1.0);
	v_light = (pos_light - vw).xyz;
	v_camera = (pos_camera - vw).xyz;
	gl_Position = mx_mvp * vec4(a_position,1.0);
/*	v_tex = vec2(0.0);
	v_normal = v_light = v_camera = vec3(0.0);
	vec3 n = a_normal;
	n = qrot(a_quaternion,vec3(0.0,0.0,1.0)) * vec3(a_handedness,1.0,1.0);
	//n = vec3(a_handedness,1.0,1.0);
	v_color = vec4(vec3(0.5) + 0.5*n,1.0);*/
}
