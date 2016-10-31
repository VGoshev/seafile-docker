#!/bin/sh
set -x
#Seafile initialisation and start script, root user part. 
#This script will fix seafile user home directory permissions 
#  if needed and exec docker-run script


DIR_OWNER=`stat -c '%U' ~seafile`

if [ "$DIR_OWNER" != "seafile" ]; then
	chown -R seafile:seafile ~seafile
fi

exec su -l -c 'exec /bin/docker-run' seafile
