//%meta getFinalColor

varying mediump vec3 v_Normal;

void main()	{
	mediump vec3 n = normalize(v_Normal);
	gl_FragColor = getFinalColor(n);
}
