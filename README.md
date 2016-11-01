## Seafile Docker image

Dockerfile and some helper scripts Seafile-server Docker image

This image is based on latest [Alpine](https://hub.docker.com/_/alpine/) Docker image

Containers, based on this image should automatically configure Seafile enviroment if there isn't any and upgrade it if enviroment is from previous version of Seafile (by calling Seafile upgrade scripts).
But I would advise you to do data backups before upgrading image (in case of bugs in upgrade logic of this image or Seafile itself).


This image exposes 2 tcp ports:
* 8000 - seahub port
* 8082 - seafile port

Also this image uses one volume with internal path /home/seafile

When you running container, you can pass several enviroment variables (with **--env** option of **docker run** command):
* INTERACTIVE=<0|1> - if container should ask you about some configuration values (on first run) and about upgrades. Default: 1
* SERVER_NAME=<...> - Name of Seafile server (3 - 15 letters or digits), used only for first run in non-interactive mode. Default: Seafile
* SERVER_DOMAIN=<...> - Domain or ip of seafile server, used only for first run in non-interactive mode. Default: seafile.domain.com

If you do not want container to automatically upgrade your Seafile enviroment and user data on image (and Seafile-server) update, 
you can add empty file named **.no-update** to directory **/home/seafile** in your container 
(you can use **docker exec <container_name> touch /home/seafile/.no-update** for it).

Container will use user seafile on run, so if you need to do something with root access in container, you can use **docker exec -ti <container_name> /bin/sh** for it

At this time on first run (end every image upgrade) container copy seahub directory from /usr/local/share/seahub to /home/seafile/seafile-server/seahub, so it cost about 40Mb of space. In future this behaviour could be changed (or not, as long as external webserver need media directory from seahub to serve seafile properly).

Also at this moment seafile scripts like *seaf-fsck.sh* and *seaf-gc.sh* aren't working properly, it will be fixed.


PS: Do backups of your data.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
