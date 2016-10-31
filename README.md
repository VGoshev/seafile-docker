## Seafile Docker image

Dockerfile for alpine-based Seafile-server Docker image

Containers, based on this image should automatically configure seafile enviroment if there isn't any
and upgrade if enviroment is from previous version of Seafile.
But it is better to do backup before upgrading image (just in case of bugs in upgrade logic of this image or Seafile itself).

This image exposes 2 tcp ports:
* 8000 - seahub port
* 8082 - seafile port

Also this image uses one volume with path /home/seafile

When you running container, you can pass several enviroment variables (with *--env* option of *docker run* command):
* INTERACTIVE=<0|1> - if container should ask you about some configuration values (on first run) and about upgrades. Default: 1
* SERVER_NAME=<...> - Name of Seafile server (3 - 15 letters or digits), used only for first run. Default: Seafile
* SERVER_DOMAIN=<...> - Domain or ip of seafile server, used only for first run. Default: seafile.domain.com


At this time on first run (end every image upgrade) container copy seahub directory from /usr/local/share/seahub to /home/seafile/seafile-server/seahub, so it cost about 40Mb of space. In future this behaviour would be changed, maybe.


PS: Do backups of your data,

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
