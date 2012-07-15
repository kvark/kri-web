attribute vec4	a_BoneIndex;
attribute vec4	a_BoneWeight;

struct Space	{ vec4 pos,rot; };
uniform Space bones[90];


vec3 qrot(vec4 q, vec3 v)	{
	return v + 2.0*cross(q.xyz, cross(q.xyz,v) + q.w*v);
}
vec3 transForward(Spatial s, vec3 v)	{
	return qrot(s.rot, v*s.pos.w) + s.pos.xyz;
}


Space trans = Space( vec4(0.0), vec4(0.0) ); 

vec3 modifyPosition(vec3 pos)	{
	for(int i=0; i<4; ++i)	{
		int bid = int(a_BoneIndex[i]+0.5);
		float w = a_BoneWeight[i];
		Space s = bones[bid];
		trans.pos += w * vec4( transForward(s,pos), 1.0);
		trans.quat += w * s.rot;
	}
	trans.quat = normalize( trans.quat );
	return trans.pos;
}

vec3 modifyVector(vec3 vector)	{
	return qrot( trans.quat, vector );
}
