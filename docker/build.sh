#!/bin/sh

#Debug!
set -x
set -e

# Fix little bug in alpine image
ln -s /etc/profile.d/color_prompt /etc/profile.d/color_prompt.sh

###################################################
# We'll need binaries from different paths,       #
#  so we should be sure, all bin dir in the PATH  #
###################################################
PATH="${PATH}:/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin:/usr/local/sbin"

######################################
# Get Seafile Version from first arg #
#  (or use 6.0.5 as default)         #
######################################
SEAFILE_VERSION="6.0.10"
if [ "x$1" != "x" ]; then
    SEAFILE_VERSION=$1
fi

#[ -z $LIBEVHTP_VERSION  ] && LIBEVHTP_VERSION="1.2.0"
[ -z $LIBEVHTP_VERSION  ] && LIBEVHTP_VERSION="18c649203f009ef1d77d6f8301eba09af3777adf"
[ -z $LIBSEARPC_VERSION ] && LIBSEARPC_VERSION="3.1-latest"
##################################
# Where we should install Seahub #
##################################
SEAFILE_SERVER_DIR="/home/seafile"
if [ "x$2" != "x" ]; then
    SEAFILE_SERVER_DIR=$2
fi

##########################################
# Use latest, buggy things in our image. #
# Like seahub via symlink.               #
##########################################
EDGE_V=0
if [ "x$3" = "x1" ]; then
    EDGE_V=1
fi


################################################################
# We'll do all the work here. And delete whole directory after #
################################################################
WORK_DIR="/tmp/seafile"
mkdir -p $WORK_DIR
cd $WORK_DIR

################################
# UID and GID for seafile user #
################################
[ -z "$uUID" ] && uUID=2016
[ -z "$uGID" ] && uGID=2016


################################
# Install some needed packages #
################################
apk update
###########################################
# Runtime dependencies for Seafile-Server #
# bash is needed for upgrade scripts      #
###########################################
apk add bash openssl python py-setuptools py-imaging sqlite \
    libevent util-linux glib jansson libarchive \
		mariadb-client-libs postgresql-libs py-pillow

#################################################
# Add build-deps for Seafile-Server             #
#################################################
apk add --virtual .build_dep \
    curl-dev libevent-dev glib-dev util-linux-dev intltool \
    sqlite-dev libarchive-dev libtool jansson-dev vala fuse-dev \
    cmake make musl-dev gcc g++ automake autoconf bsd-compat-headers \
    python-dev file mariadb-dev mariadb-dev py-pip git


PYTHON_PACKAGES_DIR=`python -c "from distutils.sysconfig import get_python_lib; print(get_python_lib())"`

####################
# Install libevhtp #
####################
#wget https://github.com/ellzey/libevhtp/archive/${LIBEVHTP_VERSION}.tar.gz -O- | tar xzf -
wget https://github.com/haiwen/libevhtp/archive/${LIBEVHTP_VERSION}.tar.gz -O- | tar xzf -
#https://github.com/haiwen/libevhtp/archive/18c649203f009ef1d77d6f8301eba09af3777adf.zip
cd libevhtp-${LIBEVHTP_VERSION}/ && cmake -DEVHTP_DISABLE_SSL=ON -DEVHTP_BUILD_SHARED=ON . && make && make install && cp oniguruma/onigposix.h /usr/include/

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

cd $WORK_DIR/seahub-${SEAFILE_VERSION}-server/ &&
echo "diff --git a/seahub/settings.py b/seahub/settings.py
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
" | patch -p1 && pip install -r requirements.txt

pip install gunicorn flup django-picklefield requests
#   django_compressor django-post_office \
#   django==1.8 pytz django-statici18n djangorestframework \
#   chardet python-dateutil six openpyxl
#pip install https://github.com/haiwen/django-constance/archive/bde7f7c.zip
#pip install https://github.com/haiwen/django-constance/archive/6b04a31.zip

#mv $WORK_DIR/seahub-${SEAFILE_VERSION}-server/ /usr/local/share/seahub
mkdir -p /usr/local/share/seafile
tar czf /usr/local/share/seafile/seahub.tgz -C $WORK_DIR/seahub-${SEAFILE_VERSION}-server/ ./
###############################
# Build and install libSeaRPC #
###############################
cd $WORK_DIR/libsearpc-${LIBSEARPC_VERSION}/ && ./autogen.sh && ./configure && make && make install

export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig

###########################
# Build and install CCNET #
###########################
cd $WORK_DIR/ccnet-server-${SEAFILE_VERSION}-server/ && \
	./autogen.sh && \
    ./configure --with-mysql --with-postgresql --enable-python && \
		make && make install


####################################
# Build and install Seafile-Server #
# As a First step we need to patch #
# seafile-controller topdir        #
# And some scripts                 #
####################################
cd $WORK_DIR/seafile-server-${SEAFILE_VERSION}-server/
patch -p1 < /tmp/seafile-server.patch
./autogen.sh && \
    ./configure --with-mysql --with-postgresql --enable-python && \
		make && make install

#Copy some useful scripts to /usr/local/bin
#mkdir -p /usr/local/bin
cp scripts/seaf-fsck.sh /usr/local/bin/seafile-fsck
cp scripts/seaf-gc.sh /usr/local/bin/seafile-gc
# Also copy scripts to save them
#mkdir -p /usr/local/share/seafile/
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
# Like add seafile user and  #
#  create his home directory #
##############################

addgroup -g "$uGID" seafile
adduser -D -s /bin/sh -g "Seafile Server" -G seafile -h "$SEAFILE_SERVER_DIR" -u "$uUID" seafile

# Create seafile-server dir 
su - -c "mkdir ${SEAFILE_SERVER_DIR}/seafile-server" seafile

# Store seafile version and if tis is edge image
mkdir -p /var/lib/seafile
echo -n "$SEAFILE_VERSION" > /var/lib/seafile/version
echo -n "$EDGE_V" > /var/lib/seafile/edge

echo "seafile user has been created and configured successfully!"

#########################################
# Delete all unneded files and packages #
#########################################
cd /
apk del --purge .build_dep
rm -rf $WORK_DIR
rm /var/cache/apk/*
rm -rf /root/.cache
rm -f /tmp/seafile-server.patch

echo "unneded files were cleaned"

echo "Done!"

# vim: set ft=sh foldmethod=marker shiftwidth=4 tabstop=4 expandtab :
