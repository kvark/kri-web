attribute vec3	a_position;
attribute vec3	a_normal;
attribute vec2	a_tex0;
attribute vec4	a_bone_ids;
attribute vec4	a_bone_weights;

varying vec2 v_tex;
varying vec3 v_normal, v_light, v_camera;
varying vec4 v_color;

uniform mat4 mx_mvp, mx_model;
uniform vec4 pos_camera, pos_light;

struct Spatial	{ vec4 pos,rot; };
uniform Spatial bones[90];


Spatial eval_skeleton()	{
	Spatial rez = Spatial( vec4(0.0), vec4(0.0) );
	for(int i=0; i<4; ++i)	{
		int bid = int(a_bone_ids[i]+0.5);
		float w = a_bone_weights[i];
		Spatial sp = bones[bid];
		rez.pos += w * sp.pos;
		rez.rot += w * sp.rot;
	}
	rez.rot = normalize(rez.rot);
	return rez;
}


void main()	{
	Spatial pose = eval_skeleton();
	vec4 pos = vec4(a_position + pose.pos.xyz,1.0);
	//vec4 pos = vec4(a_position,1.0);
	v_normal = mat3(mx_model) * a_normal;
	v_tex = a_tex0;
	vec4 vw = mx_model * pos;
	v_light = (pos_light - vw).xyz;
	v_camera = (pos_camera - vw).xyz;
	gl_Position = mx_mvp * pos;
	//v_color = a_bone_ids/90.0;
}
