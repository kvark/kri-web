## Kri-Web

    It stands in your way... only when you want to shoot yourself in the foot! 

### Functional

*Kri* takes functional programming style seriously. Instead of just wrapping *OpenGL* state into user-friendly names, *Kri* goes farther by providing a functional interface to the graphics context.

There are no global mutable objects for you to care about, and no drawing states to miss. Everything needed by a function, such as a draw call, is passed in its arguments.

Math objects are immutable, making expressions easily readable and predictable. All low-level state blocks (`Depth`, `Stencil`, `Blending`, etc) are also immutable. Most of the functionality is covered by unit tests.

### 3D Engine

*Kri* provides a complete pipeline of resources going from *Blender* to the screen of your *WebGL*-supporting browser. Assets are exported using *Python* plugin for *Blender 2.6*, and loaded asynchronously while the page is rendering.

*Kri* protects you by verifying, on each draw call, that the shader gets what it needs, without any assumptions about the content. This includes finding matching vertex attributes in a mesh, and uniforms in a parameter block.

Graphics context is transparently cached, optimizing the number of state switches for you. It is also automatically verified, quickly revealing de-synchronization issues of the cache.

### for Web

Finally, *Kri* is designed for ultimate portability. All you need to see the action is a device with *OpenGL ES 2.0* support, and a good browser. No OS requirements, no hardware architecture support, no need to build any code!

It is written in *Dart*, an emerging programming language from *Google* that can effectively replace *JavaScript*. This allows *Kri* code to be small, modular, and expressive.
		

Thank you for the interest in *Kri* tech. I'm open to any kind of cooperation.
