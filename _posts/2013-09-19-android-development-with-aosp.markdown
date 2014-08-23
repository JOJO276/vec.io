---
layout: post
title: "Android  Development with AOSP"
date:   2013-09-19 17:45:58
---

Constantly, I have to debug with Android open source code, to use some private APIs or to test some hidden features.


Building AOSP
-------------

Just follow the instructions from http://source.android.com/source/building-devices.html, make sure to get the vendor binaries at first https://developers.google.com/android/nexus/drivers.

It's also important to use correct software versions, e.g. Java 6 or Python 2. I haven't tried to find the best method to manage multiple java or python implementations, just on my most dirty way.

Only two problem occurred during my build for flo (new Nexus 7), issues [#22231](https://code.google.com/p/android/issues/detail?id=22231) and [#60234](https://code.google.com/p/android/issues/detail?id=60234).


Flash device
------------

Run `adb reboot bootloader` to get into the boot loader, then unlock it with `fastboot oem unlock`, and flash AOSP with `fastboot -w flashall`.

The [Superuser](http://download.clockworkmod.com/superuser/superuser.zip) is a useful tool, it needs to be flashed to device, with [ClockworkMod recovery](http://www.clockworkmod.com/rommanager).

    adb push superuser.zip /sdcard/
    adb reboot bootloader
    fastboot boot recovery.img


Hack module
-----------

After the full build and flash, you don't need to build the full platform again, just build the specific module with `mmm`, e.g.

    mmm frameworks/av/media/libstagefright

After that, use `adb` to push the built library to _/system/lib/_

    adb root
    adb remount
    adb push $BUILD_DIR/target/product/flo/system/lib/libstagefright.so /system/lib/

Then just hack the platform!
