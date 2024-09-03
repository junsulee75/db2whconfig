#!/bin/bash

#source `pwd`/conf ## for /bin/ksh
source config.ini # use /bin/bash for reading from the current directory
source jscommon.sh

db2whFirstRun(){

	# JS_TODO : number of partition control. ORA compatibility control   
	for HOST in $ALLHOST
	do
		disp_msglvl2 "Run Db2wh for the 1st time $HOST..."
		ssh $SSH_NO_BANNER root@$HOST "podman run -d -it --privileged=true --net=host --name=Db2wh -v /mnt/clusterfs:/mnt/bludata0 -v /mnt/clusterfs:/mnt/blumeta0 -e MLN_DISTRIBUTION="$NUM_PARTITION_HEADNODE:$NUM_PARTITION_DATANODE" $DB2WH_IMAGE"
		if [ $? -ne 0 ]; then
			echo "failure. Exit.."
		else
			echo "success !!! "
		fi
	done
}

db2whFirstRun

disp_msglvl1 "Monitor Db2wh log. You may quit by CTRL+C any time."
podman logs --follow Db2wh
