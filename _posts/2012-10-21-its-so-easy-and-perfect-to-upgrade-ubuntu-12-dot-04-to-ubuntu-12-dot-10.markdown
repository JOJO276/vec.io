---
layout: post
title: "It's So Easy and Perfect to Upgrade Ubuntu 12.04 to Ubuntu 12.10"
date:   2012-10-21 14:33:23
---

The first day I learnt that Ubuntu 12.10 is released, I upgraded my Ubuntu 12.04 LTS to the latest version (I installed Ubuntu as the only OS for my MacBook Pro 8,1). Have been using the Ubuntu 12.10 for several days, so far so good, it beats 12.04 in performance and visual effects a lot.


How to upgrade
--------------

I haven't made any special procedures, just hit upgrade in the Ubuntu update manager, click 'OK' and use the default option in every step. If you haven't got the new release notification, please choose 'For any new version' for 'Notify me of a new Ubuntu version' in Software Sources configuration dialog.

However, due to the complexity of an OS, some minor issues still occured.


Unity is crashed during updating
--------------------------------

It's recommended to close all applications before the update, but I don't care it enough, and move the upgrade dialog to another workspace. Suddenly the unity crashed, I couldn't navigate to the upgrade workspace and follow the progress.

So I used `top` to monitor the `dpkg` process status, and finally found it paused. I waited it for few minutes, got none status changes. Then I rebooted my Ubuntu to the new system.


Some packages update failure
----------------------------

After booting into the new Ubuntu, I ran an `apt-get dist-upgrade` command, got following errors:

    Processing triggers for bamfdaemon ...
    Rebuilding /usr/share/applications/bamf.index...
    Errors were encountered while processing:
     dictionaries-common
     aspell
     update-notifier-common
     hyphen-en-us
     aspell-en
     flashplugin-installer
     update-notifier
     ubuntu-desktop
     update-manager
     ubuntu-release-upgrader-gtk

Luckily, the apt-get log provided an instruction to fix this issue:

```bash
sudo /usr/share/debconf/fix_db.pl
sudo dpkg-reconfigure -a
```


Root partition disk space disappeared
-------------------------------------

This is the most annoying problem, I found my root partition `/` had only about 200MB left! I don't want to repeat the efforts I've spent on this issue here, finally I found it's an awesome Btrfs feature, [subvolume](http://en.wikipedia.org/wiki/Btrfs#Subvolumes_and_snapshots).

Ubuntu installation had created an backup of previous 12.04 as a Btrfs subvolume, I don't know if I had been told this by the Update manager, because [I couldn't see it during updating](#toc-unity-is-crashed-during-updating).

So it's easy to free the root partition space:

```bash
$ sudo btrfs subvolume list /
ID 256 top level 5 path @
ID 257 top level 5 path @apt-snapshot-release-upgrade-quantal-2012-10-19_20:29:34

$ sudo btrfs subvolume delete /@apt-snapshot-release-upgrade-quantal-2012-10-19_20:29:34
```

It's wonderful to learn something about Btrfs. I will be taught many new other things everyday, it's the reason why I keep trying new things.

Finally, Ubuntu has become much greater.
