<table><tr><td>
<h2>Kri-Web</h2>
<blockquote>It stands in your way...<br>
only when you want to shoot yourself in the foot!<br>
<hr />
<h3>Functional</h3>
<i>Kri</i> takes functional programming style seriously. Instead of just wrapping <i>OpenGL</i> state into user-friendly names, <i>Kri</i> goes farther by providing a functional interface to the graphics context.</blockquote>

There are no global mutable objects for you to care about, and no drawing states to miss. Everything needed by a function, such as a draw call, is passed in its arguments.<br>
<br>
Math objects are immutable, making expressions easily readable and predictable. All low-level state blocks (<i>Depth</i>, <i>Stencil</i>, <i>Blending</i>, etc) are also immutable. Most of the functionality is covered by unit tests.<br>
<br>
<h3>3D Engine</h3>
<i>Kri</i> provides a complete pipeline of resources going from Blender to the screen of your <i>WebGL</i>-supporting browser. Assets are exported using <i>Python</i> plugin for <i>Blender 2.6</i>, and loaded asynchronously while the page is rendering.<br>
<br>
<i>Kri</i> protects you by verifying, on each draw call, that the shader gets what it needs, without any assumptions about the content. This includes finding matching vertex attributes in a mesh, and uniforms in a parameter block.<br>
<br>
Graphics context is transparently cached, optimizing the number of state switches for you. It is also automatically verified, quickly revealing de-synchronization issues of the cache.<br>
<br>
<h3>for Web</h3>
Finally, <i>Kri</i> is designed for ultimate portability. All you need to see the action is a device with <i>OpenGL ES 2.0</i> support, and a good browser. No OS requirements, no hardware architecture support, no need to build any code!<br>
<br>
It is written in <i>Dart</i>, an emerging programming language from <i>Google</i> that can effectively replace <i>JavaScript</i>. This allows <i>Kri</i> code to be small, modular, and expressive.<br>
</td><td width='10%'></td><td>
<a href='http://www.dartlang.org'><img src='http://www.shadihania.com/wp-content/uploads/2011/10/Dart-Language-Logo.jpg' /></a>

<a href='http://www.khronos.org/webgl/'><img src='http://upload.wikimedia.org/wikipedia/commons/3/39/WebGL_logo.png' /></a>

<a href='http://www.khronos.org/opengles/'><img src='http://db-in.com/blog/wp-content/uploads/2011/01/opengl-es-logo.jpg' /></a>

<a href='http://www.blender.org'><img src='http://www.blender.org/typo3temp/pics/f3ef19cb46.jpg' /></a>
</td></tr>
</table>

---

Thank you for the interest in KRI tech. I'm open to any kind of cooperation.