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
Usage: /usr/local/bin/docker-expose <container_name|container_id> <add|del|ls> [<host_port>:]<container_port>[/<protocol_type>]

docker-expose my_docker add 22002:22
docker-expose my_docker del 22002:22

docker-expose my_docker add 8080
docker-expose my_docker del 8080

docker-expose my_docker ls
```

```sh
$ sudo docker-expose a766 ls
[INFO] Container network: my_default, Container IP: 192.168.11.11 and Gateway IP: 192.168.11.1
[INFO] Current NAT rules: 
-A DOCKER ! -i br-7026360877e6 -p tcp -m tcp --dport 2181 -j DNAT --to-destination 192.168.11.11:2181
-A DOCKER ! -i br-7026360877e6 -p tcp -m tcp --dport 16000 -j DNAT --to-destination 192.168.11.11:16000
-A DOCKER ! -i br-7026360877e6 -p tcp -m tcp --dport 16020 -j DNAT --to-destination 192.168.11.11:16020
-A DOCKER ! -i br-7026360877e6 -p tcp -m tcp --dport 16022 -j DNAT --to-destination 192.168.11.11:16022
-A POSTROUTING -s 192.168.11.11/32 -d 192.168.11.11/32 -p tcp -m tcp --dport 2181 -j MASQUERADE
-A POSTROUTING -s 192.168.11.11/32 -d 192.168.11.11/32 -p tcp -m tcp --dport 16000 -j MASQUERADE
-A POSTROUTING -s 192.168.11.11/32 -d 192.168.11.11/32 -p tcp -m tcp --dport 16020 -j MASQUERADE
-A POSTROUTING -s 192.168.11.11/32 -d 192.168.11.11/32 -p tcp -m tcp --dport 16022 -j MASQUERADE
[INFO] Current FILTER rules: 
-A DOCKER -d 192.168.11.11/32 ! -i br-7026360877e6 -o br-7026360877e6 -p tcp -m tcp --dport 2181 -j ACCEPT
-A DOCKER -d 192.168.11.11/32 ! -i br-7026360877e6 -o br-7026360877e6 -p tcp -m tcp --dport 16000 -j ACCEPT
-A DOCKER -d 192.168.11.11/32 ! -i br-7026360877e6 -o br-7026360877e6 -p tcp -m tcp --dport 16020 -j ACCEPT
-A DOCKER -d 192.168.11.11/32 ! -i br-7026360877e6 -o br-7026360877e6 -p tcp -m tcp --dport 16022 -j ACCEPT

```
