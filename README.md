# Seafile Server Docker image
[Seafile](http://seafile.com/) server Docker image based on [Alpine Linux](https://hub.docker.com/_/alpine/) Docker image.

Also in my [Github repository](https://github.com/SunAngel/seafile-docker) you can find some usefull scripts for helping running containers.

## Supported tags and respective `Dockerfile` links

* [`6.0.6`](https://github.com/SunAngel/seafile-docker/blob/6.0.6/docker/Dockerfile), [`6.0`](https://github.com/SunAngel/seafile-docker/blob/6.0/docker/Dockerfile), [`latest`](https://github.com/SunAngel/seafile-docker/blob/master/docker/Dockerfile) - Seafile Server v6.0.6 - latest avaliable version
* [`6.0.5`](https://github.com/SunAngel/seafile-docker/blob/6.0.5/docker/Dockerfile) - Seafile Server v6.0.5

## Quickstart

To run container you can use following command:
`docker run \
  -v /home/docker/seafile:/home/seafile \
  -p 127.0.0.1:8000:80000 \
  -p 127.0.0.1:8082:8082 \ 
  -ti sunx/seafile`

Containers, based on this image will automatically configure 
 Seafile enviroment if there isn't any. If Seafile enviroment is from previous version of Seafile, container will automatically upgrade it to latest version (by calling Seafile upgrade scripts).
 
But I would advise you to do data backups before upgrading image 
 (to not lose your data in case of bugs in upgrade logic of this image or Seafile upgrde scripts).

## Detailed description of image and containers

### Used ports

This image uses 2 tcp ports:
* 8000 - seafile port
* 8082 - seahub port

### Volume
This image uses one volume with internal path `/home/seafile`

I would recommend you use host directory mapping of named volume to run containers, so you will not lose your valuable data after image update and starting new container

### Web server configuration

This image doesnt contain any web-servers, because you, usually, already have some http server running on your server and don't want to run any extra http-servers (because it will cost you some CPU time and Memory). But if you know some really tiny web-server with proxying support, tell me and I would be glad to integrate it to the image.


For Web-server configuration, as media directory location you should enter
`<volume/path>/seafile-server/seahub/media`

In [httpd-conf](https://github.com/SunAngel/seafile-docker/blob/master/httpd-conf/) directory you can find [lighttpd](https://www.lighttpd.net/) [config example](https://github.com/SunAngel/seafile-docker/blob/master/httpd-conf/lighttpd.conf.example).

You can find 
[Nginx](https://manual.seafile.com/deploy/deploy_with_nginx.html) and 
[Apache](https://manual.seafile.com/deploy/deploy_with_apache.html) 
configurations in official Seafile Server [Manual](https://manual.seafile.com/).

### Supported ENV variables

When you running container, you can pass several enviroment variables (with **--env** option of **docker run** command):
* **`INTERACTIVE`**=<0|1> - if container should ask you about some configuration values (on first run) and about upgrades. Default: 1
* **`SERVER_NAME`**=<...> - Name of Seafile server (3 - 15 letters or digits), used only for first run in non-interactive mode. Default: Seafile
* **`SERVER_DOMAIN`**=<...> - Domain or ip of seafile server, used only for first run in non-interactive mode. Default: seafile.domain.com

## Usefull commands in container

When you're inside of container, in home directory of seafile user, you can use following useful commands:
* seafile-fsck - check your libraries for errors (Originally seaf-fsck.sh is used for it)
* seafile-gc - remove ald unused data from storage of your seafile libraries (Originally seaf-gc.sh is used for it)
* seafile-admin start - start seafile and seahub daemons (if they were stopped)
* seafile-admin stop - stop seafile and seahub daemons
* seafile-admin reset-admin - reset seafile admin user and/or password
* seafile-admin setup - setup ccnet, seafile and seahub services (if they wasn't configured automatically by some reason)
* seafile-admin create-admin - create seafile admin user (if it wasn't created automatically by some reason)

## Tips&amp;Tricks and Known issues

* If you do not want container to automatically upgrade your Seafile enviroment on image (and Seafile-server) update, 
you can add empty file named `.no-update` to directory `/home/seafile` in your container. You can use **`docker exec <container_name> touch /home/seafile/.no-update`** for it.

* Container will switch to user seafile after run, so if you need to do something with root access in container, you can use **`docker exec -ti <container_name> /bin/sh`** for it.

* On first run (end every image upgrade) container will copy seahub directory from `/usr/local/share/seahub` to `/home/seafile/seafile-server/seahub `(i.e. to the volume), so it cost about 40Mb of space. I'm not sure if it could be changed without using webserver inside of container (But 40Mb of space isn't to much in our days, I think).

* At this moment most seafile scripts (which are located in `/usr/local/share/seafile/scripts` directory) aren't working properly, but I do not think that they are to usefull for this image (scripts `seaf-fsck.sh` and `seaf-gc.sh` are working correctly and also avaliable as `/usr/local/bin/seafile-fsck` and `/usr/local/bin/seafile-gc`).

## License

This Dockerfile and scripts are released under [MIT License](https://github.com/SunAngel/seafile-docker/blob/master/LICENSE).

[Seafile](https://github.com/haiwen/seafile/blob/master/LICENSE.txt) and [Alpine Linux](https://www.alpinelinux.org/) have their own licenses.
