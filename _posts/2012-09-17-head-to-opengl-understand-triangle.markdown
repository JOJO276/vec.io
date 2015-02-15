---
layout: post
title: "Head to OpenGL: Understand Triangle"
date:   2012-09-17 06:01:06
---

It's time to understand how OpenGL renders the triangle on the screen. First, I will give you a hint about how OpenGL's pipeline works.

Client & Server
---------------

OpenGL is designed with a C/S architecture.  Our OpenGL code is written as an OpenGL client, so each OpenGL API call will be passed to the OpenGL server to do some operations.

The OpenGL server is typically running in the GPU.  It has its own memory in GPU, thus most API calls will need communication between CPU and GPU.  I am going to avoid discussing the more detailed aspects of this, because I love to learn how to use the API at first.

State Machine
-------------

**Note:** I won't give you a perfect OpenGL definition.  You can find the most accurate details from the OpenGL specifications. I will only try my best to tell a story about how OpenGL works, from a OpenGL beginner's perspective.

In every book about OpenGL, you will read something like this, "OpenGL is a state machine."

So what's a state machine? I don't think I can explain it clearly to you if you haven't heard about it.  I can't even understand it when others try to give me an explanation on what a state machine is. Instead, I'd love to describe OpenGL with some simple programming skills:

```c
struct OpenGL {
  Context renderContext; // We create it with freeglut
  vec4 clearColor; // Set with glClearColor(1.0f, 1.0f, 1.0f, 1.0f)
  GLuint program; // glUseProgram()
  GLuint buffer; // glBindBuffer(GL_ARRAY_BUFFER, ..)
  ...
};
```

I assume you're familiar with the C language. The above code is my impression of OpenGL.  I see it as a big struct with many members.  Each OpenGL method call may change the struct to some state, and keep the state until other calls change it. So we:

```c
// Create the OpenGL context with a few freeglut calls
glutInit(&argc, argv);
glutInitDisplayMode(GLUT_DOUBLE | GLUT_ALPHA | GLUT_DEPTH | GLUT_STENCIL);
...

// Then we use glClearColor() to change the context's color state,
// one state among hundreds of states in the OpenGL big struct
glClearColor(1.0f, 1.0f, 1.0f, 1.0f);

// We want to clear the render window before do other rendering works,
// so we invoke the glClear() method, which will make the screen full
// of the color we set with glClearColor(). This behaviour will lasts
// until we call glClearColor() with another color value.
glClear(GL_COLOR_BUFFER_BIT);
```

As the comments say in above code, if you do something to the OpenGL big struct, the effect will last until the next time you do something to the same part of the big struct. E.g. once you call `glEnable*`, `glBind*` or some other OpenGL methods, you will set some fields in the big OpenGL struct to some values, and the values will be kept until you change them again. This is the basic and most important **OpenGL workflow** from my understanding of the OpenGL state machine.


OpenGL Pipeline
---------------

Let's go deep into more details about the OpenGL workflow and OpenGL pipeline. I'd love to follow OpenGL with these steps:


### Initialize OpenGL program and shaders ###

Once we created our OpenGL context with freeglut, we should think about initializing some basic OpenGL attributes.

```c
GLuint vertexShader = CreateShader(GL_VERTEX_SHADER, VERTEX_SHADER);
GLuint fragmentShader = CreateShader(GL_FRAGMENT_SHADER, FRAGMENT_SHADER);
sProgram = CreateProgram(vertexShader, fragmentShader);
glDeleteShader(vertexShader);
glDeleteShader(fragmentShader);
```

The code may be more readable than human language. I just created (compiled) two shaders.  Then, created an OpenGL program based on them. At last, the shaders are deleted.

More explanations about the procedure would be massive.  For the sake of brevity, OpenGL is like a C/S architecture, and the program is created at the server side.  It also needs to be compiled like our normal C code.

The two methods, `CreateShader` and `CreateProgram` are just two simple wrappers around the most common procedures to create an OpenGL program, which we will use many more times in the future.


### Ttransfer vertices to OpenGL ###

OpenGL is running on the GPU with its own memory space, so we need to transfer all data to be used by the OpenGL server. In our triangle demo, we use the following API to do it:

```c
glGenBuffers(1, &sValuesBuffer);
glBindBuffer(GL_ARRAY_BUFFER, sValuesBuffer);
glBufferData(GL_ARRAY_BUFFER, sizeof(sValues), sValues, GL_STATIC_DRAW);
glBindBuffer(GL_ARRAY_BUFFER, 0);
```

The `glGenBuffers` call will generate a buffer in OpenGL server's memory, but can't be used until we tell OpenGL how we want to use it.

We use `glBindBuffer(GL_ARRAY_BUFFER, sValuesBuffer)` to indicate that we want to use the genereated buffer as an array.

The third method `glBufferData` is where the magic happens. This method will copy `sValues` to OpenGL memory space as a `GL_ARRAY_BUFFER`. The destination of the `GL_ARRAY_BUFFER` is the `sValuesBuffer`. The state machine rocks, once you bind `sValuesBuffer` to `GL_ARRAY_BUFFER`, any later usage of `GL_ARRAY_BUFFER` will be implicitly set to `sValuesBuffer`.

The fourth line bind `GL_ARRAY_BUFFER` to 0. **0** is the default value of most states. It's not necessary to bind to 0 at this time, it's just a habit (maybe a good one).

To understand it as a C programmer, the code below has similiar effects:

```c
void *sValuesBuffer = malloc(sizeof(sValues));
float *arrayBuffer = (float *)sValuesBuffer;
memcpy(arrayBuffer, sValues, sizeof(sValues));
arrayBuffer = NULL;
```

They look like some buggy C code, but it helps us to understand how the OpenGL API works.


### Draw with the program and vertices ###

Finally, it's time to make the actual rendering.

```c
glUseProgram(sProgram);

glBindBuffer(GL_ARRAY_BUFFER, sValuesBuffer);
glEnableVertexAttribArray(sLocPosition);
glVertexAttribPointer(sLocPosition, 4, GL_FLOAT, GL_FALSE, 0, 0);
glEnableVertexAttribArray(sLocColor);
glVertexAttribPointer(sLocColor, 4, GL_FLOAT, GL_FALSE, 0, (void *)48);

glDrawArrays(GL_TRIANGLES, 0, 3);
```

To be honest with you, it's a little hard to learn OpenGL if you're a newbie to graphics programming. But if you can understand the code above, you will feel the sunshine. Also it's harder to explain it clearly to others. However, we're lucky to have [gltut's explanation](http://www.arcsynthesis.org/gltut/Basics/Tut02%20Vertex%20Attributes.html), here I will borrow some ideas from there.

At first we tell OpenGL server to use the `sProgram` to do the rendering work, 1glUseProgram(sProgram)1. Then we instruct OpenGL to draw stroke by stroke with the steps we define:

1. Bind `sValuesBuffer` to `GL_ARRAY_BUFFER`. Then any later usage of `GL_ARRAY_BUFFER` will implicitly use `sValuesBuffer`.
2. `glEnableVertexAttribArray` and `glVertexAttribPointer` combination assign some array value to vertex attribute, we will discuss the vertex attribute in next part.
3. `glDrawArrays(GL_TRIANGLES, 0, 3)` tell OpenGL to draw many triangles with 3 vertices starting from the 0 index, in this program, it will draw only one triangle, because 3 vertices can only form one tirangle in normal situation.


A Taste of a Bit Shader
-----------------------

In the previous part we give out several instructions to the OpenGL server, let it to use `sProgram` to accomplish those commands. Recall that we have linked two shaders, VERTEX\_SHADER and FRAGMENT\_SHADER, with `sProgram`. Indeed, these two shaders are the most important part of the `sProgram`, they will be executed in the OpenGL server, just like our C code compiled and executed in CPU.

The OpenGL shader has its own programming language, called OpenGL shading language, abbreviated as GLSL. GLSL's syntax is very like C's. The two most used shaders are vertex shader and fragment shader.  Although with different names, they share the same syntax.


### Vertex coordinate ###

Before getting into the shader, let's look at the coordinate system to define the vertex position. Don't take it too complex, every vertex's position is a 4 dimentional vector, (x, y, z, w). W is set to 1 by default, and we won't care it this time. x, y and z should all fall into \[-1, 1\]. Yes, you guess right, it's a percentage value.

```c
const GLfloat sValues[] = {
  0.0f, 0.5f, 0.0f, 1.0f,
  -0.5f, -0.5f, 0.0f, 1.0f,
  0.5f, -0.5f, 0.0f, 1.0f,
};
```

Compare the values above with the picture from [previous tutorial](https://vec.io/posts/head-to-opengl-hello-triangle/), you may get the point.


### Vertex shader ###

A vertex shader will be executed for every **vertex**. It's the first stage in the shading sequences. Its most important role is computing the position for each vertex while accepting various other vertex attributes and passing them to fragment shader.

```c
#define VERTEX_SHADER " \
  #version 130\n \
  in vec4 position; \
  in vec4 color; \
  smooth out vec4 vColor; \
  void main() { \
    gl_Position = position; \
    vColor = color; \
  }"
```

In the vertex shader code above, it receives two **vertex attributes**, `in vec4 position` and `in vec4 color`. It also sets the vertex position to `gl_Position`, which is a must do in every vertex shader.

How do we pass vertex attribute `position` to vertex shader? It's the result of `glVertexAttribPointer(sLocPosition, 4, GL_FLOAT, GL_FALSE, 0, 0)`, which means get `position` from the `GL_ARRAY_BUFFER` starting at index 0, and each `position` will use 4 values from the `GL_ARRAY_BUFFER`. So as the vertex attribute `color`.

We have three vertices to draw a triangle, so the above procedure will be executed for three times. To demonstrate more clearly, we can emulate this vertex shader's work with C code below:

```c
for (index = 0; index < 3; index++) {
  position = sValuesBuffer + 0 + index * 4 * 4; // float is 4 bytes length
  color = sValuesBuffer + 48 + index * 4 * 4; // float is 4 bytes length
}
```

### Fragment shader ###

A Fragment shader will be executed for every **fragment**. A **Fragment** is a different concept from vertex. While a triangle has tree vertices, it may have millions fragments. As an introduction, you can imagine a fragment as one pixel on the screen.

```c
#define FRAGMENT_SHADER " \
  #version 130\n \
  smooth in vec4 vColor; \
  void main() { \
  	gl_FragColor = vColor; \
  }"
```

In the previous vertex shader, we define `smooth out vec4 vColor`, and in this fragment shader `smooth in vec4 vColor`. The two declarations are a lot alike, and it's not a coincidence. The GLSL specifications limit you to define the same `in` attribute in fragment shader as the `out` attribute in vertex shader. It's also the only method (as I know) to get attribute value in the fragment shader.

The fragment shader in this demo is very simple, just assign the vColor to `gl_FragColor` just like we assgin position to `gl_Position` in the vertex shader.


Finally
-------

I found it was very difficult to write this article, but it helped me to understand OpenGL better after I've finished it. This tutorial is not intended to be a very accurate guide to OpenGL, but a simple comprehension from a newbie.

BTW, it's welcomed to help me with the English grammar.
