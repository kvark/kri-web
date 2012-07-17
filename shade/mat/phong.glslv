attribute vec2	a_Tex0;

varying vec2 v_Tex;
varying vec3 v_Normal, v_Light, v_Camera;

uniform mat4 mx_Model;
uniform vec4 u_PosCamera, u_PosLight;


void initMaterial(vec3 position, mat3 TBN)	{
	v_Normal = mat3(mx_Model) * TBN[2];
	v_Tex = a_Tex0;
	vec4 vw = mx_Model * vec4(position,1.0);
	v_Light = (u_PosLight - vw).xyz;
	v_Camera = (u_PosCamera - vw).xyz;
}
