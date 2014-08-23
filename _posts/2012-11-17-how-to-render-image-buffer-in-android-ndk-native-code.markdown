---
layout: post
title: "How to Render Image Buffer in Android NDK Native Code"
date:   2012-11-17 06:52:03
---

Android NDK development has been improved quite a lot since Android 2.3 Gingerbread, but still with many limitations. In this post I will show off a general way to render native image pixels to Android Surface from NDK.

All the code below are benchmarked against a Samsung Galaxy S I9000 device, which has an 1 GHz Cortex-A8 single core CPU and 512M RAM.


Java Surface JNI
----------------

This method should work for all Android versions, but I haven't tested it with Android versions prior to 2.1.

At first, create a `ByteBuffer` in the Java code, then pass its handle to native C code. Each time I want to render some pixels, I only need to copy the pixels to the native `ByteBuffer` pointer, then invoke the Java method `surfaceRender` through JNI.

Please note that you need to set the `mSurface` object at proper time, such as `SurfaceView.onSurfaceChanged`. Also the `w` and `h` variable correspond to the width and height of the native image.

```java
private Bitmap mBitmap;
private ByteBuffer mByteBuffer;

private ByteBuffer surfaceInit() {
  synchronized (this) {
    mBitmap = Bitmap.createBitmap(w, h, Bitmap.Config.RGB_565);
    mByteBuffer = ByteBuffer.allocateDirect(w * h * 2);
    return mByteBuffer;
  }
}

private void surfaceRender() {
  synchronized (this) {
    try {
      Canvas c = mSurface.lockCanvas(null);
      mBitmap.copyPixelsFromBuffer(mByteBuffer);
      c.drawBitmap(mBitmap, 0, 0, null);
      mSurface.unlockCanvasAndPost(c);
    } catch (Exception e) {
    }
  }
}

private void surfaceRelease() {
  synchronized (this) {
    mBitmap.recycle();
    mBitmap = null;
    mByteBuffer = null;
  }
}
```

The C code is very simple, just invoke proper Java methods at proper time to initialize, render and release the Java `ByteBuffer` resources. The code won't compile, because I haven't include the common JNI setup methods.

```c
static jbyte* g_buffer;

bool jni_surface_init(JNIEnv* env) {
  jobject buf = (*env)->CallObjectMethod(env, javaClass, javaSurfaceInit);
  if (buf == NULL) return false;
  
  g_buffer = (jbyte*)(*env)->GetDirectBufferAddress(env, buf);
  if (g_buffer == NULL) return false;

  return JNI_VERSION_1_6;
}

void jni_surface_release(JNIEnv* env) {
  (*env)->CallVoidMethod(env, javaClass, javaSurfaceRelease);
  g_buffer = NULL;
}

void jni_surface_render(JNIEnv* env, uint8_t* pixels, int w, int h) {
  if (g_buffer != NULL) {
    memcpy(g_buffer, pixels, w * h * 2); // RGB565 pixels
    (*env)->CallVoidMethod(env, javaClass, javaSurfaceRender);
  }
}
```

It may be a bit complicated, but its performance is very eligible thanks to Java nio ByteBuffer. To render an 1280x720 RGB image, the JNI method only needs about 10ms.


OpenGL ES 2 Texture
-------------------

OpenGL is fast, it can also boost the performance if you need color space conversion, e.g. from YUV to RGB. I won't list any code here, because there're too many code and it's too difficult to describe it clearly. But it will be simple for the programmers who have used OpenGL before.

OpenGL ES 2 is supported by most Android devices, it's recommended to use this method if you're familiar with OpenGL.

To render an 1280x720 YUV image, the OpenGL method will cost about 12ms, the color space conversion time included!


NDK ANativeWindow API
---------------------

For Android versions prior to Android 2.3, there're no official NDK APIs to render pixels efficiently. Though an `android/bitmap.h` is provided, it's still too slow and not robust, I don't recommend it.

But since Android 2.3 Gingerbread, the `ANativeWindow` API is available, it's very fast and easy to use.

```cpp
ANativeWindow* window = ANativeWindow_fromSurface(env, javaSurface);

ANativeWindow_Buffer buffer;
if (ANativeWindow_lock(window, &buffer, NULL) == 0) {
  memcpy(buffer.bits, pixels,  w * h * 2);
  ANativeWindow_unlockAndPost(window);
}

ANativeWindow_release(window);
```

To render an 1280x720 RGB image, the `ANativeWindow` API only cost about 7ms.


Private C++ API
---------------

Android teams don't recommend to use the private interfaces hidden in Android source code, so it's up to you to choose whether to use this method. As I know, many famous Apps have choosen this method, such as Flash, Firefox, VPlayer, MX Player and VLC for Android.

```cpp
#ifdef FROYO
#include "surfaceflinger/Surface.h"
#else
#include "ui/Surface.h"
#endif

using namespace android;

jclass surfaceClass = env->FindClass("android/view/Surface");
if (surfaceClass == NULL) return;

jfield fid = env->GetFieldID(surfaceClass, "mSurface", "I");
if (fid == NULL) return;

sp<Surface> surface = (Surface*)env->GetIntField(javaSurface, fid);

Surface::SurfaceInfo info;
if (surface->lock(&info) == 0) {
  memcpy(info.bits, pixels,  w * h * 2);
  surface->unlockAndPost();
}
```

As you can see, the procedure used here is very similiar to the `ANativeWindow` one. But it's a bit hard to build this code snippet, because you need to setup proper `LOCAL_C_INCLUDES` and `LOCAL_C_LIBS` in your Android.mk file. For the header files, you'd better to clone the Android source code. For the shared libs *libgui.so* and *libsurfaceflinger_client.so*, you can pull them off from a real Android device or Android emulator.

The performance in this method is also the same as the `ANativeWindow` one.


Conclusion
----------

There're so many ways to display image in Android NDK, with so many Android versions! So I have been using several different dynamic shared libraries for different methods and Android versions, and load a poper one at runtime.
