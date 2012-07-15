struct Space	{ vec4 pos,rot; };

//rotate vector
vec3 qrot(vec4 q, vec3 v)	{
	return v + 2.0*cross(q.xyz, cross(q.xyz,v) + q.w*v);
}

//combine quaternions
vec4 qmul(vec4 a, vec4 b)	{
	return vec4(cross(a.xyz,b.xyz) + a.xyz*b.w + b.xyz*a.w, a.w*b.w - dot(a.xyz,b.xyz));
}

//inverse quaternion
vec4 qinv(vec4 q)	{
	return vec4(-q.xyz,q.w);
}

//from axis, angle
vec4 qvec(vec3 axis, float angle)	{
	return vec4( axis*sin(0.5*angle), cos(0.5*angle) );
}

//combine transformations
Space transCombine(Space sa, Space sb)	{
	vec4 pos = vec4( qrot(sb.rot,sa.pos.xyz), sb.pos.w*sa.pos.w );
	return Spatial( pos, qmul(sb.rot,sa.rot) );
}

//transform by Spatial forward
vec3 transForward(vec3 v, Space s)	{
	return qrot(s.rot, v*s.pos.w) + s.pos.xyz;
}

//transform by Spatial inverse
vec3 transInverse(vec3 v, Space s)	{
	return qrot( vec4(-s.rot.xyz, s.rot.w), (v-s.pos.xyz)/s.pos.w );
}
