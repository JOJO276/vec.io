---
layout: post
title: "Use Android Hardware Decoder with OMXCodec in NDK"
date:   2012-12-19 16:09:25
---

Android API dosen't expose interface to the device's hardware decoding module, but the OS does have a beautiful private library called stagefright, which encapsulates elegant hardware accelerated decoding & encoding API, which can be used accompanied with FFmpeg or GStreamer.

Don't fear the private API would change frequently suggested by many developers or Google's Android engineers, many famous apps tell us these APIs won't change hardly. The Adobe Flash player, VPlayer and Firefox for Android have been using the stagefright API to do hardware decoding for quite a long time.

To procceed in this post, you need to be familiar with the techinques menthioned in [How to Render Image Buffer in Android NDK Native Code](http://vec.io/posts/how-to-render-image-buffer-in-android-ndk-native-code#toc-private-c-plus-plus-api).


MediaSource
-----------

Android engineers use OpenMAX specification to communicate with different devices' hardware decoders, in order to simplify the OpenMAX procedure, they created the stagefright library.

To understand this library, the `MediaSource` class is one of the most important keys. `MediaSource` is declared in *frameworks/av/include/media/stagefright/MediaSource.h*. Simply put, a `MediaSource` should provide one main method called `read`, which should read some data from some data source and return the result to a `MediaBuffer`.

To fulfill a complete video decoding work, we need two different `MediaSource`, one to read encoded video data from file, it's something like FFmpeg's **demuxer**, and the other one acts just like FFmpeg's **decoder**, which will read and decode the encoded data from the demuxer, then produce decoded video frames.

![OMXCodec_MediaSource.png]({{ '/images/2012/12/19/OMXCodec_MediaSource.png' | prepend: site.url }})


AVFormatSource
------------

`AVFormatSource`, a very simple `MediaSource` implementation based on FFmpeg's `libavformat`, is the first `MediaSource`, which works as the demuxer.

It's the plenty of powerful demuxers why I use `libavformat` to create a fresh new `MediaSource` rather than using the existing ones in AOSP.

```cpp
#define FFMPEG_AVFORMAT_MOV "mov,mp4,m4a,3gp,3g2,mj2"

using namespace android;

class AVFormatSource : public MediaSource {
  public:
    AVFormatSource(const char *videoPath);

    virtual status_t read(MediaBuffer **buffer, const MediaSource::ReadOptions *options);
    virtual sp<MetaData> getFormat() { return mFormat; }
    virtual status_t start(MetaData *params) { return OK; }
    virtual status_t stop() { return OK; }

  protected:
    virtual ~AVFormatSource();

  private:
    AVFormatContext *mDataSource;
    AVCodecContext *mVideoTrack;
    AVBitStreamFilterContext *mConverter;
    MediaBufferGroup mGroup;
    sp<MetaData> mFormat;
    int mVideoIndex;
};

AVFormatSource::AVFormatSource(const char *videoPath) {
  av_register_all();

  mDataSource = avformat_alloc_context();
  avformat_open_input(&mDataSource, videoPath, NULL, NULL);
  for (int i = 0; i < mDataSource->nb_streams; i++) {
    if (mDataSource->streams[i]->codec->codec_type == AVMEDIA_TYPE_VIDEO) {
      mVideoIndex = i;
      break;
    }
  }
  mVideoTrack = mDataSource->streams[mVideoIndex]->codec;

  size_t bufferSize = (mVideoTrack->width * mVideoTrack->height * 3) / 2;
  mGroup.add_buffer(new MediaBuffer(bufferSize));
  mFormat = new MetaData;

  switch (mVideoTrack->codec_id) {
    case CODEC_ID_H264:
      mConverter = av_bitstream_filter_init("h264_mp4toannexb");
      mFormat->setCString(kKeyMIMEType, MEDIA_MIMETYPE_VIDEO_AVC);
      if (mVideoTrack->extradata[0] == 1) {
        mFormat->setData(kKeyAVCC, kTypeAVCC, mVideoTrack->extradata, mVideoTrack->extradata_size);
      }
      break;
    case CODEC_ID_MPEG4:
      mFormat->setCString(kKeyMIMEType, MEDIA_MIMETYPE_VIDEO_MPEG4);
      if (mDataSource->iformat && mDataSource->iformat->name && !strcasecmp(mDataSource->iformat->name, FFMPEG_AVFORMAT_MOV)) {
        MOVContext *mov = (MOVContext *)(mDataSource->priv_data);
        if (mov->esds_data != NULL && mov->esds_size > 0 && mov->esds_size < 256) {
          mFormat->setData(kKeyESDS, kTypeESDS, mov->esds_data, mov->esds_size);
        }
      }
      break;
    case CODEC_ID_H263:
      mFormat->setCString(kKeyMIMEType, MEDIA_MIMETYPE_VIDEO_H263);
      break;
    default:
      break;
  }

  mFormat->setInt32(kKeyWidth, mVideoTrack->width);
  mFormat->setInt32(kKeyHeight, mVideoTrack->height);
}

status_t AVFormatSource::read(MediaBuffer **buffer, const MediaSource::ReadOptions *options) {
  AVPacket packet;
  status_t ret;
  bool found = false;

  while (!found) {
    ret = av_read_frame(is->formatCtx, &packet);
    if (ret < 0) {
      return ERROR_END_OF_STREAM;
    }

    if (packet.stream_index == mVideoIndex) {
      if (mConverter) {
        av_bitstream_filter_filter(mConverter, mVideoTrack, NULL, &packet.data, &packet.size, packet.data, packet.size, packet.flags & AV_PKT_FLAG_KEY);
      }
      ret = mGroup.acquire_buffer(buffer);
      if (ret == OK) {
        memcpy((*buffer)->data(), packet.data, packet.size);
        (*buffer)->set_range(0, packet.size);
        (*buffer)->meta_data()->clear();
        (*buffer)->meta_data()->setInt32(kKeyIsSyncFrame, packet.flags & AV_PKT_FLAG_KEY);
        (*buffer)->meta_data()->setInt64(kKeyTime, packet.pts);
      }
      found = true;
    }
    av_free_packet(&packet);
  }

  return ret;
}

AVFormatSource::~AVFormatSource() {
  if (mConverter) {
    av_bitstream_filter_close(mConverter);
  }
  av_close_input_file(mDataSource);
}
```

I've omitted all the header includes and error checks to make code more clean and easy to read.

From the code above, I only try to decode H.263, H.264 and MPEG4, all other formats are not supported from Android's documentation officially, though some vendors support more formats such as WMV, FLV or RM.

Pay attention to the FFmpeg code I used, it's the [patched version](https://github.com/yixia/FFmpeg-Android) from VPlayer for Android, I've also written a simple post on [building FFmpeg for Android](http://vec.io/posts/how-to-build-ffmpeg-with-android-ndk).


OMXCodec
--------

The other `MediaSource` is `OMXCodec`, which do the actual decoding work.

You can locate the `OMXCodec.cpp` at [AOSP](http://source.android.com/) tree's *frameworks/av/media/libstagefright/OMXCodec.cpp*, and `OMXCodec.h` at *frameworks/av/include/media/stagefright/OMXCodec.h*. Then you will find it's so easy to use the `OMXCodec` class in our own NDK code, especially if you found some sample usage from *libstagefright/AwesomePlayer.cpp*.

```cpp
// At first, get an ANativeWindow from somewhere
sp<ANativeWindow> mNativeWindow = getNativeWindowFromSurface();

// Initialize the AVFormatSource from a video file
sp<MediaSource> mVideoSource = new AVFormatSource(filePath);

// Once we get an MediaSource, we can encapsulate it with the OMXCodec now
OMXClient mClient;
mClient.connect();
sp<MediaSource> mVideoDecoder = OMXCodec::Create(mClient.interface(), mVideoSource->getFormat(), false, mVideoSource, NULL, 0, mNativeWindow);
mVideoDecoder->start();

// Just loop to read decoded frames from mVideoDecoder
for (;;) {
	MediaBuffer *mVideoBuffer;
    MediaSource::ReadOptions options;
    status_t err = mVideoDecoder->read(&mVideoBuffer, &options);
    if (err == OK) {
    	if (mVideoBuffer->range_length() > 0) {
        	// If video frame availabe, render it to mNativeWindow
    		sp<MetaData> metaData = mVideoBuffer->meta_data();
        	int64_t timeUs = 0;
    		metaData->findInt64(kKeyTime, &timeUs)
    		native_window_set_buffers_timestamp(mNativeWindow.get(), timeUs * 1000);
    		err = mNativeWindow->queueBuffer(mNativeWindow.get(), mVideoBuffer->graphicBuffer().get());
    		if (err == 0) {
    			metaData->setInt32(kKeyRendered, 1);
            }
        }
        mVideoBuffer->release();
    }
}

// Finally release the resources
mVideoSource.clear();
mVideoDecoder->stop();
mVideoDecoder.clear();
mClient.disconnect();
```

I think you will figure that `OMXCodec` is also a child class of `MediaSource`, and it's constructed from another `MediaSource`, which is `AVFormatSource` in this example.

Indeed, if you take a look at `OMXCodec.cpp`, you should notice its `read` method is implemented in three main steps:

1. Read encoded video data with `mVideoSource.read` to a `MediaBuffer`. The video data is just an `AVPacket` in this FFmpeg sample.
2. Pass the `MediaBuffer` to device's decoding module, which will do the actual decoding work.
3. Return the decoded video frame as a `MediaBuffer`, which we can render to screen.


Troubleshooting
---------------

It's a pain to deal with the product of so many Android devices, Android versions and video formats. As my experience, the chips from TI, Nvidia, QCom and other vendors all have slight differences to each other in using `OMXCodec`. It's harder than deal with different cameras and different screen sizes, but it deserves if you want to play high quality videos with video format not supported by Android!

I'm not able to list all the problems appeared to me, but count some main fields where the problems most occur.

1. Different color space used in the decoded frames, it's best to find those information from CyanogenMod's source code.
2. The difference in managing MediaBuffer memory, mainly when releasing MediaBuffer.
3. Some decoders require you to crop the decoded frames' dimensions.
4. It's important to reorder the decoded frames' timestamps for some decoders, but not for the others.


Resources
---------

This approach has been used in several open source projects listed below.

1. The `libstagefright.cpp` in FFmpeg's source code is the most simple start point to understand the concepts. But look out, don't use it in production code, it's full of bugs.
2. Firefox for Android [added H.264 hardware decoding recently](https://hacks.mozilla.org/2012/11/h264-video-in-firefox-for-android/), the related code is available in *$MOZILLA/content/media*.
3. VLC for Android is also capable of hardware decoding, but I haven't looked its code yet.

It's not an easy work to use hardware decoding in Android, but all these projects have proved that it's possible and nearly perfect.
