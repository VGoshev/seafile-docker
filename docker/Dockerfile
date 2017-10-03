FROM alpine:3.4
MAINTAINER Vladimir Goshev <sunx@sunx.name>

# SEAFILE_SERVER_DIR:
# Where we will store seafile-server settings
#  seafile user home directory.
# Default: /home/seafile
#
# SEAFILE_VERSION:
# Seafile-Server version do townload and install
#  See https://github.com/haiwen/seafile-server/releases
#  for latest avaliable version
# uUID - set UID of Seafile user, default: 2016
# uGID - set GID of Seafile user, default: 2016
ENV SEAFILE_SERVER_DIR="/home/seafile" \
	SEAFILE_VERSION="6.2.2"

###########################################
# Runtime dependencies for Seafile-Server #
# bash is needed for upgrade scripts      #
###########################################
RUN apk add --update \
        bash \
        glib \
        jansson \
        libarchive \
        libevent \
        mariadb-client-libs \
        openssl \
        postgresql-libs \
        py-imaging \
        py-pillow \
        py-setuptools \
        python \
        sqlite \
        util-linux \
 && rm -rf /var/cache/apk/*

# Most of installation stuff is done in build.sh
COPY build.sh /tmp/build.sh
COPY seafile-server.patch /tmp/seafile-server.patch
# Add build-deps for Seafile-Server
RUN apk add --update --virtual .build_dep \
        autoconf \
        automake \
        bsd-compat-headers \
        cmake \
        curl-dev \
        file \
        fuse-dev \
        g++ \
        gcc \
        git \
        glib-dev \
        intltool \
        jansson-dev \
        libarchive-dev \
        libevent-dev \
        libtool \
        make \
        mariadb-dev \
        musl-dev \
        py-pip \
        python-dev \
        sqlite-dev \
        util-linux-dev \
        vala \
# Run the buildscript and remove builddep packages again
 && /tmp/build.sh \
 && apk del --purge .build_dep

# Container initialization scripts ()
COPY docker-run.sh /usr/local/bin/docker-run

EXPOSE 8000 8082
VOLUME $SEAFILE_SERVER_DIR

USER seafile

CMD ["/usr/local/bin/docker-run"]
