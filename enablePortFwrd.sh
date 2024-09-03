#!/bin/bash

source config.ini # use /bin/bash for reading from the current directory
source jscommon.sh

enable_portforwarding() {

disp_msglvl1 " Enable port forwarding kernel OS setting : sysctl -w net.ipv4.ip_forward=1 "
#echo "target hosts : $ALLHOST"  

for i in $ALLHOST
do
    disp_msglvl2 "Running on the host $i"     
    ssh $SSH_NO_BANNER $HOST  ${i} "sysctl -w net.ipv4.ip_forward=1" 
    if [ $? -ne 0 ]; then
	logger_error "Failure to enable port forwarding on the host $i"   
    fi
    ssh $SSH_NO_BANNER $HOST  ${i} "sysctl -a |grep \"net.ipv4.ip_forward =\"" 

done

}

enable_portforwarding

