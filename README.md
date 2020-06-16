# docker-expose
A shell tool for adding and mapping machine ports to docker ports on a running container

Modified and tested on Ubuntu 16.04 and Docker 17.09

docker-expose-centos7.sh is tested on Centos 7 and Docker 18.03.1-ce

# usage

Get docker-expose.sh and copy it into /usr/local/bin, enjoy it!

``` sh
cp docker-expose.sh /usr/local/bin/docker-expose
chmod +x /usr/local/bin/docker-expose

docker-expose
Usage: /usr/local/bin/docker-expose <container_name> <add|del> [<host_port>:]<container_port>[/<protocol_type>]

docker-expose 80324bbd5ad0 add 22002:22
docker-expose 80324bbd5ad0 del 22002:22

docker-expose 80324bbd5ad0 add 8080
docker-expose 80324bbd5ad0 del 8080
```
