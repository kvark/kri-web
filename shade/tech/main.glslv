attribute vec3 a_Position, a_Normal;

uniform mat4 mx_Model, mx_ViewProj;

void main()	{
	vec3 pos = a_Position;
	vec3 nor = a_Normal;
	//%modify pos nor
	vec4 wp = mx_Model * vec4(pos,1.0);
	initMaterial( wp.xyz );
	gl_Position = mx_ViewProj * wp;
}
