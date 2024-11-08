#!/bin/bash

source config.ini # use /bin/bash for reading from the current directory
source jscommon.sh

enable_portforwarding() {

print1 " Enable port forwarding kernel OS setting "
#echo "target hosts : $ALLHOST"

for i in $ALLHOST
do
    print2 "$i : Live change only : sysctl -w net.ipv4.ip_forward=1"
    ssh $SSH_NO_BANNER $HOST  ${i} "sysctl -w net.ipv4.ip_forward=1"
    if [ $? -ne 0 ]; then
        logger_error "Failure to enable port forwarding on the host $i"
    fi
    ssh $SSH_NO_BANNER $HOST  ${i} "printf \"Value from sysctl -a        \";sysctl -a |grep \"net.ipv4.ip_forward =\""
    ssh $SSH_NO_BANNER $HOST  ${i} "printf \"Value in /etc/sysctl.conf   \" ;grep \"net.ipv4.ip_forward =\" /etc/sysctl.conf"
    print2 "$i : permanent change to /etc/sysctl.conf. /etc/sysctl.conf is the last file to run during next reboot"
    ssh $SSH_NO_BANNER $HOST  ${i} "sed -i 's/^net.ipv4.ip_forward = 0/net.ipv4.ip_forward = 1/' /etc/sysctl.conf"
    ssh $SSH_NO_BANNER $HOST  ${i} "printf \"Value in /etc/sysctl.conf   \" ;grep \"net.ipv4.ip_forward =\" /etc/sysctl.conf"
done

}

enable_portforwarding