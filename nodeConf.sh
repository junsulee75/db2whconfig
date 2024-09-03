#!/bin/bash

##########################################
 # Copyright ? 2020 Jun Su Lee. All rights reserved.
 # Author : Jun Su Lee ( junsulee@au1.ibm.com )
 # Description : create /mnt/clusterfs/nodes file   
 # ex)
#  [root@jsdb2wh1 clusterfs]# cat /mnt/clusterfs/nodes
# head_node=jsdb2wh1:10.11.26.85
# data_node1=jsdb2wh2:10.11.26.153
# data_node2=jsdb2wh3:10.11.26.196
 # Category : DB2 setup
##########################################


source config.ini # use /bin/bash for reading from the current directory
source jscommon.sh

NODES_CONF="/mnt/clusterfs/nodes"

nodeConf() {

    disp_msglvl1 "Create /mnt/clusterfs/nodes file" 

    if [ -f "$NODES_CONF" ]; then
        # File exists, so delete it

        disp_msglvl2 "Backing up existing $NODES_CONF to $NODES_CONF.bak.`date +%Y%m%d_%H%M%S` and delete" 
        cp $NODES_CONF $NODES_CONF.bak.`date +%Y%m%d_%H%M%S`
        rm -f $NODES_CONF
    fi 

    head_shortname=`grep $headhost /etc/hosts |grep -v "^#" |awk '{print $3;}'`
    head_ip=`grep $headhost /etc/hosts |grep -v "^#" |awk '{print $1;}'`
    echo "head_node=$head_shortname:$head_ip" >> $NODES_CONF

    i=0
    for HOST in $datahost
    do
        ((i++))
        data_shortname=`grep $HOST /etc/hosts |grep -v "^#" |awk '{print $3;}'` 
        data_ip=`grep $HOST /etc/hosts |grep -v "^#" |awk '{print $1;}'`
        echo "data_node$i=$data_shortname:$data_ip" >> $NODES_CONF
    done
    
    disp_msglvl2 "show /mnt/clusterfs/nodes"   
    cat $NODES_CONF
}

nodeConf