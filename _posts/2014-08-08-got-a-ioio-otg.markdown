---
layout: post
title: "Got a IOIO-OTG"
date:   2014-08-08 09:55:37
---

Interested in hardware development, I just don't like some obviously popular things, so instead of Arduino, I ordered a IOIO-OTG.

It's much smaller than I expected! No any experiences in hardware development, so I hadn't buy enough components to start hacking with the Android yet.

![IOIO_OTG.jpg]({{ '/images/2014/08/08/IOIO_OTG.jpg' | prepend: site.url }})

Anyway, after adding a proper udev rule _/usr/lib/udev/rules.d/50-ioio.rules_, I plugged it into my Arch Linux notebook with the USB cable for my HTC One.

```bash
ACTION=="add", SUBSYSTEM=="tty", SUBSYSTEMS=="usb", ATTRS{idVendor}=="1b4f", ATTRS{idProduct}=="0008", SYMLINK+="IOIO%n", MODE="666"
```

Follow the guide https://github.com/ytai/ioio/wiki/IOIO-OTG-Bootloader-and-IOIODude, get the `ioiodude` from https://github.com/ytai/ioio/tree/master/release/apps

```bash
ls /dev/IOIO* #=> /dev/IOIO0
./ioiodude --port=/dev/IOIO0 versions
```

The IOIO is running in application mode, so I got

```
IOIO Application detected.

Hardware version: SPRK0020
Bootloader version: IOIO0400
Application version: IOIO0330
```

To flash the latest firmware, I need to boot the IOIO to bootloader mode. Just detach the IOIO from the PC, use any wire to connect the `boot` with `GND`, then plug the IOIO to PC with the USB cable. Wow, the yellow state LED just lights!

Remove the wire or jumper in the jargon, then run the identical command

```bash
./ioiodude --port=/dev/IOIO0 versions
IOIO Bootloader detected.

Hardware version: SPRK0020
Bootloader version: IOIO0400
Platform version: IOIO0030
```

The IOIO is in bootloader mode now, so flash the firmware from https://github.com/ytai/ioio/raw/master/release/firmware/application/App-IOIO0500.ioioapp

```bash
./ioiodude --port=/dev/IOIO0 --reset write App-IOIO0500.ioioapp
Comparing fingerprints...
Fingerprint mismatch.
Writing image...
[########################################]
Writing fingerprint...
Done.
```

Check the version again

```bash
./ioiodude --port=/dev/IOIO0 versions
IOIO Application detected.

Hardware version: SPRK0020
Bootloader version: IOIO0400
Application version: IOIO0500
```

Firmware updated successfully! Wish I could learn something with this small thing.
