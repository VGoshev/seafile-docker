#!/bin/sh

#Do debug output in case of debug
[ "x$DEBUG" = "x1" ] && set -x

#Seafile initialisation and start script
VERSION_FILE=".seafile_version"

#Be sure, that python path variable is loaded
source /etc/profile.d/python-local.sh   

# Make sure, that /usr/local/bin is in PATH
# The PATH-variable depends on the host's setting. /usr/local/bin may not be included in every distro
export PATH="${PATH}:/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin:/usr/local/sbin"

SEAFILE_VERSION=$(cat /var/lib/seafile/version)
if [ -z "$SEAFILE_VERSION" ]; then
	echo "can not find Seafile version in file /var/lib/seafile/version, probably corrupted image"
	exit 1
fi

# If it is interactive run or not, by default - yes.
# It will affect configuration and update stages
[ -z "$INTERACTIVE" ] && INTERACTIVE=1
[ "x$INTERACTIVE" != "x1" ] && INTERACTIVE=0

#Just in case
cd $HOME

#########################
# Some useful functions #
#########################

start_seafile_server() {
	if [ "$SEAHUB" == "fastcgi" ]; then
		seafile-admin start --fastcgi
	else
		seafile-admin start
	fi
}

stop_seafile() {
	echo "Stopping Seafile..."
	cd ${HOME}
	seafile-admin stop
	# We need to wait a bit to make sure that
	#  seafile server really has been stopped
	sleep 5 
	exit 0
}

hup_seafile() {
	echo "SIGHUP or similar received, restarting Seafile..."
	cd ${HOME}
	seafile-admin stop
	sleep 10
	start_seafile_server
}

if [ ! -d 'seafile-server' ]; then
	mkdir seafile-server
	RES=$?
	#If we wasn't able to create directory then,
	#  probably permissions for $HOME are wrong
	if [ $RES -ne 0 ]; then
		cat >&2 <<-EOM
			ERROR: Can't create directory $HOME/seafile, probably bad permissions
			To fix permissions, you can run:
			docker run --rm -v <mount_point>:$HOME --user=0 <image> chown seafile:seafile $HOME
		EOM
		exit 1
	fi
fi

# Fix seahub dir if needed
[ ! -d 'seafile-server/seahub' ] && mkdir -p seafile-server/seahub && \
	tar xzf /usr/local/share/seafile/seahub.tgz -C seafile-server/seahub

#Seafile-server related enviroment variables
export CCNET_CONF_DIR=${HOME}/ccnet
export SEAFILE_CONF_DIR=${HOME}/seafile-data
export SEAFILE_CENTRAL_CONF_DIR=${HOME}/conf

#We do not want to reset admin password. probably
RESET_ADMIN=0

# If there is $VERSION_FILE already, then it isn't first run of this script, 
#  do not need to configure seafile
if [ ! -f $VERSION_FILE ]; then
	echo 'No previous version on Seafile configurations found, starting seafile configuration...'


	# Init ccnet
	if [ ! -d 'ccnet' ]; then
		if [ $INTERACTIVE -eq 1 ]; then
			echo "Enter the name of the server  (3 - 15 letters or digits)"
			echo -n "[server name ]: "
			read SERVER_NAME

			echo "Enter the domain OR ip of the server?  (For example: www.mycompany.com, 192.168.1.101)"
			echo -n "[ip or domain ]: "
			read SERVER_DOMAIN
		else
			[ -z "$SERVER_NAME"   ] && SERVER_NAME="Seafile"
			[ -z "$SERVER_DOMAIN" ] && SERVER_DOMAIN="seafile.domain.com"
		fi

		ccnet-init -F ${HOME}/conf -c ${HOME}/ccnet --name "$SERVER_NAME" --port 10001 --host "$SERVER_DOMAIN" || exit 3
		echo '* ccnet configured successfully'
	fi

	# Init seafile
	if [ ! -d 'seafile-data' ]; then
		seaf-server-init -F ${HOME}/conf --seafile-dir ${HOME}/seafile-data --port 12001 --fileserver-port 8082 || exit 4
		echo "${HOME}/seafile-data" > ${HOME}/ccnet/seafile.ini
		echo '* seafile configured successfully'
	fi

	# Init seahub
	if [ ! -f 'conf/seahub_settings.py' ]; then
		SKEY1=$(uuidgen -r)
		SKEY2=$(uuidgen -r)
		SKEY=$(echo "$SKEY1$SKEY2" | cut -c1-40)
		echo "SECRET_KEY = '${SKEY}'" > ${HOME}/conf/seahub_settings.py

		mkdir -p seahub-data/avatars
		mv -f seafile-server/seahub/media/avatars/* seahub-data/avatars/
		rm -rf seafile-server/seahub/media/avatars
		ln -s ${HOME}/seahub-data/avatars ${HOME}/seafile-server/seahub/media/avatars
		echo '* seahub configured successfully'
	fi

	# Do syncdb anyway, because it willn't corrupt old databse
	python seafile-server/seahub/manage.py syncdb || exit 5
	echo
	echo '* seahub database synchronized successfully'

	#Make Gunicorn config
	if [ ! -f 'seafile-server/runtime/seahub.conf' ]; then
		mkdir "${HOME}/seafile-server/runtime"

		cat >> "${HOME}/seafile-server/runtime/seahub.conf" <<- EOF
			import os
			daemon = True
			workers = 3

			# Logging
			runtime_dir = os.path.dirname(__file__)
			pidfile = os.path.join(runtime_dir, 'seahub.pid')
			errorlog = os.path.join(runtime_dir, 'error.log')
			accesslog = os.path.join(runtime_dir, 'access.log')
		EOF

		echo '* gunicorn configured successfully'
	fi

	# Keep seafile version for managing future updates
	echo -n "${SEAFILE_VERSION}" > $VERSION_FILE
	echo "Configuration compleated!"

	#Say that we want to create admin user after server start
	RESET_ADMIN=1

else
	# Need to check if we need to run upgrade scripts
	echo "Version file found in container, checking it"
	OLD_VER=$(cat $VERSION_FILE)
	if [ "x$OLD_VER" != "x$SEAFILE_VERSION" ]; then
		echo "Version is different. Stored version is $OLD_VER, Current version is $SEAFILE_VERSION"
		if [ -f '.no-update' ]; then
			cat >&2 <<-EOM
				.no-update file found, skipping update.
				You should update user data manually (or delete file .no-update).
				Do not forget to update seafile version in $VERSION_FILE manually after update.
			EOM
		else
			echo "No .no-update file found, performing update..."

			#Copy new seahub
			[ -e 'seafile-server/seahub' ] && mv ${HOME}/seafile-server/seahub ${HOME}/seafile-server/seahub.old
			mkdir -p seafile-server/seahub && \
				tar xzf /usr/local/share/seafile/seahub.tgz -C seafile-server/seahub && \
				[ -e 'seafile-server/seahub.old' ] && rm -rf ${HOME}/seafile-server/seahub.old

			# Copy upgrade scripts. symlink doesn't work, unfortunatelly 
			#  and I do not want to patch all of them
			cp -rf /usr/local/share/seafile/scripts/upgrade seafile-server/
			# Get major and minor version number
			OV1=$(echo "$OLD_VER" | cut -d. -f1)
			OV2=$(echo "$OLD_VER" | cut -d. -f2)
			CV1=$(echo "$SEAFILE_VERSION" | cut -d. -f1)
			CV2=$(echo "$SEAFILE_VERSION" | cut -d. -f2)

			i1=$OV1
			i1p=$i1
			i2p=$OV2
			i2=$(( $i2p + 1 ))
			while [ $i1 -le $CV1 ]; do
				SCRIPT="./seafile-server/upgrade/upgrade_${i1p}.${i2p}_${i1}.${i2}.sh"
				if [ -f $SCRIPT ]; then
					echo "Executing $SCRIPT..."
					if [ $INTERACTIVE -eq 1 ]; then
						$SCRIPT
					else
						echo | $SCRIPT
					fi

					i1p=$i1
					i2p=$i2
					i2=$(( $i2 + 1 ))
				else
					i1p=$i1
					i1=$(( $i1 + 1 ))
					i2=0
				fi
			done

			# Run minor upgrade, just in case (Actually needed when only last number was changed)
			if [ $INTERACTIVE -eq 1 ]; then
				./seafile-server/upgrade/minor-upgrade.sh
			else
				echo | ./seafile-server/upgrade/minor-upgrade.sh
			fi

			rm -rf seafile-server/upgrade
			echo -n "${SEAFILE_VERSION}" > $VERSION_FILE
		fi
	else
		echo "Version is the same, no upgrade needed"
	fi
fi


echo "Starting seafile server..."
start_seafile_server

if [ $RESET_ADMIN -eq 1 ]; then
	# Create admin user only in interactive mode. Just becouse.
	if [ $INTERACTIVE -eq 1 ]; then
		echo "Creating administrator user:"
		python seafile-server/seahub/manage.py createsuperuser
	else
		cat >&2 <<-EOM
			To create administrator user, execute in container:
			python seafile-server/seahub/manage.py createsuperuser
		EOM
	fi
	echo ""
fi

tail -f logs/* seafile-server/runtime/*.log &

trap stop_seafile INT QUIT ABRT ALRM TERM TSTP
trap hup_seafile HUP

wait
