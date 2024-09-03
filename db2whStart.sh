#!/bin/bash

#source `pwd`/conf ## for /bin/ksh
source config.ini # use /bin/bash for reading from the current directory
source jscommon.sh

# not for 1st start. Just usual start after installation.  
db2whStart(){

	# JS_TODO : number of partition control. ORA compatibility control   
	for HOST in $ALLHOST
	do
		disp_msglvl2 "Start Db2wh container on $HOST..."
		ssh $SSH_NO_BANNER root@$HOST "podman start Db2wh"
		if [ $? -ne 0 ]; then
			echo "failure. Exit.."
		else
			echo "success !!! "
		fi
	done
}

db2whStart

disp_msglvl1 "Monitor Db2wh log. You may quit by CTRL+C any time."
podman logs --follow Db2wh