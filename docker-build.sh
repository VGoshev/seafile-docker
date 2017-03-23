#!/bin/sh

cd `dirname $0`

ARCH=`uname -m`
IMAGE="sunx/seafile"

if `echo $ARCH | grep -q arm`; then
	#Use armhf/alpine as base image instead of alpine
	sed -r 's,(FROM)\s+(alpine),\1 armhf/\2,' < ./docker/Dockerfile > ./docker/Dockerfile.arm

	docker build -t $IMAGE -f ./docker/Dockerfile.arm ./docker/
	#&& rm -rf ./build
else
	if `echo $ARCH | grep -q x86_64`; then
		docker build -t $IMAGE ./docker/
	else 
		echo "Error: Architecture $ARCH isn't supported"
		exit 1
	fi
fi

