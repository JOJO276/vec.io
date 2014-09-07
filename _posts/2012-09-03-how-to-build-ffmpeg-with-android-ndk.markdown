---
layout: post
title: "How to Build FFmpeg with Android NDK"
date:   2012-09-03 09:12:23
---

I have written one article on compiling FFmpeg for Android with NDK, and got thousands of visits everyday, though it's in Chinese and too many problems to use.

Here will show you how to build FFmpeg from the latest git repository with the latest Android NDK version, step by step, promise to work.


Got FFmpeg
----------

At first, you need git to get the FFmpeg code, if you don't have git or don't wanna use git, you can get FFmpeg from http://ffmpeg.org.

```bash
git clone git://source.ffmpeg.org/ffmpeg.git ffmpeg
git checkout 5e99df019a850e9ffa96d73e72b8a47a93a61de8
```


Configure NDK
-------------

In this tutorial, we don't use the traditional Android.mk file to build FFmpeg, instead we will try the Android NDK standalone toolchain. To initialize the toolchain, issue these commands:

```bash
export ANDROID_NDK=/path/to/your/android/ndk/root
export TOOLCHAIN=/tmp/ffmpeg
export SYSROOT=$TOOLCHAIN/sysroot/
$ANDROID_NDK/build/tools/make-standalone-toolchain.sh \
    --platform=android-14 --install-dir=$TOOLCHAIN
```

At this point, we can use the Android standalone toolchain located at `$TOOLCHAINE` to build our FFmpeg. More details about Android standalone toolchain can be found in Android NDK's docs.


Configure FFmpeg
----------------

Now we're ready to do the traditional Linux style `./configure` job for FFmpeg, it's quite easy to do that once previous two preparations are ready.

A little break: it's annoying to write bash scripts directly in terminal window, so at this point I will create a bash file with below content:

```bash
export PATH=$TOOLCHAIN/bin:$PATH
export CC=arm-linux-androideabi-gcc
export LD=arm-linux-androideabi-ld
export AR=arm-linux-androideabi-ar

CFLAGS="-O3 -Wall -mthumb -pipe -fpic -fasm \
  -finline-limit=300 -ffast-math \
  -fstrict-aliasing -Werror=strict-aliasing \
  -fmodulo-sched -fmodulo-sched-allow-regmoves \
  -Wno-psabi -Wa,--noexecstack \
  -D__ARM_ARCH_5__ -D__ARM_ARCH_5E__ \
  -D__ARM_ARCH_5T__ -D__ARM_ARCH_5TE__ \
  -DANDROID -DNDEBUG"

EXTRA_CFLAGS="-march=armv7-a -mfpu=neon \
              -mfloat-abi=softfp -mvectorize-with-neon-quad"
EXTRA_LDFLAGS="-Wl,--fix-cortex-a8"

FFMPEG_FLAGS="--prefix=/tmp/ffmpeg/build \
  --target-os=linux \
  --arch=arm \
  --enable-cross-compile \
  --cross-prefix=arm-linux-androideabi- \
  --enable-shared \
  --disable-symver \
  --disable-doc \
  --disable-ffplay \
  --disable-ffmpeg \
  --disable-ffprobe \
  --disable-ffserver \
  --disable-avdevice \
  --disable-avfilter \
  --disable-encoders  \
  --disable-muxers \
  --disable-filters \
  --disable-devices \
  --disable-everything \
  --enable-protocols  \
  --enable-parsers \
  --enable-demuxers \
  --disable-demuxer=sbg \
  --enable-decoders \
  --enable-bsfs \
  --enable-network \
  --enable-swscale  \
  --enable-asm \
  --enable-version3"

./configure $FFMPEG_FLAGS --extra-cflags="$CFLAGS $EXTRA_CFLAGS" \
  --extra-ldflags="$EXTRA_LDFLAGS"
```

It's easy, right? We just define some variables and enable or disable some FFmpeg components. Also some GCC optimizations are included, details can be found from `man gcc` or online documents http://gcc.gnu.org/onlinedocs/gcc/ARM-Options.html.


Build and strip FFmpeg
----------------------

If you succeed to configure FFmpeg for Android, it's time to `make`, issue commands below:

```bash
make -j4
make install
```

If everything is OK, we can get libavcodec.so, libavformat.so, etc in the prefix directory.  If you wanna combine them to one libffmpeg.so, run:

```bash
rm libavcodec/inverse.o
$CC -lm -lz -shared --sysroot=$SYSROOT -Wl,--no-undefined \
   -Wl,-z,noexecstack $EXTRA_LDFLAGS libavutil/*.o libavutil/arm/*.o \
   libavcodec/*.o libavcodec/arm/*.o libavformat/*.o libswresample/*.o \
   libswscale/*.o -o libffmpeg.so
```

After testing with your build, you may want to strip unused information to shrink the libffmpeg.so library size:

```bash
arm-linux-androideabi-strip --strip-unneeded libffmpeg.so
```

For those who wanna the full code, please go to https://github.com/vecio/FFmpeg-Android.


Conclusion
----------

It's easier to port Linux library to Android since Android standalone toolchain was available, I've managed to compile many other libraries in my Android project.

In the later tutorials, I will share how to build a video player with FFmpeg from the ground, step by step too. Stay tuned!
