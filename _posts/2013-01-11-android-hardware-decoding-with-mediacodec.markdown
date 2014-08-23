---
layout: post
title: "Android Hardware Decoding with MediaCodec"
date:   2013-01-11 15:55:23
---

Finally, I must say, finally, we get [low-level media APIs in Android](https://developers.google.com/events/io/sessions/gooio2012/117/), the Android hardware decoding and encoding APIs are finally available. It was a thing since Android 4.1 in Google IO 2012, but until now, when a new Android version 4.2 has been released, those low-level APIs are still too hard to use. There're so many Android vendors, we can't even [get the same results from all Google's Nexus devices](http://code.google.com/p/android/issues/detail?id=37769).

Despite the annoyings, I still tried these APIs and prayed them to get better in next Android release, and next Android release would swallow market quikly.

I just finished a simple video player with the combination of `MediaExtractor` and `MediaCodec`, you may find the full project from [my Github](https://github.com/vecio).

```java
private MediaExtractor extractor;
private MediaCodec decoder;
private Surface surface;

public void run() {
  extractor = new MediaExtractor();
  extractor.setDataSource(SAMPLE);

  for (int i = 0; i < extractor.getTrackCount(); i++) {
    MediaFormat format = extractor.getTrackFormat(i);
    String mime = format.getString(MediaFormat.KEY_MIME);
    if (mime.startsWith("video/")) {
      extractor.selectTrack(i);
      decoder = MediaCodec.createDecoderByType(mime);
      decoder.configure(format, surface, null, 0);
      break;
    }
  }

  if (decoder == null) {
    Log.e("DecodeActivity", "Can't find video info!");
    return;
  }

  decoder.start();

  ByteBuffer[] inputBuffers = decoder.getInputBuffers();
  ByteBuffer[] outputBuffers = decoder.getOutputBuffers();
  BufferInfo info = new BufferInfo();
  boolean isEOS = false;
  long startMs = System.currentTimeMillis();

  while (!Thread.interrupted()) {
    if (!isEOS) {
      int inIndex = decoder.dequeueInputBuffer(10000);
      if (inIndex >= 0) {
        ByteBuffer buffer = inputBuffers[inIndex];
        int sampleSize = extractor.readSampleData(buffer, 0);
        if (sampleSize < 0) {
          Log.d("DecodeActivity", "InputBuffer BUFFER_FLAG_END_OF_STREAM");
          decoder.queueInputBuffer(inIndex, 0, 0, 0, MediaCodec.BUFFER_FLAG_END_OF_STREAM);
          isEOS = true;
        } else {
          decoder.queueInputBuffer(inIndex, 0, sampleSize, extractor.getSampleTime(), 0);
          extractor.advance();
        }
      }
    }

    int outIndex = decoder.dequeueOutputBuffer(info, 10000);
    switch (outIndex) {
    case MediaCodec.INFO_OUTPUT_BUFFERS_CHANGED:
      Log.d("DecodeActivity", "INFO_OUTPUT_BUFFERS_CHANGED");
      outputBuffers = decoder.getOutputBuffers();
      break;
    case MediaCodec.INFO_OUTPUT_FORMAT_CHANGED:
      Log.d("DecodeActivity", "New format " + decoder.getOutputFormat());
      break;
    case MediaCodec.INFO_TRY_AGAIN_LATER:
      Log.d("DecodeActivity", "dequeueOutputBuffer timed out!");
      break;
    default:
      ByteBuffer buffer = outputBuffers[outIndex];
      Log.v("DecodeActivity", "We can't use this buffer but render it due to the API limit, " + buffer);

      // We use a very simple clock to keep the video FPS, or the video
      // playback will be too fast
      while (info.presentationTimeUs / 1000 > System.currentTimeMillis() - startMs) {
        try {
          sleep(10);
        } catch (InterruptedException e) {
          e.printStackTrace();
          break;
        }
      }
      decoder.releaseOutputBuffer(outIndex, true);
      break;
    }

    if ((info.flags & MediaCodec.BUFFER_FLAG_END_OF_STREAM) != 0) {
      Log.d("DecodeActivity", "OutputBuffer BUFFER_FLAG_END_OF_STREAM");
      break;
    }
  }

  decoder.stop();
  decoder.release();
  extractor.release();
}
```

Compared to the [OMXCodec methods introduced in an early post](http://vec.io/posts/use-android-hardware-decoder-with-omxcodec-in-ndk), this method is more recommended if you're targeting Android 4.1 and later. But it's still too limited, you can't do anything with the decoded video frame but render them to surface, because there're more than 40 color formats to deal with and many of them are vendor proprietary without documentation.
