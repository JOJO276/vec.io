---
layout: post
title: "Jekyll Clean URLs with Nginx"
date:   2014-08-22 09:35:59
---

Just generated the Shou.TV blog with Jekyll, I want to use a unique URL for each post like https://blog.shou.tv/the-technology-behind-shoutv, without any alternatives e.g. a .html extension, a trailing slash at the end or a trailing slash followed by index.html.

It's easy to achieve this objective with a simple nginx rule. At first, configure the Jekyll permalink style in _\_config.yml_

```yaml
permalink: /:title
```

The nginx configuration rules are quite simpler than expected:

```nginx
rewrite ^/index.html$ / permanent;
rewrite ^(/.+)/$ $1 permanent;
rewrite ^(/.+)/index.html$ $1 permanent;

location / {
  try_files $uri $uri/index.html =404;
}
```

This will redirect all other URL alternatives to the exact same URL.

Inspired by http://rickharrison.me/how-to-remove-trailing-slashes-from-jekyll-urls-using-nginx
