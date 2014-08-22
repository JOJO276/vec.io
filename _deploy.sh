#!/bin/sh

rsync -avvu --delete-after --delete-excluded _site/ webapp@vec.io:apps/vec.io/current/public/
rsync -avvu --delete-after --delete-excluded _config/ webapp@vec.io:apps/vec.io/current/config/
