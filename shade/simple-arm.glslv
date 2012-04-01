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


// Quaternion routines
vec4 qinv(vec4 q)	{
	return vec4(-q.xyz,q.w);
}
vec4 qmul(vec4 a, vec4 b)	{
	return vec4(cross(a.xyz,b.xyz) + a.xyz*b.w + b.xyz*a.w, a.w*b.w - dot(a.xyz,b.xyz));
}
vec3 qrot(vec4 q, vec3 v)	{
	return v + 2.0*cross(q.xyz, cross(q.xyz,v) + q.w*v);
}
vec3 trans_for(Spatial s, vec3 v)	{
	return qrot(s.rot, v*s.pos.w) + s.pos.xyz;
}
//---

// Dual-Quaternion routines
struct DualQuat	{
	vec4 re,im;
	float scale;
};

Spatial normDq(DualQuat dq)	{
	float k = 1.0 / length(dq.re);
	vec4 tmp = qmul( dq.im, qinv(dq.re) );
	vec4 pos = vec4( 2.0*k*k*tmp.xyz, dq.scale );
	return Spatial( pos, k * dq.re );
}

void eval_dual_quat(inout vec4 vPos, inout vec3 vNorm)	{
	DualQuat dq = DualQuat( vec4(0.0), vec4(0.0), 0.0 );
	for(int i=0; i<4; ++i)	{
		int bid = int(a_bone_ids[i]+0.5);
		float w = a_bone_weights[i];
		Spatial s = bones[bid];
		vec4 pos = vec4(0.5 * s.pos.xyz, 0.0);
		dq.re += w * s.rot;
		dq.im += w * qmul( pos, s.rot );
		dq.scale += w * s.pos.w;
	}
	Spatial sp = normDq(dq);
	vPos = vec4( trans_for( sp, vPos.xyz ), 1.0 );
	vNorm = qrot( sp.rot, vNorm );
}
//---


void eval_skeleton(inout vec4 vPos, inout vec3 vNorm)	{
	vec4 quat = vec4(0.0);
	vec4 pos = vec4(0.0);
	for(int i=0; i<4; ++i)	{
		int bid = int(a_bone_ids[i]+0.5);
		float w = a_bone_weights[i];
		Spatial s = bones[bid];
		pos += w * vec4( trans_for(s,vPos.xyz), 1.0);
		quat += w * s.rot;
	}
	vPos = pos;
	vNorm = qrot( normalize(quat), vNorm );
}


void main()	{
	vec4 pos = vec4(a_position,1.0);
	vec3 nor = a_normal;
	eval_skeleton(pos,nor);
	//eval_dual_quat(pos,nor);
	v_normal = mat3(mx_model) * nor;
	v_tex = a_tex0;
	vec4 vw = mx_model * pos;
	v_light = (pos_light - vw).xyz;
	v_camera = (pos_camera - vw).xyz;
	gl_Position = mx_mvp * pos;
	//v_color = a_bone_ids/90.0;
}
