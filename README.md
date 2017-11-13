# docker-expose
A shell tool for adding and mapping machine ports to docker ports on a running container

Refer to the shell scripts described in [docker动态映射运行的container端口](http://yaxin-cn.github.io/Docker/expose-port-of-running-docker-container.html)

Modified and tested on Ubuntu 16.04 and Docker 17.09

# usage

Get docker-expose.sh and copy it into /usr/local/bin, enjoy it!

``` sh
cp docker-expose.sh /usr/local/bin/docker-expose
chmod +x /usr/local/bin/docker-expose

docker-expose
Usage: /usr/local/bin/docker-expose <container_name> <add|del> [[<machine_ip>:]<machine_port>:]<container_port>[/<protocol_type>]

docker-expose 80324bbd5ad0 add 172.17.0.1:22002:22
docker-expose 80324bbd5ad0 del 172.17.0.1:22002:22

docker-expose 80324bbd5ad0 add 22002:22
docker-expose 80324bbd5ad0 del 22002:22

docker-expose 80324bbd5ad0 add 8080
docker-expose 80324bbd5ad0 del 8080
```
