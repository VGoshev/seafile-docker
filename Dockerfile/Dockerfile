FROM alpine
MAINTAINER Vladimir Goshev

# SEAFILE_SERVER_DIR:
# Where we will store seafile-server settings
#  seafile user home directory.
#
# SEAFILE_VERSION:
# Seafile-Server version do townload and install
#  See https://github.com/haiwen/seafile-server/releases 
#  for latest avaliable version
ENV SEAFILE_SERVER_DIR="/home/seafile/" \
	SEAFILE_VERSION="6.0.5"

# All instalation proccess is in build.sh
# It is possible to do all work via RUN command
# But it looks much better with all work in script
COPY build.sh /tmp/build.sh
# Execute our build script and delete it because it isn't needed anymore/
RUN sh /tmp/build.sh "$SEAFILE_VERSION" "$SEAFILE_SERVER_DIR" && rm /tmp/build.sh

# Container initialization script
COPY docker-run.sh /bin/docker-run

EXPOSE 8000 8082
VOLUME $SEAFILE_SERVER_DIR

WORKDIR $SEAFILE_SERVER_DIR
#USER seafile
#CMD ["/bin/docker-run"]
CMD su -l -c "/bin/docker-run" seafile ; /bin/sh
