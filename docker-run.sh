#!/bin/sh
#Run seafile docker container with host folder as a volume

#Default volume path on host.
VOLUME_PATH="/home/docker/seafile"
#Or you can add it to ~/.docker-sunx-seafile file
[ -f ~/.docker-sunx-seafile ] && source ~/.docker-sunx-seafile

docker run -ti -v $VOLUME_PATH:/home/seafile -p 127.0.0.1:8000:8000 -p 127.0.0.1:8082:8082 sunx/seafile
