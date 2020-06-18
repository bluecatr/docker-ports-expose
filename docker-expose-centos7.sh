#!/bin/bash
# filename: docker_expose.sh

if [ `id -u` -ne 0 ];then
    echo "[EROOR] Please use root to run this script"
    exit 23
fi

if [ $# -ne 3 ];then
  if [ $# -ne 2 ];then
      echo "Usage: $0 <container_name|container_id> <add|del|ls> [<host_port>:]<container_port>[/<protocol_type>]"
      exit 1
  fi
fi

IPV4_RE='(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])'

container_name=$1
action=$2
arguments=$3

# check action
if [ "$action"x != "add"x -a "$action"x != "del"x -a "$action"x != "ls"x ];then
    echo "[ERROR] Please use add, del or ls parameter to add port map or delete port map or list rules"
    exit 654
fi

container_network=`docker inspect -f {{.HostConfig.NetworkMode}} $container_name 2> /dev/null`
if [ "$container_network"x == "default"x ];then
    # get container ip by container name
    container_ip=`docker inspect -f {{.NetworkSettings.IPAddress}} $container_name 2> /dev/null`
    container_gateway_ip=`docker inspect -f {{.NetworkSettings.Gateway}} $container_name 2> /dev/null`
else
    # get container ip by container name
    container_ip=`docker inspect -f {{.NetworkSettings.Networks.$container_network.IPAddress}} $container_name 2> /dev/null`
    container_gateway_ip=`docker inspect -f {{.NetworkSettings.Networks.$container_network.Gateway}} $container_name 2> /dev/null`
fi

if [ -z $container_ip ];then
    echo "[ERROR] Get container's (${container_name}) IP error, please ensure you have this container"
    exit 2
fi
echo "[INFO] Container network: $container_network, Container IP: $container_ip and Gateway IP: $container_gateway_ip"

if [ "$action"x == "add"x ];then
    action="A"
else
  if [ "$action"x == "del"x ];then
      action="D"
  else
    echo "[INFO] Current NAT rules: "
    iptables -t nat -S DOCKER | grep $container_ip
    iptables -t nat -S POSTROUTING | grep $container_ip
    echo "[INFO] Current FILTER rules: "
    iptables -t filter -S DOCKER | grep $container_ip
    exit 0
  fi
fi

# parse arguments
protocol_type=`echo $arguments | awk -F '/' '{print $2}'`
if [ -z $protocol_type ];then
    protocol_type="tcp"
fi

# check protocol
if [ "$protocol_type"x != "tcp"x -a "$protocol_type"x != "udp"x ];then
    echo "[ERROR] Only tcp or udp protocol is allowed"
    exit 99
fi

host_ip=$container_gateway_ip
host_port=''
container_port=''
# split the left arguments
arguments=${arguments%/*}
host_port=`echo $arguments | awk -F ':' '{print $1}'`
container_port=`echo $arguments | awk -F ':' '{print $2}'`
if [ -z $container_port ];then
    # arguments is: 234:456
    container_port=$host_port
fi

# check port number function
_check_port_number() {
    local port_num=$1
    if ! echo $port_num | egrep "^[0-9]+$" &> /dev/null;then
        echo "[ERROR] Invalid port number $port_num"
        exit 3
    fi
    if [ $port_num -gt 65535 -o $port_num -lt 1 ];then
        echo "[ERROR] Port number $port_num is out of range(1-56635)"
        exit 4
    fi
}

# check port and ip address
_check_port_number $container_port
_check_port_number $host_port

if [ ! -z $host_ip ];then
    if ! echo $host_ip | egrep "^${IPV4_RE}$" &> /dev/null;then
        echo "[ERROR] Invalid Ip Adress $host_ip"
        exit 5
    fi

    # check which interface bind the IP
    for interface in `ifconfig -s | sed -n '2,$p' | awk '{print $1}'`;do
        interface_ip=`ifconfig $interface | awk '/inet addr/{print substr($2,6)}'`
        if [ "$interface_ip"x == "$host_ip"x ];then
            interface_name=$interface
            break
        fi
    done

    if [ -z $interface_name ];then
        echo "[ERROR] Can not find interface bind with $container_ip"
        exit 98
    fi
fi

if [ -z $interface_name ];then
    interface_name="docker0"
fi
echo "[INFO] Container network interface name: $interface_name"

# run iptables command
echo "[INFO] Now start to change rules to iptables on interface: $interface_name"

echo "[INFO] Changing POSTROUTING chain of nat table"
iptables -t nat -${action} POSTROUTING -p ${protocol_type} --dport ${container_port} -s ${container_ip} -d ${container_ip} -j MASQUERADE
echo "[INFO] Changing DOCKER chain of nat table"
iptables -t nat -${action} DOCKER ! -i $interface_name -p ${protocol_type} --dport ${host_port} -j DNAT --to-destination ${container_ip}:${container_port}

echo "[INFO] Changing DOCKER chain of filter table"
iptables -t filter -${action} DOCKER ! -i $interface_name -o $interface_name -p ${protocol_type} --dport ${container_port} -d ${container_ip} -j ACCEPT
