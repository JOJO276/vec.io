---
layout: post
title: "Google Cloud Storage Images Processing"
date:   2014-10-08 15:29:39
---

There are plenty of images processing work in Shou.TV, especially the snapshots of video streams. Instead of building our own distributed image service, we plan to use Google App Engine, as we have already put most of our videos and snapshots on the Google Cloud Storage.

It's easy to use the Google Cloud Platform, but it's painful in the learning procedure. Google provides us a powerful service to scale images stored in GCS, but it's really difficutl to figure out how to use this simple service.




Development environment
-----------------------

Google favors Python, notably Python 2. I use Arch Linux, so I need to change the Python environment

```bash
virtualenv2 .
source bin/activate
```

Then install the google-cloud-sdk and sign in. I selected Python and PHP environment for the GAE development.

```
curl https://sdk.cloud.google.com/ | bash
gcloud auth login
```




Setup GAE project
-----------------

Start a GAE instance and download the sample Python flask project. I'm not a Python programmer, but this seems to be the most simple solution to use GAE. Then just modify the default route according to the `get_serving_url` document at https://developers.google.com/appengine/docs/python/images.

```python
@app.route('/<path:img_key>')
def img(img_key):
    key = create_gs_key('/gs/bucket-name/%s' % img_key)
    url = get_serving_url(key, crop=False, secure_url=True)
    return url
```

I don't have any previous GAE knowledge, so I just figure out a single command to deploy the project

```bash
appcfg.py -A gae-app-id update root-path-of-the-project
```

After the project deployed, `https://gae-app-id.appspot.com/img_key` will return a permanent magic URL to the image stored in the GCS. If you append `=s128` to the magic URL, the image will be instantly scaled to 128.

But it may not work as expected...




Google Cloud Storage ACL
------------------------

When it doesn't work, it's mostly [ACL](https://developers.google.com/storage/docs/accesscontrol). We need to give the GAE instance owner permission to the GCS bucket and all existing and upcoming images.

Find the GAE _Service Account Name_ from the old GAE console https://appengine.google.com/, usually `gae-app-id@appspot.gserviceaccount.com`. Then give this user the default owner permission.

```bash
gsutil defacl ch -g gae-app-id@appspot.gserviceaccount.com:O \
         gs://bucket-name
```

And for all existing images which need to be processed.

```bash
gsutil -m acl ch -R -u gae-app-id@appspot.gserviceaccount.com:O \
         gs://bucket-name/*.png
```

If the bucket is public, it's better to grant `AllUsers` read permission.

```bash
gsutil defacl ch -g AllUsers:R gs://bucket-name
```

This will simplify our client uploading logic, because it's a bit weird to change file access permission from client side library, e.g. the Ruby Fog gem will override the default permissions if you specify `public: true`.
