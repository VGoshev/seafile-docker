#!/bin/sh

#Debug!
set -x
set -e

# Fix little bug in alpine image
ln -s /etc/profile.d/color_prompt /etc/profile.d/color_prompt.sh

# Make sure, that /usr/local/bin is in PATH
# The PATH-variable depends on the host's setting. /usr/local/bin may not be included in every distro
export PATH="${PATH}:/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin:/usr/local/sbin"

[ -z $LIBEVHTP_VERSION  ] && LIBEVHTP_VERSION="18c649203f009ef1d77d6f8301eba09af3777adf"
[ -z $LIBSEARPC_VERSION ] && LIBSEARPC_VERSION="3.1-latest"

################################################################
# We'll do all the work here. And delete whole directory after #
################################################################
WORK_DIR="/tmp/seafile"
mkdir -p $WORK_DIR
cd $WORK_DIR

################################
# UID and GID for Seafile user #
################################
[ -z "$uUID" ] && uUID=2016
[ -z "$uGID" ] && uGID=2016

PYTHON_PACKAGES_DIR=$(python -c "from distutils.sysconfig import get_python_lib; print(get_python_lib())")

####################
# Install libevhtp #
####################
wget https://github.com/haiwen/libevhtp/archive/${LIBEVHTP_VERSION}.tar.gz -O- | tar xzf -
cd libevhtp-${LIBEVHTP_VERSION}/
cmake -DEVHTP_DISABLE_SSL=ON -DEVHTP_BUILD_SHARED=ON .
make
make install
cp oniguruma/onigposix.h /usr/include/

###################################
# Download all Seafile components #
###################################
cd $WORK_DIR
wget https://github.com/haiwen/libsearpc/archive/v${LIBSEARPC_VERSION}.tar.gz -O- | tar xzf -
wget https://github.com/haiwen/ccnet-server/archive/v${SEAFILE_VERSION}-server.tar.gz -O- | tar xzf -
wget https://github.com/haiwen/seafile-server/archive/v${SEAFILE_VERSION}-server.tar.gz -O- | tar xzf -
wget https://github.com/haiwen/seahub/archive/v${SEAFILE_VERSION}-server.tar.gz -O- | tar xzf -
wget https://github.com/haiwen/seafobj/archive/v${SEAFILE_VERSION}-server.tar.gz -O- | tar xzf -
wget https://github.com/haiwen/seafdav/archive/v${SEAFILE_VERSION}-server.tar.gz -O- | tar xzf -

#####################################
# Seahub is python application,     #
#  just copy it in proper directory #
#####################################

cd $WORK_DIR/seahub-${SEAFILE_VERSION}-server/
patch -p1 <<-EOP
diff --git a/seahub/settings.py b/seahub/settings.py
index 0b40098..a569b94 100644
--- a/seahub/settings.py
+++ b/seahub/settings.py
@@ -472,7 +472,7 @@ SESSION_COOKIE_AGE = 24 * 60 * 60
 # Days of remembered login info (deafult: 7 days)
 LOGIN_REMEMBER_DAYS = 7

-SEAFILE_VERSION = '6.2.0'
+SEAFILE_VERSION = '${SEAFILE_VERSION}'

 # Compress static files(css, js)
 COMPRESS_URL = MEDIA_URL
EOP
pip install -r requirements.txt

pip install gunicorn flup django-picklefield requests

mkdir -p /usr/local/share/seafile
tar czf /usr/local/share/seafile/seahub.tgz -C $WORK_DIR/seahub-${SEAFILE_VERSION}-server/ ./
###############################
# Build and install libSeaRPC #
###############################
cd $WORK_DIR/libsearpc-${LIBSEARPC_VERSION}/
./autogen.sh
./configure
make
make install

export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig

###########################
# Build and install CCNET #
###########################
cd $WORK_DIR/ccnet-server-${SEAFILE_VERSION}-server/
./autogen.sh
./configure --with-mysql --with-postgresql --enable-python
make
make install

####################################
# Build and install Seafile-Server #
# As a First step we need to patch #
# Seafile-controller topdir        #
# And some scripts                 #
####################################
cd $WORK_DIR/seafile-server-${SEAFILE_VERSION}-server/
patch -p1 < /tmp/seafile-server.patch
./autogen.sh
./configure --with-mysql --with-postgresql --enable-python
make
make install

#Copy some useful scripts to /usr/local/bin
cp scripts/seaf-fsck.sh /usr/local/bin/seafile-fsck
cp scripts/seaf-gc.sh /usr/local/bin/seafile-gc
# Also copy scripts to save them
mv scripts /usr/local/share/seafile/

###########
# SeafObj #
###########
cd $WORK_DIR/seafobj-${SEAFILE_VERSION}-server/
mv seafobj ${PYTHON_PACKAGES_DIR}/

###########
# SeafDav #
###########
cd $WORK_DIR/seafdav-${SEAFILE_VERSION}-server/
mv wsgidav ${PYTHON_PACKAGES_DIR}/

echo "export PYTHONPATH=${PYTHON_PACKAGES_DIR}:/usr/local/lib/python2.7/site-packages/:/usr/local/lib/python2.7/:${SEAFILE_SERVER_DIR}/seafile-server/seahub/thirdpart" >> /etc/profile.d/python-local.sh

ldconfig || true

echo "Seafile-Server has been built successfully!"

##############################
# Do some preparations       #
# Like add Seafile user and  #
#  create his home directory #
##############################

addgroup -g "$uGID" seafile
adduser -D -s /bin/sh -g "Seafile Server" -G seafile -h "$SEAFILE_SERVER_DIR" -u "$uUID" seafile

# Create Seafile-server dir 
su - -c "mkdir ${SEAFILE_SERVER_DIR}/seafile-server" seafile

# Store Seafile version
mkdir -p /var/lib/seafile
echo -n "$SEAFILE_VERSION" > /var/lib/seafile/version

echo "Seafile user has been created and configured successfully!"

##########################################
# Delete all unneeded files and packages #
##########################################
cd /
rm -rf $WORK_DIR
rm /var/cache/apk/*
rm -rf /root/.cache
rm -f /tmp/seafile-server.patch

echo "Unneeded files were cleaned"

echo "Done!"

# vim: set ft=sh foldmethod=marker shiftwidth=4 tabstop=4 expandtab :
