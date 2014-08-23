---
layout: post
title: "Explore Android Video Encoding"
date:   2013-10-24 05:01:00
---

It's a pain to do video encoding on all Android platforms, even Android 4.3. Compared to video decoding, you just can't find any efficient and free solutions to encode video as AVC/H.264.

From the very beginning, when Android born six years ago, the MediaRecorder API had never improved significantly, and no additional **usable** video encoding related API introduced neither. But guess what? Google has a brilliant video chat APP, Google talk, since Android 2.3. Google knows the essentiality of video encoder, if you go through the AOSP tree, you could find the code specific for Google talk's video chat functionality.

Now, I'm working on a SIP client for Android, alongside a screen recorder called **[Shou](https://shou.tv)**, which can also mirror your Android screen to AirPlay or Miracast powered external display. I will share some experiences of encoding high quality video on Android, but without the painful details.




MediaRecorder
-------------

This is the only API available to encode video for quite a long time. It's simple and stable, but only supports encoding frames from the Camera preview! You can't even start the MediaRecorder without the Camera permission declared in the AndroidManifest.xml.

Thank goodness, Google introduced the hidden video source `GRALLOC_BUFFER` from Android 4.0. You may remember the short-lived face morphing feature in ICS Camera, which is just based on the hidden API. This video source allows the MediaRecorder to encode frames from a Surface, and still available and hidden for Android 4.3.

What if this video source stable enough, I wouldn't receive so many crash reports from my users of **[Shou](https://shou.tv)**. According to the feedback, about half devices would crash with the `GRALLOC_BUFFER` API.




OMXCodec
--------

The encoding side of OMXCodec is not as stable as [the decoding part](https://vec.io/posts/use-android-hardware-decoder-with-omxcodec-in-ndk), but is stable enough compared to the MediaRecorder video source `GRALLOC_BUFFER`.

It's also more flexible than use the MediaRecorder directly, you can use several MediaWriter in stagefright or craft your own ones. So if you want to do video streaming or produce some custom video containers, you would benefit from this API, especially when targeting some specific devices.




MediaCodec
----------

This missing API was introduced from Android 4.1, just improved a lot at Android 4.3, it can encode video frames from a Surface, just like the `GRALLOC_BUFFER` for MediaRecorder. It seems Google has decided to deprecate the `GRALLOC_BUFFER` video source, which hasn't been publicly released yet.

So if you're targeting Android 4.3, this should be considered at first. But it lacks documentation and tests, some devices will crash. It's much harder for most developers to encapsulate the encoded frames to a proper video container, while the MediaMuxer API is too limited.

For Android 4.1+, the MediaCodec requires different color formats as input buffer, I've written some color space conversion functions for it, got acceptable testing results for most devices. The performance is great, but not as stable as the MediaRecorder, it would crash for some particular devices or ROMs.




Software encoding
-----------------

The methods above are all hardware encoding solutions. I have also considered using software encoding, it's more stable and portable compared to hardware encoding. Of course, I won't write my own video encoder, it's too complicated for anyone.

I've used x264 for a long time, it's the most stable and efficient one compared to other video encoders. But compared to hardware encoding, it's too slow, can't encode Android screen at 720P or even 1080P with high quality! Moreover it's GPL or requires an expensive commercial license fee.

BTW, the libvpx from Google is slower and produced higher bit rate compared to x264. I may use it when all Android devices equip an octa-core CPU.




Conclusion
----------

Fucking Android!
