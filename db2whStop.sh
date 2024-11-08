#!/bin/bash

#source `pwd`/conf ## for /bin/ksh
source config.ini # use /bin/bash for reading from the current directory
source jscommon.sh

# Manual stop
db2whStop(){

	# JS_TODO : number of partition control. ORA compatibility control   
	for HOST in $ALLHOST
	do
		disp_msglvl2 "Run Db2wh for the 1st time $HOST..."
		ssh $SSH_NO_BANNER root@$HOST "podman stop Db2wh"
		if [ $? -ne 0 ]; then
			echo "failure. Exit.."
		else
			echo "success !!! "
		fi
	done
}

disp_msglvl1 "stop Db2wh service"
podman exec –it Db2wh stop   # shutdown all service issueing from head node. JSTODO error Error: no container with name or ID "–it" found: no such container

db2whStop
