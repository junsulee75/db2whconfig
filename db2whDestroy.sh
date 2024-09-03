#!/bin/bash

#source `pwd`/conf ## for /bin/ksh
source config.ini # use /bin/bash for reading from the current directory
source jscommon.sh

# For whatever reason, to clean Db2Warehouse
db2whDelete(){

	IMAGE_ID=`podman images |grep db2wh |awk '{print $3;}'`
	# JS_TODO : number of partition control. ORA compatibility control   
	for HOST in $ALLHOST
	do
		disp_msglvl2 "Stop Db2wh 1st attempt $HOST..."
		ssh $SSH_NO_BANNER root@$HOST "podman stop Db2wh"
		disp_msglvl2 "Stop Db2wh 2nd attempt $HOST...Sometimes need to do twice when getting error |StopSignal  failed to stop container Db2wh in 10 seconds, resorting to SIGKILL| "
		ssh $SSH_NO_BANNER root@$HOST "podman stop Db2wh"
		if [ $? -ne 0 ]; then
			echo "failure. Exit.."
		else
			echo "success !!! "
		fi

		disp_msglvl2 "Delete Db2wh container $HOST..."
		ssh $SSH_NO_BANNER root@$HOST "podman rm Db2wh"
		if [ $? -ne 0 ]; then
			echo "failure. Exit.."
		else
			echo "success !!! "
		fi
		
		disp_msglvl2 "Delete Db2wh image $HOST..."
		ssh $SSH_NO_BANNER root@$HOST "podman rmi $IMAGE_ID"
		if [ $? -ne 0 ]; then
			echo "failure. Exit.."
		else
			echo "success !!! "
		fi		
	done
}

db2whDelete 

disp_msglvl1 "Delete all files from /mnt/clusterfs"
rm -rf /mnt/clusterfs/*

