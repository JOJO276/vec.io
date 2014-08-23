---
layout: post
title: "Valo - Open Source Viewer for Panorama Video and Image"
date:   2013-07-21 04:51:13
---

The internet are populated by more and more panorama images thanks to Android and iPhone, even panorama videos are beginning to snap people's eyes. But I can't find an easy tool to view those contents, most guys are working hard to create panorama camera or recorder, but won't pay enough attention to the viewer development.

So, Valo ([name source](http://en.wiktionary.org/wiki/valo)) comes, just some sample code, only works on Linux desktop now, but I want to keep improving it, written with C and OpenGL, makes it portable to Mac OSX, Android, iOS, and even Windows. And it's [open source](http://github.com/vecio/Valo), anybody may contribute.

To make it easy for other developers to join me, here I'd love to share some basic techniques used in Valo.


Image and video decoding
------------------------

Decoding images is easy, you may find many one-line solutions to read all pixels out of a picture with any format. However, when comes to video, the situation becomes much much harder.

![Video_Player_Architecture.png]({{ '/images/2013/07/21/Video_Player_Architecture.png' | prepend: site.url }})

As the figure shown above, to play a video using the gorgeous FFmpeg library, you need many steps and multiple threads to synchronize. Of course, there're also one line libraries to handle video playback, but we must do it the hard way, cause we need to do many custom post processing.

It's such a large topic that I won't expand more details. To learn FFmpeg, I recommend the famous but outdated [FFmpeg tutorial](http://dranger.com/ffmpeg/), accompany with some up-to-date [sample code](https://github.com/chelyaev/ffmpeg-tutorial). At the time of writing this post, [Valo's source code](https://github.com/vecio/Valo/tree/c0d488f4ae3d6aca891ee8921badb6ed7befdbe6) is very easy, you may get something from the _player.c_.


Panorama and OpenGL textures
----------------------------

As I know, there're three main kinds of panoramic images, spherical, cylindrical and cubic. It was thought only simple texture mapping to display the decoded panorama images, but I found it difficult to handle correct perspective and to calculate the texture coordinates.

This is the real hard work for me, to give the texture a seamlessly looking. In the demo stage, I try to use a simpler logic to make the program work. I model the background as a large spherical mesh, with the panoramic image as 2D texture, and the texture coordinates are calculated as the latitude and longitude of the mesh.

$\bigg\{ \begin{aligned}
u & = (1 + atan2(y,x) \div \pi) \times 0.5 \\
v & = (1 - z) \times 0.5
\end{aligned}$

The formula above assumes z-axis as the up vector, results in some realistic viewing, but the scene is warped at two sphere poles. The eventually work should benefit from an improved algorithm to transform the panoramic image texture coordinates to a plane, http://en.wikipedia.org/wiki/Map_projection.
