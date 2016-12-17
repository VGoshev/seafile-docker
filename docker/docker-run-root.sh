#!/bin/sh
#set -x
#Seafile initialisation and start script, root user part. 
#This script will fix seafile user home directory permissions 
#  if needed and exec docker-run script


DIR_OWNER=`stat -c '%U' ~seafile`

if [ "$DIR_OWNER" != "seafile" ]; then
	chown -R seafile:seafile ~seafile
fi

#echo "#!/bin/sh" > ~seafile/.passed_env
for i in INTERACTIVE SERVER_NAME SERVER_DOMAIN SEAHUB ; do 
	PASS_ENV="$PASS_ENV $i=` eval echo '$'$i`"
done

#echo $PASS_ENV
exec su -l -c "$PASS_ENV exec /bin/docker-run" seafile
