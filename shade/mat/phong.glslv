attribute vec2	a_Tex0;

varying vec2 v_Tex;
varying vec3 v_Normal, v_Light, v_Camera;

uniform vec4 u_PosCamera, u_PosLight;


void initMaterial(vec3 position)	{
	v_Normal = vec3(0.0,0.0,1.0);
	v_Tex = a_Tex0;
	v_Light = u_PosLight.xyz - position;
	v_Camera = u_PosCamera.xyz - position;
}
