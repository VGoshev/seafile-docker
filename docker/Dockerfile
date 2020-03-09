FROM alpine:3.11
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
# uUID - set UID of seafile user, default: 2016
# uGID - set GID of seafile user, default: 2016
ENV SEAFILE_SERVER_DIR="/home/seafile" \
	SEAFILE_VERSION="7.0.5"

# All installation proccess is in build.sh
# It is possible to do all work via RUN command(s)
# But it looks much better with all work in script
COPY build.sh /tmp/build.sh
COPY seafile-server.patch /tmp/seafile-server.patch
# Execute our build script and delete it because we won't need it anymore
RUN /tmp/build.sh "$SEAFILE_VERSION" "$SEAFILE_SERVER_DIR" && rm /tmp/build.sh

# Container initialization scripts ()
COPY docker-run docker-run-root /bin/

EXPOSE 8000 8082
VOLUME $SEAFILE_SERVER_DIR

# Container will run /bin/docker-run-root with root user access 
# to configure seafile user and switch to it
# to configure (if needed) and run Seafile server
ENTRYPOINT ["/bin/docker-run-root"]
CMD []
