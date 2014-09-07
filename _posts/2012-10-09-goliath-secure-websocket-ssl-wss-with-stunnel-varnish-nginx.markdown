---
layout: post
title: "Goliath Secure WebSocket (wss://) with Stunnel, Varnish and Nginx"
date:   2012-10-09 08:40:48
---

UPDATE: [NGINX Announces Support for WebSocket Protocol](http://nginx.com/news/nginx-websockets.html) in nginx 1.3, on February 19, 2013.

Niginx don't support websocket, so I choosed varnish to serve it as a frontend. But Varnish don't support SSL, then [stunnel](http://www.stunnel.org/) comes to rescue it.


Goliath
-------

I've built a chat room with Goliath WebSocket, secured by a simple authentication system with warden middleware, you can find details at [Goliath authenticate with Warden](http://vec.io/posts/use-warden-to-authenticate-in-ruby-goliath).

Then I can start the Goliath app with a simple command:

```bash
bundle exec ruby app.rb -p 5000 -P /tmp/goliath.pid -l log/production.log -e production -d
```

After that, the app should daemonize to serve all the HTTP and WebSocket request in TCP port 5000, so I can drop all HTTP and WebSocket requests to http://vzine.us:5000.

However, in a world where Google and Facebook are both secured with HTTPS, why not my site? It's easy to add SSL support to Goliath app, see its options:

```bash
SSL options:
      --ssl                        Enables SSL (default: off)
      --ssl-key FILE               Path to private key
      --ssl-cert FILE              Path to certificate
      --ssl-verify                 Enables SSL certificate verification
```

But, I need more, I like my site to be accessed from https://vzine.us with the default HTTPS port 443, and I hate https://vzine.us:5000.

I need a proxy.


Nginx
-----

I've used nginx to serve all my Rails and PHP service all the time, so it flashed at first when I thought about proxy. And it's quite easy to configure nginx:

```nginx
upstream vzine_us_server {
  server 0.0.0.0:5000;
}

server {
  listen 80;
  server_name vzine.us www.vzine.us;
  rewrite ^/(.*)$ https://$host/$1 permanent;
}

server {
  listen 443;
  server_name vzine.us www.vzine.us;
  ssl on;
  ssl_certificate /home/webapp/apps/sample.app/config/certs/server.crt;
  ssl_certificate_key /home/webapp/apps/sample.app/config/certs/server.key;

  root /home/webapp/apps/vzine.us/public/;
  index  index.html index.htm;

  error_log /home/webapp/logs/vzine.us/nginx_error.log;
  access_log /home/webapp/logs/vzine.us/nginx_access.log;

  if ($host = "www.vzine.us") {
    rewrite  ^/(.*)$  https://vzine.us/$1  permanent;
  }

  location / {
    proxy_set_header  X-Real-IP  $remote_addr;
    proxy_set_header  X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header  X_FORWARDED_PROTO https;
    proxy_set_header  Host $http_host;
    proxy_redirect off;

    try_files /maintenance.html $uri $uri/index.html $uri.html @goliath;
}

  location @goliath {
    proxy_pass http://vzine_us_server;
  }
}
```

According to my experience, I could access https://vzine.us to start my chat at this point. But it failed at the WebSocket part, though I can visit the authentication with all the normal HTTP pages.

Check Goliath's production.log, I get the errors below:

```bash
[4344:INFO] 2012-10-09 02:32:00 :: GET - /ws
[4344:ERROR] 2012-10-09 02:32:00 :: Connection and Upgrade headers required
```

It seems that nginx can't manipulate the HTTP Upgrade headers properly, which is needed by [WebSocket specification](http://tools.ietf.org/html/rfc6455). Indeed, WebSocket is on nginx 1.3 [roadmap](http://trac.nginx.org/nginx/roadmap).


Varnish
-------

Varnish is a caching HTTP reverse proxy. Although it's used in front of web HTTP servers such as nginx, Varnish can also handle several nginx's works such as nginx's `proxy_pass`, with WebSocket support added.

So we can configure Varnish in front of nginx and Goliath, and only pass normal HTTP requests to nginx, while WebSocket's to Goliath directly.

```nginx
backend default {
  .host = "127.0.0.1";
  .port = "8080";
}
backend goliath {
  .host = "127.0.0.1";
  .port = "5000";
}

sub vcl_recv {
  set req.backend = default;

  if (req.http.x-forwarded-for) {
    set req.http.X-Forwarded-For = req.http.X-Forwarded-For ", " client.ip;
  } else {
    set req.http.X-Forwarded-For = client.ip;
  }

  if (req.http.upgrade ~ "(?i)websocket") {
    set req.backend = goliath;
    return (pipe);
  }

  return (lookup);
}

sub vcl_pipe {
  if (req.http.upgrade) {
    set bereq.http.upgrade = req.http.upgrade;
  }
  return (pipe);
}
```

Then start Varnish with the following command:

```bash
varnishd -P /var/run/varnishd.pid -a :6081 -T localhost:6082 \
   -f /etc/varnish/default.vcl -S /etc/varnish/secret -p pipe_timeout 86400 \
   -s file,/var/lib/varnish/sample/varnish_storage.bin,1G
```

Note the **`-p pipe_timeout 86400`** param, it's important to set a long timeout to keep your WebSocket chat room alive for a long time, or the connection will disconnect each 60 seconds by default.

The nginx configuration needs some small modifications too, change `listen 443` to `listen 127.0.0.1:8080` and remove the four lines below:

```nginx
ssl on;
ssl_certificate /home/webapp/apps/sample.app/config/certs/server.crt;
ssl_certificate_key /home/webapp/apps/sample.app/config/certs/server.key;

proxy_set_header  X_FORWARDED_PROTO https;
```

At this point, I can visit my chat room at http://vzine.us:6081, it's the port Varnish is listening.

In this step we get an normal HTTP address with an ugly 6081 port, but all will be OK after we setup the Stunnel.


Stunnel
-------

When coming to SSL, we need something called certificate or key. In the [nginx](#toc-nginx) configuration above, we used *server.crt* and *server.key*, but a pem file should be used in the Stunnel configuration. What is the difference between .csr, .crt, .key and .pem files? [A heroku article](https://devcenter.heroku.com/articles/ssl-file-extensions) describes it short and clearly.

So we can create a *server.pem* based on *server.crt* and *server.key*

```bash
cat server.crt server.key > server.pem
```

Then we configure Stunnel to use the server.pem to encrypt and decrypt our HTTP and WebSocket streams.

```
chroot = /var/lib/stunnel4/
setuid = stunnel4
setgid = stunnel4

pid = /stunnel.vzine.us.pid
cert = /home/webapp/apps/vzine.us/config/certs/server.pem

[https]
accept  = 443
connect = 6081
TIMEOUTclose = 0
```

The configuration above is very simple based on the example Stunnel configuration. After we start Stunnel, it will listen port 443, and decrypt all SSL content to normal data, then pass to port 6081, which is the port Varnish is listening.

Finally, I can visit my chat room at https://vzine.us.

**NOTE**: don't start Goliath app with SSL options, because all the SSL stuff will be managed by Stunnel.


Conclusion
----------

Let's get a bird's-eye view on how Stunnel, Varnish, Nginx and Goliath fit to each other.

1. We access https://vzine.us from a browser, it's a normal HTTP request without WebSocket.
2. Stunnel is listening 443 port, so it will decrypt the request and pass it to Varnish port 6081.
3. Varnish checks the content be normal HTTP, will deliver it to nginx's 8080 port, and nginx will serve it happily.
4. When the chat room page rendered, some JavaScript statements will invoke `new WebSocket("wss://vzine.us/ws")`, it's a secure WebSocket request.
5. Stunnel will work again to decrypt the request content and pass it to Varnish port 6081.
6. Varnish finds the request is WebSocket, and pass it to Goliath 5000 port.

BTW, [nginx_tcp_proxy_module](https://github.com/yaoweibin/nginx_tcp_proxy_module) is a third party module to add WebSocket support to nginx.
