#!/bin/sh

rsync -avvu --delete-after --delete-excluded _site/ webapp@vec.io:apps/vec.io_jekyll/current/public/
rsync -avvu --delete-after --delete-excluded _config/ webapp@vec.io:apps/vec.io_jekyll/current/config/
