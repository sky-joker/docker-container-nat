#!/usr/bin/env bash

usage() {
    echo "Usage: $0 [-a|-d] [-p protocol] [-n target port] [-t destination port] [-c container ip]"
    echo ""
    echo "optional arguments:"
    echo -e "  -h\tshow this help message and exit"
    echo -e "  -a\tadd nat"
    echo -e "  -d\tdelete nat"
    echo -e "  -p\ttcp or udp protocol"
    echo -e "  -n\thost target port"
    echo -e "  -t\tcontainer destination port"
    echo -e "  -c\tcontainer ip"
    exit 1
}

while getopts adp:n:t:c:h OPT
do
    case $OPT in
        a) add_flag=true
           ;;
        d) delete_flag=true
           ;;
        p) protocol=$OPTARG
           ;;
        n) target_port=$OPTARG
           ;;
        t) destination_port=$OPTARG
           ;;
        c) container_ip=$OPTARG
           ;;
        h) usage
           ;;
    esac
done

if [ $add_flag -a $protocol -a $target_port -a $destination_port -a $container_ip ] ; then
    iptables -t nat -A POSTROUTING -s $container_ip/32 -d $container_ip/32 -p $protocol -m $protocol --dport $destination_port -j MASQUERADE
    iptables -t nat -A DOCKER ! -i docker0 -p $protocol -m $protocol --dport $target_port -j DNAT --to-destination $container_ip:$destination_port
    iptables -A DOCKER -d $container_ip/32 ! -i docker0 -o docker0 -p $protocol -m $protocol --dport $destination_port -j ACCEPT
    exit 0
fi

if [ $delete_flag -a $protocol -a $target_port -a $destination_port -a $container_ip ] ; then
    iptables -t nat -D POSTROUTING -s $container_ip/32 -d $container_ip/32 -p $protocol -m $protocol --dport $destination_port -j MASQUERADE
    iptables -t nat -D DOCKER ! -i docker0 -p $protocol -m $protocol --dport $target_port -j DNAT --to-destination $container_ip:$destination_port
    iptables -D DOCKER -d $container_ip/32 ! -i docker0 -o docker0 -p $protocol -m $protocol --dport $destination_port -j ACCEPT
    exit 0
fi

usage

