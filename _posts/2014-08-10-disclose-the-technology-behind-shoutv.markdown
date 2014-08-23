---
layout: post
title: "Disclose the Technology Behind Shou.TV"
date:   2014-08-10 08:53:34
---

In case you are not in the same group with those amazing young gamers from 2000s, I have pasted a snapshot of my personal [Shou.TV](https://shou.tv/vecio) page here, streaming Clash of Clans from my HTC One.

![Shou.TV.png]({{ '/images/2014/08/10/Shou.TV.png' | prepend: site.url }})

As Shou.TV is quite a large project, I will mainly describe the basic technology choices in server side, without thorough details for each technology usage.


TL;DR
-----

We use a custom protocol SLSP based on WebSocket to do broadcasting or live streaming. All components are proxied with nginx and deployed on Ubuntu servers, they communicate with each other through HTTP and JSON.

![Shou.TV_Broadcasting_Architecture.png]({{ '/images/2014/08/10/Shou.TV_Broadcasting_Architecture.png' | prepend: site.url }})


Technologies
------------

Here at Shou.TV, we have several engineering rules, and we try our best to stick to these rules in every development activity.

**Use the best available solutions before building our own one.** We engineers are loving to build everything by ourselves, but to make a product, we need to build everything quickly and ensure the stability.

**Master the core technology by ourself.** If we are using a third-party solution in our core architecture, we should try our best to understand every aspects. If we can't, or it doesn't deserve, just build our own solution.

**Don't bind the core technology to a specific vendor.** We should ensure the ability to migrate our solution to any servers, etc.

**Build everything other than the core technology as quickly as possible.** Use every piece of software or solutions available, master it later when we have time.

Following these rules, we used these technologies in Shou.TV

1. Rent lots of VPS from several different vendors, e.g. EC2, GCE, Linode, Rackspace, DigitalOcean, etc.
2. Ubuntu 14.04 LTS. It has the latest software and not so "stable" as the CentOS kind.
3. Place nginx and SSL before every request, including website, API, chat room and broadcasting server.
4. MongoDB as the main database.
5. Ruby on Rails for website and API server.
6. Socket.IO and Redis for chat room.
7. SLSP (Simple Live Streaming Protocol) is our custom broadcasting protocol based on WebSocket, implemented with Node.js and FFmpeg.
8. Use HLS as the technology for video live streaming and archived video playback. Video.js as the web player and custom Android video player.
9. Google Cloud Storage for archived streaming clips.
10. Amazon S3 for small assets storage, e.g. user avatars.
11. Use git to manage code and deploy with Capistrano.



Website and API
---------------

We use the latest Ruby on Rails and Unicorn to develop the website and API for clients, all access are proxied with nginx and SSL. We use more and more memcached while the users growing. And the database is a MongoDB cluster.

We haven't experienced high volume visits yet, so we can't ensure the availability while users flood in. But we have designed the full architecture behind AWS Route 53 and Elastic Load Balancing or GCE Network Load Balancing.


Chat Room
---------

The chat room is a simple Socket.IO server cluster behind Load Balancing, which uses a Redis cluster to distribute the messages, and the chat room uses the same cookie and session with the main website to do user authentication.

The web chat interface uses the Socket.IO client library, iScroll.js and the simple jsrender template library.

We use the AndroidAsync library to build the Android chat room, as it has several issues, we have made some hacks on it.


Broadcasting Server
-------------------

We defined a custom live streaming protocol, SLSP, based on WebSocket, and implemented it with only about 1 thousand lines of code in Node.js and C.

The reason, RTMP is damn old and hard to understand, difficult to utilize the large available solutions built for HTTP, it's just a "stable" bullshit compared to WebSocket or SLSP. I have several years of experience in multimedia development, still feel difficult to fix the issues or implement custom features in Wowza or any currently available RTMP servers.

The web is innovating quickly, HTTP is a much maturer protocol and much easier to understand for everybody. We have many high performance open source HTTP servers, e.g. nginx, which features very high performance while keeps high stability.

WebSocket is a long connection protocol, which is very suitable to do video streaming. It's supported by all modern browsers and SSL is built in without any additional coding from both client and server side. Most firewalls will allow WebSocket connection because it uses the same 443 port as HTTPS.

SLSP is as simple as a WebSocket chat room, just deploy the server after nginx proxy, as soon as a WebSocket client publishes continuous video stream to the server, it will segment the stream to HLS TS segments, then any publicly available HLS video player can play the stream!

Because SLSP is based on WebSocket, which can use many available high performance solutions for HTTP, so we have built a very robust intelligent load balancer. As shown in the above figure [Shou.TV Broadcasting Architecture]({{ '/images/2014/08/10/Shou.TV_Broadcasting_Architecture.png' | prepend: site.url }}), whenever we boot a new SLSP server, it will register itself to the load balancer. Each SLSP server will constantly ping the balancer with its state, mainly the server load.

Once a SLSP client wants to broadcast, it first request a SLSP server address from the load balancer, the balancer will choose a most suitable SLSP server based on the latency and server load, then the client can publish video stream to the SLSP server directly.

Whenever the load balancer experiences high load, it can build a new SLSP server automatically in several minutes, and we're still improving this. The balancer can also remove free SLSP servers to save costs.

After broadcasting finished, the server will upload the full streaming segments to the Google Cloud Storage for future playback.


To Be Updated
-------------

Shou.TV is still a very new project, it only has a few users, so we haven't verified this architecture under high load. We will keep improving and publishing more details constantly.
