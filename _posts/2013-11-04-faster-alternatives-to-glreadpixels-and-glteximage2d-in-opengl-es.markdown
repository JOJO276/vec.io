---
layout: post
title: "Faster Alternatives to glReadPixels and glTexImage2D in OpenGL ES"
date:   2013-11-04 17:30:27
---

In the development of [Shou](https://shou.tv), I've been using GLSL with NEON to manipulate image rotation, scaling and color conversion, before send them to video encoder.

So I need a very efficient way to transfer pixels between OpenGL and memory space. The `glTexImage2D` and `glReadPixels` performance are very unacceptable, especially for some specific vendors, e.g. Samsung Galaxy devices with Exynos chip.

Compared to `glTex(Sub)Image2D`, the `glReadPixels` is the real bottleneck, which blocks all OpenGL pipeline and results in about 100ms delay for a standard 720P frame read back.

Here I will share two standard OpenGL approaches to achieve really fast pixels pack, which should be available on all OpenGL implementations. Only `glReadPixels` will be discussed, as the `glTexImage2D` should have the same usage.



Pixel Buffer Object
-------------------

[PBO](http://www.opengl.org/wiki/Pixel_Buffer_Object) is not introduced until OpenGL ES 3.0, which is available since Android 4.3. The pixels pack operation will be reduced to about 5ms using PBO.

PBO is created just like any other buffer objects:

```c
glGenBuffers(1, &pbo_id);
glBindBuffer(GL_PIXEL_PACK_BUFFER, pbo_id);
glBufferData(GL_PIXEL_PACK_BUFFER, pbo_size, 0, GL_DYNAMIC_READ);
glBindBuffer(GL_PIXEL_PACK_BUFFER, 0);
```
According to the reference of `glReadPixels`:

> If a non-zero named buffer object is bound to the GL_PIXEL_PACK_BUFFER target (see glBindBuffer) while a block of pixels is requested, data is treated as a byte offset into the buffer object's data store rather than a pointer to client memory.  

When we need to read pixels from an FBO:

```c
glReadBuffer(GL_COLOR_ATTACHMENT0);
glBindBuffer(GL_PIXEL_PACK_BUFFER, pbo_id);
glReadPixels(0, 0, width, height, GL_RGBA, GL_UNSIGNED_BYTE, 0);
GLubyte *ptr = glMapBufferRange(GL_PIXEL_PACK_BUFFER, 0, pbo_size, GL_MAP_READ_BIT);
memcpy(pixels, ptr, pbo_size);
glUnmapBuffer(GL_PIXEL_PACK_BUFFER);
glBindBuffer(GL_PIXEL_PACK_BUFFER, 0);
```

In a real project, we may consider using double or triple PBOs to improve the performance.


EGLImage
--------

EGL_KHR_image_base is a completed EGL extension, which achieves the same performance as PBO, but only require OpenGL-ES 1.1 or 2.0.

The function to create an `EGLImageKHR` is 

```c
EGLImageKHR eglCreateImageKHR(EGLDisplay dpy,
                              EGLContext ctx,
                              EGLenum target,
                              EGLClientBuffer buffer,
                              const EGLint *attrib_list)
```

The Android EGL implementation _frameworks/native/opengl/libagl/egl.cpp_ implies that the `EGLDisplay` should be a valid display,  the `EGLClientBuffer` type should be `ANativeWindowBuffer`, the `EGLContext` can only be `EGL_NO_CONTEXT`, and the target can only be `EGL_NATIVE_BUFFER_ANDROID`.

All the other parameters are obvious, except for the `ANativeWindowBuffer`, which is defined in `system/core/include/system/window.h`.

To allocate an `ANativeWindowBuffer`, Android has a simple wrapper called `GraphicBuffer`, defined in `frameworks/native/include/ui/GraphicBuffer.h`.

```c
GraphicBuffer *window = new GraphicBuffer(width, height, PIXEL_FORMAT_RGBA_8888, GraphicBuffer::USAGE_SW_READ_OFTEN | GraphicBuffer::USAGE_HW_TEXTURE);

struct ANativeWindowBuffer *buffer = window->getNativeBuffer();
EGLImageKHR *image = eglCreateImageKHR(eglGetCurrentDisplay(), EGL_NO_CONTEXT, EGL_NATIVE_BUFFER_ANDROID, *attribs);
```

Then anytime we want to read pixels from an FBO, we should use one of the two methods below:

```c
void EGLImageTargetTexture2DOES(enum target, eglImageOES image)

void EGLImageTargetRenderbufferStorageOES(enum target, eglImageOES image)
```

These two methods will establishes all the properties of the target `GL_TEXTURE_2D` or `GL_RENDERBUFFER`.

```c
uint8_t *ptr;
glBindTexture(GL_TEXTURE_2D, texture_id);
glEGLImageTargetTexture2DOES(GL_TEXTURE_2D, image);

window->lock(GraphicBuffer::USAGE_SW_READ_OFTEN, &ptr);
memcpy(pixels, ptr, width * height * 4);
window->unlock();
```



References
----------

1. GL_PIXEL_PACK_BUFFER http://www.khronos.org/opengles/sdk/docs/man3/xhtml/glMapBufferRange.xml
2. EGL_KHR_image_base http://www.khronos.org/registry/egl/extensions/KHR/EGL_KHR_image_base.txt
3. GL_OES_EGL_image http://www.khronos.org/registry/gles/extensions/OES/OES_EGL_image.txt
4. Using direct textures on Android http://snorp.net/2011/12/16/android-direct-texture.html
5. Using OpenGL ES to Accelerate Apps with Legacy 2D GUIs http://software.intel.com/en-us/articles/using-opengl-es-to-accelerate-apps-with-legacy-2d-guis
6. iOS solution http://stackoverflow.com/questions/9550297/faster-alternative-to-glreadpixels-in-iphone-opengl-es-2-0
