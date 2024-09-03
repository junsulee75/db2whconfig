#!/bin/bash

#source `pwd`/conf ## for /bin/ksh
source config.ini # use /bin/bash for reading from the current directory
source jscommon.sh


# Function tok setIBMKey on all hosts. Maybe better to do firstly for testing purpose.   

setIBMKey(){

	for HOST in $ALLHOST
	do
		disp_msglvl2 "Setting IBM key on $HOST...(1st test)"
		ssh $SSH_NO_BANNER root@$HOST "echo $IBM_KEY | podman login -u iamapikey --password-stdin icr.io"
		if [ $? -ne 0 ]; then
			echo "failure. Exit.."
		else
			echo "success !!! "
		fi
	done
}

# JS_TODO : is there a way to do this in parallel ?  
# Currently running one by one. 
# Each iteration takes lots of time. Then sometimes it fails moving on next host.  
# Somehow, IBM KEY is missing again .( Any timeout ? )   
# So before downloading, setting IBM Key again   

db2whDownload(){

	for HOST in $ALLHOST
	do
		disp_msglvl2 "Setting IBM key on $HOST... "
		ssh $SSH_NO_BANNER root@$HOST "echo $IBM_KEY | podman login -u iamapikey --password-stdin icr.io"
		if [ $? -ne 0 ]; then
			echo "failure. Exit.."
		else
			echo "success !!! "
		fi

		disp_msglvl2 "Downloading db2wh image on $HOST..."
		ssh $SSH_NO_BANNER root@$HOST "podman pull $DB2WH_IMAGE"
		if [ $? -ne 0 ]; then
			echo "failure. Exit.."
		else
			echo "success !!! "
		fi
	done
	
	for HOST in $ALLHOST
	do
		disp_msglvl2 "Checking db2wh image on $HOST..."
		ssh $SSH_NO_BANNER root@$HOST "podman image list"
		if [ $? -ne 0 ]; then
			echo "failure. Exit.."
		else
			echo "success !!! "
		fi
	done
}

setIBMKey
db2whDownload
#swCmdChkAllHost "podman xterm"
#setProfile
#pyChk ## install python 

#disp_msglvl1 "Copying frequently used commands to /usr/local/bin"   