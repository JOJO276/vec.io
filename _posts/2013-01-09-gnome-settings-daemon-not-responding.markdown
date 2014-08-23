---
layout: post
title: "GNOME Settings Daemon Not Responding"
date:   2013-01-09 07:58:37
---

Just indicated as the title, I encountered this problem again, but forgot how to fix it at last time. This problem caused most of my keyboard shortcuts didn't work and I couldn't even log out.

![Gnome_Settings_Daemon.png]({{ '/images/2013/01/09/Gnome_Settings_Daemon.png' | prepend: site.url }})

As the screenshot shown above, the volume applet was also stuck. I'm confused by these problems, because I haven't changed any configurations of any softwares, or haven't upgraded my system either.

If I logged in as guest, everything worked very well, so I tried to restore every GNOME related configuration files to default by deleting them, such as _~/.config_, _~/.compiz_, _~/.gconf_ or _~/.local_. But nothing helped, even the powerful 'reboot' didn't work any more.

Then I seeked to find the log file of `gnome-settings-daemon`, without clues but a bug report from launchpad, [gnome-settings-daemon extensive disk usage](https://bugs.launchpad.net/bugs/505085), it helped to resolve my problem.

```bash
sudo strace -p $(pidof gnome-settings-daemon)
```

The missing `strace` tool tell me the _~/.pulse_ directory was causing `gnome-settings-daemon` stuck. So deleted it, everything back.

```
nanosleep({0, 10000000}, NULL)          = 0
readlink("/home/vecio/.pulse/597c3768236921d57286be880000000d-runtime", "/tmp/pulse-LJLJZtJLWpLE"..., 99) = 23
lstat("/tmp/pulse-LJLJZtJLWpLE", 0x7fff3c09c510) = -1 ENOENT (No such file or directory)
umask(077)                              = 02
mkdir("/tmp/pulse-euJOZCPFqcfT", 0700)  = 0
umask(02)                               = 077
symlink("/tmp/pulse-euJOZCPFqcfT", "/home/vecio/.pulse/597c3768236921d57286be880000000d-runtime.tmp") = -1 EEXIST (File exists)
rmdir("/tmp/pulse-euJOZCPFqcfT")        = 0
```

Finally I reported a bug to launchpad as [#1097608](https://bugs.launchpad.net/bugs/1097608).
