attribute vec3 a_Position;

uniform mat4 mx_Mvp;

void main()	{
	vec3 pos = a_Position;
	//%modify pos
	gl_Position = mx_Mvp * vec4(pos,1.0);
}
