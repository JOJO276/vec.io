---
layout: post
title: "Andriod IPC: Shared Memory with ashmem, MemoryFile and Binder"
date:   2013-09-30 09:36:32
---

Recently, I've decided to begin my own hardware journey. The most important part is to choose a proper operating system. I've tried to use several embedded Linux systems, but got many portable and development issues. Also the recent Android platform updates make me more confident on it, so I bet it and learn more about it!

This post intends to share something about IPC related to Android platform development, not for common Android apps, though many concepts can adapt to that.

There is an interesting slides for Android binder library [Deep Dive Into Binder](https://thenewcircle.com/s/post/1392/Deep_Dive_Into_Binder_Presentation.htm), with many useful links included. And a very simple binder demo was provided by [gburca/BinderDemo](https://github.com/gburca/BinderDemo). Here I will show some sample code to use ashmem library, of course, we need the binder mechanism.

I've published the code used in this post at GitHub https://github.com/vecio/AndroidIPC, which can run on real Android device once you have root permission.



ashmem
------

Linux has a resource expensive shared memory implementation shm, but Android is designed to be used for resource limited embedded hardware, so they crafted their own ashmem, which lives under _$AOSP/system/core_.

The magic behind ashmem is quite simple as handling generic Linux file descriptor and `mmap`.

```c
int fd = ashmem_create_region(name, size);
ashmem_pin_region(fd, 0, 0);
uint8_t *shm = mmap(NULL, size, PROT_READ | PROT_WRITE, MAP_SHARED, image->fd, 0);
```

It's called shared memory because the region created from ashmem could be used between different processes. But the memory pointer created by `mmap` is process dependent, and so is the file descriptor from `ashmem_create_region`, i.e. they are only valid in the same process they are created. 

So, we need some mechanism to share this region pointer to other processes.



MemoryFile
----------

While Android apps running on Dalvik VM, they need to benefit from the ashmem library, so _MemoryFile.java_ is created as a thin wrapper upon ashmem C library. 

```java
public MemoryFile(String name, int length) throws IOException {
    mLength = length;
    mFD = native_open(name, length);
    if (length > 0) {
        mAddress = native_mmap(mFD, length, PROT_READ | PROT_WRITE);
    } else {
        mAddress = 0;
    }
}
```

The detailed implementation of MemoryFile could be found at _$AOSP/frameworks/base/core/jni/android\_os\_MemoryFile.cpp_.



Binder
------

To make the bridge between two processes, we may use Binder. Binder is the core of Android IPC system, it defines some basic interfaces to write IPC code, just like the familiar AIDL tools. Indeed, AIDL is an wrapper of Binder.

To define the interface, just implement the `IInterface`:

```cpp
class ISHM : public IInterface {
  public:
    virtual status_t setFD(uint32_t fd) = 0;

    DECLARE_META_INTERFACE(SHM);
};
```

After the interface defined, the client and service side should both implement the interface:

```cpp
// The client side
class BpSHM : public BpInterface<ISHM> {
  public:
    BpSHM(const sp<IBinder>& impl) : BpInterface<ISHM>(impl) {
      ALOGD("BpSHM::BpSHM()");
    }

    virtual status_t setFD(uint32_t fd)
    {
      ALOGD("BpSHM::setFD(%u)", fd);
      Parcel data, reply;
      data.writeInterfaceToken(ISHM::getInterfaceDescriptor());
      data.writeFileDescriptor(fd);
      remote()->transact(SET_FD, data, &reply);
      return reply.readInt32();
    }
};

IMPLEMENT_META_INTERFACE(SHM, "io.vec.IPC");


// The server side
class BnSHM : public BnInterface<ISHM> {
  virtual status_t onTransact(uint32_t code, const Parcel& data, Parcel* reply, uint32_t flags = 0)
  {
    ALOGD("BnSHM::onTransact(%u)", code);
    CHECK_INTERFACE(ISHM, data, reply);
    switch(code) {
      case SET_FD: {
             reply->writeInt32(setFD(data.readFileDescriptor()));
             return NO_ERROR;
           } break;
      default: {
             return BBinder::onTransact(code, data, reply, flags);
           } break;
    }
  }
};
```



Share the memory
----------------

From the code in above section, there are two important functions `writeFileDescriptor` and `readFileDescriptor`. Yes, they are the magics to transfer a Linux file descriptor from one process to another.

How do we get the file descriptor from `MemoryFile` object?

```cpp
static jboolean jni_setMemoryFile(JNIEnv* env, jclass clz, jobject jmf)
{
  jclass clsMF = env->FindClass("android/os/MemoryFile");
  jfieldID fldFD = env->GetFieldID(clsMF, "mFD", "Ljava/io/FileDescriptor;");
  jobject objFD = env->GetObjectField(jmf, fldFD);
  jclass clsFD = env->FindClass("java/io/FileDescriptor");
  fldFD = env->GetFieldID(clsFD, "descriptor", "I");
  jint fd = env->GetIntField(objFD, fldFD);
  env->DeleteLocalRef(clsFD);
  env->DeleteLocalRef(objFD);
  env->DeleteLocalRef(clsMF);
  ALOGD("jni_setMemoryFile(%d)", fd);
  sp<ISHM> service = SHM::getService();
  return (service->setFD(fd) == NO_ERROR);
}
```

The full project has been published at GitHub https://github.com/vecio/AndroidIPC.
