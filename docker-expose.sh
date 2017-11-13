#!/bin/bash
# filename: docker_expose.sh

if [ `id -u` -ne 0 ];then
    echo "[EROOR] Please use root to run this script"
    exit 23
fi

if [ $# -ne 3 ];then
    echo "Usage: $0 <container_name> <add|del> [[<machine_ip>:]<machine_port>:]<container_port>[/<protocol_type>]"
    exit 1
fi

IPV4_RE='(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])'

container_name=$1
action=$2
arguments=$3

# check action
if [ "$action"x != "add"x -a "$action"x != "del"x ];then
    echo "[ERROR] Please use add or del parameter to add port map or delete port map"
    exit 654
fi
if [ "$action"x == "add"x ];then
    action="A"
else
    action="D"
fi

# get container ip by container name
container_ip=`docker inspect -f '{{.NetworkSettings.IPAddress}}' $container_name 2> /dev/null`
if [ -z $container_ip ];then
    echo "[ERROR] Get container's (${container_name}) IP error, please ensure you have this container"
    exit 2
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

machine_ip=''
machine_port=''
container_port=''
# split the left arguments
arguments=${arguments%/*}
machine_ip=`echo $arguments | awk -F ':' '{print $1}'`
machine_port=`echo $arguments | awk -F ':' '{print $2}'`
container_port=`echo $arguments | awk -F ':' '{print $3}'`
if [ -z $machine_port ];then
    # arguments is: 234
    container_port=$machine_ip
    machine_port=$machine_ip
    unset machine_ip
elif [ -z $container_port ];then
    # arguments is: 234:456
    container_port=$machine_port
    machine_port=$machine_ip
    unset machine_ip
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
_check_port_number $machine_port

if [ ! -z $machine_ip ];then
    if ! echo $machine_ip | egrep "^${IPV4_RE}$" &> /dev/null;then
        echo "[ERROR] Invalid Ip Adress $machine_ip"
        exit 5
    fi

    # check which interface bind the IP
    for interface in `ifconfig -s | sed -n '2,$p' | awk '{print $1}'`;do
        interface_ip=`ifconfig $interface | awk '/inet addr/{print substr($2,6)}'`
        if [ "$interface_ip"x == "$machine_ip"x ];then
            interface_name=$interface
            break
        fi
    done

    if [ -z $interface_name ];then
        echo "[ERROR] Can not find interface bind with $machine_ip"
        exit 98
    fi
fi

if [ -z $interface_name ];then
    interface_name="docker0"
fi

# run iptables command
echo "[INFO] Now start to change rules to iptables on interface: $interface_name"

echo "[INFO] Changing POSTROUTING chain of nat table"
iptables -t nat -${action} POSTROUTING -p ${protocol_type} --dport ${container_port} -s ${container_ip} -d ${container_ip} -j MASQUERADE
echo "[INFO] Changing DOCKER chain of nat table"
iptables -t nat -${action} DOCKER -p ${protocol_type} --dport ${machine_port} -j DNAT --to-destination ${container_ip}:${container_port}

echo "[INFO] Changing DOCKER chain of filter table"
iptables -t filter -${action} DOCKER ! -i $interface_name -o docker0 -p ${protocol_type} --dport ${container_port} -d ${container_ip} -j ACCEPT
