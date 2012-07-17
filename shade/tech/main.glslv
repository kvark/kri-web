attribute vec3 a_Position, a_Normal;

uniform mat4 mx_Mvp;

void main()	{
	vec3 pos = a_Position;
	vec3 nor = a_Normal;
	//%modify pos nor
	initMaterial( pos, mat3(nor,nor,nor) );
	gl_Position = mx_Mvp * vec4(pos,1.0);
}
