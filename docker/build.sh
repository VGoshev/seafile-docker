#!/bin/sh -e

#Debug!
set -x

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
SEAFILE_VERSION="6.0.5"
if [ "x$1" != "x" ]; then
    SEAFILE_VERSION=$1
fi

##################################
# Where we should install Seahub #
##################################
SEAFILE_SERVER_DIR="/home/seafile/"
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
uUID=2016
uGID=2016

################################
# Install some needed packages #
################################
apk update
###########################################
# Runtime dependencies for Seafile-Server #
# bash is needed for upgrade scripts      #
###########################################
apk add bash openssl python py-setuptools py-imaging sqlite \
    libevent util-linux glib jansson libarchive

#################################################
# Add build-deps for Seafile-Server             #
# I'm creatind variable with them to being able #
#  to delete them back after building           #
#################################################
BUILD_DEP="curl-dev libevent-dev glib-dev util-linux-dev intltool \
    sqlite-dev libarchive-dev libtool jansson-dev vala fuse-dev \
    cmake make musl-dev gcc g++ automake autoconf bsd-compat-headers \
    python-dev file"
apk add $BUILD_DEP
#mariadb-dev - We'll make seafile without MySQL support

###########################################################
# Seahub dependencies -                                   #
#  add py-pip and allow it to install all python packages #
# To instal some of python modules we need gcc,           #
#  so this stage should be AFTER adding build-deps        #
###########################################################
apk add py-pip 
pip install django==1.8 pytz django-statici18n djangorestframework \
    django_compressor django-post_office gunicorn flup chardet \
    python-dateutil six openpyxl \
    django-picklefield
pip install https://github.com/haiwen/django-constance/archive/bde7f7c.zip


####################
# Install libevhtp #
####################
wget https://github.com/ellzey/libevhtp/archive/1.1.6.tar.gz -O- | tar xzf -
cd libevhtp-1.1.6/ && cmake -DEVHTP_DISABLE_SSL=ON -DEVHTP_BUILD_SHARED=ON . && make && make install 

###################################
# Download all Seafile components #
###################################
cd $WORK_DIR
wget https://github.com/haiwen/libsearpc/archive/v3.1-latest.tar.gz -O- | tar xzf -
wget https://github.com/haiwen/ccnet-server/archive/v${SEAFILE_VERSION}-server.tar.gz -O- | tar xzf -
wget https://github.com/haiwen/seafile-server/archive/v${SEAFILE_VERSION}-server.tar.gz -O- | tar xzf -
wget https://github.com/haiwen/seahub/archive/v${SEAFILE_VERSION}-server.tar.gz -O- | tar xzf -

#####################################
# Seahub is python application,     #
#  just copy it in proper directory #
#####################################
#mv $WORK_DIR/seahub-${SEAFILE_VERSION}-server/ ${SEAFILE_SERVER_DIR}/seafile-server/seahub
mv $WORK_DIR/seahub-${SEAFILE_VERSION}-server/ /usr/local/share/seahub

###############################
# Build and install libSeaRPC #
###############################
cd libsearpc-3.1-latest/ && ./autogen.sh && ./configure && make && make install

export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig
###########################
# Build and install CCNET #
###########################
cd $WORK_DIR/ccnet-server-${SEAFILE_VERSION}-server/ && ./autogen.sh && \
    ./configure --without-mysql --without-postgresql && make && make install

####################################
# Build and install Seafile-Server #
# As a First step we need to patch #
# seafile-controller topdir        #
# And some scripts                 #
####################################
cd $WORK_DIR/seafile-server-${SEAFILE_VERSION}-server/
patch -p1 < /tmp/seafile-server.patch
./autogen.sh && \
    ./configure --without-mysql --without-postgresql && make && make install

#Copy some useful scripts to /usr/local/bin
#mkdir -p /usr/local/bin
cp scripts/seaf-fsck.sh /usr/local/bin/seafile-fsck
cp scripts/seaf-gc.sh /usr/local/bin/seafile-gc
# Also copy scripts to save them
mkdir -p /usr/local/share/seafile/
mv scripts /usr/local/share/seafile/

ldconfig

echo "export PYTHONPATH=/usr/local/lib/python2.7/site-packages:${SEAFILE_SERVER_DIR}/seafile-server/seahub/thirdpart" >> /etc/profile.d/python-local.sh


echo "Seafile-Server has been built successfully!"

##############################
# Do some preparations       #
# Like add seafile user and  #
#  create his home directory #
##############################
echo "seafile:x:${uUID}:${uGID}:Seafile Server:${SEAFILE_SERVER_DIR}:/bin/sh" >> /etc/passwd
echo "seafile:x:${uGID}:" >> /etc/group
echo 'seafile:!::0:::::' >> /etc/shadow

mkdir -p "${SEAFILE_SERVER_DIR}"
chown seafile:seafile "${SEAFILE_SERVER_DIR}"

# Create seafile-server dir 
su - -c "mkdir ${SEAFILE_SERVER_DIR}/seafile-server" seafile


# Only for those who want to has problems, lol
# Because there are some issues of using seahub via symlink
if [ $EDGE_V -eq 1 ]; then
    # Some seahub configuration.
    #mv /usr/local/share/seahub/media/avatars /usr/local/share/seahub/media/avatars.def
    #ln -s "${SEAFILE_SERVER_DIR}/seahub-data" /usr/local/share/seahub/media/avatars

    # I'll chown it instead
    chown -R seafile:seafile /usr/local/share/seahub

    # Little hack to be able to initialize seahub by user (and keep seahub.db on volume)
    ln -s "${SEAFILE_SERVER_DIR}/seahub.db" /usr/local/seahub.db

    #Well... i'm not sure if I need to generate *.pyc files for seahub
    # during image building or on first run of container, but anyway, 
    #  they aren't take much space
    #cd /usr/local/share/seahub && python -m compileall .
    # No need as long as I've chowned seahub directory
fi

# Store seafile version and if tis is edge image
mkdir -p /var/lib/seafile
echo -n "$SEAFILE_VERSION" > /var/lib/seafile/version
echo -n "$EDGE_V" > /var/lib/seafile/edge

echo "seafile user has been created and configured successfully!"

#########################################
# Delete all unneded files and packages #
#########################################
cd /
apk del --purge $BUILD_DEP
rm -rf $WORK_DIR
rm /var/cache/apk/*
rm -rf /root/.cache
rm -f /tmp/seafile-server.patch

echo "unneded files were cleaned"

echo "Done!"
