---
layout: post
title: "Web Development Tricks and Traps from Building MeT and Repo.IO"
date:   2013-08-08 18:43:27
---

The last two weeks, I've been busy building a Markdown and $LaTeX$ editor, [MeT](https://met.repo.io), alongside an image uploading service, [IO](https://i.repo.io), to provide MeT the inline images insertion feature. Cause I've been always an mobile and server side developer, to develop these two rich client products involves me quite a lot efforts.

I will update this post constantly to include all the common tricks and traps I met in developing Web client side products. Of course, this post is written with **MeT**.



HTML Tips
---------

With the new HTML5 specification, some tasks can be easily and efficiently achieved with proper HTML markup and attribute, without the old JavaScript way.


### Filter file types

In IO, I allow users to upload images only, so the file chooser only need to list images, without other annoying files, the [`accpet`](http://www.w3.org/html/wg/drafts/html/master/forms.html#attr-input-accept) attribute can help.

```html
<input type="file" accept="images/*" />
```

This is only intended to improve the user experience, don't reply its result, additional JavaScript and server side validation is required.


### Open links in the same tab

I must admit that I only knew the `target="_blank"` usage. Indeed, it can accept a name, then the links with the same name would be opened in the same tab or window.

```html
<a href="https://vec.io" target="vecio">...</a>
```



CSS Tricks
----------

Though I'm building the products mainly with JavaScript, sometimes the CSS can make things easier and achieve better performance.


### Make an element center

It's a common task for me to create only one simple HTML page, with a product logo in the center of the screen, no matter the screen size.

```html
<body>
  <div id="app">
  </div>
</body>
```

The trick is to make the element top and left border in the vertical and horizontal middle, then shift it top and left with its half of height and width.

```css
body {
  position: relative;
  overflow: hidden;
  width: 100%;
  padding: 0;
  margin: 0;
}

#app {
  position: absolute;
  width: 640px;
  height: 512px;
  left: 50%;
  top: 50%;
  margin-left: -320px;
  margin-top: -256px;
  text-align: center;
}
```


### Opt child elements out in Drag & Drop

Drag and Drop is a great HTML5 feature, without the actual using in real product, I won't know it's so easy to use, but it does have traps.

```html
<div id="dnd-target">
  <p>Drop images here</p>
</div>
```

In the above code, if mouse enter the area of the child elements of `#dnd-target`, i.e. `<p>`, then the `ondragleave` event of `dnd-target` will be triggered, in most scenarios, it's not what I want. To prevent that with JavaScript is a bit difficult, but the CSS property [`pointer-events`](https://developer.mozilla.org/en-US/docs/Web/CSS/pointer-events) can do the trick.

```css
#dnd-target p {
  pointer-events: none;
}
```



JavaScript
----------

Never write so many JavaScript code, in the last two weeks, I have learnt many things about JavaScript, knew its limitation, got some tricks and obstacles, and learnt to write modular JavaScript code.


### DOM creation

Create a DOM in pure JavaScript, or with the jQuery or Zepto library, will cause the browser to evaluate the HTML code, fetch all external resources and run the JavaScript code.

```javascript
var doc = $('<div/>').html('<img src="http://some-404-resource" />');
```

The code above will cause error in browser console _NetworkError: 404 Not Found_, because the HTML code is evaluated, though not inserted to the page. To prevent that, use the following [code](http://stackoverflow.com/questions/11966960/dom-parsing-in-javascript).

```javascript
var doc = document.implementation.createHTMLDocument('');
doc.documentElement.innerHTML = '<div><img src="http://some-404-resource" /></div>';
```


### Prevent text selection after double click

I've used mouse double click to trigger some event for several times, but alongside the normal function, the text would be selected, even after `event.preventDefault()`. To disable this behavior, I need to prevent the `mousedown` event.

```javascript
$('#dnd').mousedown(function(e){e.preventDefault();});
```


### Prevent default file drop event

When drag and drop a file into browser window, the browser will try to open the file, this behavior is weird.

```javascript
window.addEventListener("dragover",function(e){
  e.preventDefault();
},false);
window.addEventListener("drop",function(e){
  e.preventDefault();
},false);
```


### HTTP Headers and XHR

Though XMLHttpRequest2 has grown rapidly, but according to the specification, many useful HTTP headers can't be set with XHR.

> Nothing MUST be done if the header argument matches Accept-Charset, Accept-Encoding, Content-Length, Expect, Date, Host, Keep-Alive, Referer, TE, Trailer, Transfer-Encoding or Upgrade case-insensitively.

Regarding the specification, browsers just give different behaviors, Chrome will output errors to warn the developers in developer console, but Firefox does nothing.

One notable header is `Expect: 100-Continue`, it's very useful when building file uploading service, but Chrome and [Firefox](https://bugzilla.mozilla.org/show_bug.cgi?id=803673) don't support that, while Opera may support it according their [dev site](http://dev.opera.com/articles/view/xhr2/).


### HTTP Headers and Base64

The HTTP headers only accept ASCII, so if I want to pass some Unicode characters , e.g. a file name, I could encode the data in [Base64](https://developer.mozilla.org/en-US/docs/Web/API/window.btoa).

```javascript
var b64 = btoa(unescape(encodeURIComponent(file.name)))
```

For reference, to decode that in server side Ruby code

```ruby
URI.decode(CGI.escape(Base64.decode64(b64))).force_encoding('UTF-8')
```


### XHR and FileReader

The `FileReader` API with the XHR2 features make file uploading much easier, developers can create better uploading experience with several lines JavaScript code.

We can get files from traditional file selecting `input` or the `ondrop` event, and monitor the `progress` event from `xhr.upload` to display uploading progress.

```javascript
var files = inputEvent.target.files || dropEvent.dataTransfer.files.

for (var i = 0; i < files.length; i++) {
	var xhr = new XMLHttpRequest();
  xhr.upload.addEventListener('progress', function(e){});
  xhr.open('POST', "https://i.repo.io", true);
  xhr.send(files[i]);
}
```

To facilitate the user experience, the `createObjectURL` can be used to provide image preview.

```javascript
img.src = URL.createObjectURL(file);
```

The `FileReader` API can be used with server side to enable chunked uploading, e.g. read file with `readAsBinaryString`, then `send` different parts of the buffer concurrently, finally concat them at server side.


### CAN NOT DO

Have struggled to achieve something, but found them impossible.

1. The developer can't program how the URL is opened, in a tab or in a window.
2. In all browsers, IndexedDB is not supported by Web Worker, no matter the synchronous or asynchronous mode, though the specification said it should do.
3. Can't copy to clipboard without plugins, though an API is under proposal http://www.w3.org/TR/clipboard-apis/.



Web server
----------

The post is about client side programming, but something just can't work with these basic setups in server side.


### Nginx CORS configuration

Follow the guide from MDN [HTTP access control (CORS)](https://developer.mozilla.org/en-US/docs/HTTP/Access_control_CORS), it's supposed to be very easy to add proper headers in Nginx configuration, but I've failed for lots of times, because [Nginx If Is Evil](http://wiki.nginx.org/IfIsEvil).

```nginx
location / {
    add_header     Access-Control-Allow-Origin      $http_origin;
    add_header     Access-Control-Allow-Credentials true;

    if ($request_method = 'OPTIONS') {
      add_header     Access-Control-Allow-Origin      $http_origin;
      add_header     Access-Control-Allow-Credentials true;
      add_header     Access-Control-Allow-Methods     'GET, POST, OPTIONS';
      add_header     Access-Control-Allow-Headers     'DNT, X-API-KEY, X-API-SECRET, Content-Type, Content-Range, Content-Disposition, Content-Description';
      add_header     Access-Control-Max-Age           1728000;
      add_header     Content-Type                     text/plain;
      add_header     Content-Length                   0;
      return 204;
    }
}
```
