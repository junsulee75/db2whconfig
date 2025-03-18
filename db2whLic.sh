#!/bin/bash

#source `pwd`/conf ## for /bin/ksh
source config.ini # use /bin/bash for reading from the current directory
source jscommon.sh

db2whLic(){

	cp dash_c.lic /mnt/clusterfs
	podman exec -it Db2wh dashlicm -a /mnt/blumeta0/dash_c.lic
}

db2whLic