---
layout: post
title: "A Workaround to Fix OpenGL eglSwapBuffers Freezing"
date:   2012-11-20 13:54:41
---

UPDATE: After the Galaxy S III upgraded to Android 4.1.1, the `glFlush` can't work any more!

In a recent OpenGL project, I found everything brilliant, until I tested the app on a Galaxy S III. In the Galaxy S III with a stock 4.0.4 ROM, the surface will be updated by a few frames, then stuck there, nothing continues, I can't even stop it.

I enabled and disabled several OpenGL/EGL related invocations, then had a conclusion that all methods which may update the surface buffer can freeze or block the rendering, `glClear`, `glDrawArrays`, `glDrawElements` and `eglSwapBuffers` included in these methods.

After been racking my brain all night over this problem, I found some Android issues which may cause the EGL freezing, such as [Android issue#6478](http://code.google.com/p/android/issues/detail?id=6478). This issue is not quite the same as mine, and only reported to occur in Android versions prior to ICS.

But I still wanted to take a chance, so I added `glFinish` just before `eglSwapBuffers`, everything worked!

```c
glFinish();
eglSwapBuffers(display, surface);
```

However, I got a great performance reduction, the FPS is only half of that when `glFinish` removed. More strange, the Galaxy S has the same performance with or without `glFinish` call.

I Think it's a Galaxy S III bug, or why it's slower than the Galaxy S?
