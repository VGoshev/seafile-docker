#!/bin/sh
#Run seafile docker container with host folder as a volume

#Default volume path on host.
VOLUME_PATH="/home/docker/seafile"
#Container hostname
CONTAINER_HOSTNAME="seafile.domain.com"
#Container name
CONTAINER_NAME="seafile"
#Restart policy
RESTART_POLCY="unless-stopped"
#Some extra arguments. Like -d ant -ti
EXTRA_ARGS="-d -ti"

#You can change default values by adding them to config file ~/.docker-sunx-seafile
[ -f ~/.docker-sunx-seafile ] && source ~/.docker-sunx-seafile

[ ! -z "$CONTAINER_HOSTNAME" ] && CONTAINER_HOSTNAME="--hostname=$CONTAINER_HOSTNAME"
[ ! -z "$CONTAINER_NAME" ]     && CONTAINER_NAME="--name=$CONTAINER_NAME"
[ ! -z "$RESTART_POLCY" ]      && RESTART_POLCY="--restart=$RESTART_POLCY"

docker run -v $VOLUME_PATH:/home/seafile -p 127.0.0.1:8000:8000 -p 127.0.0.1:8082:8082 $CONTAINER_HOSTNAME $CONTAINER_NAME $RESTART_POLCY $EXTRA_ARGS sunx/seafile
