[Go to main page](https://github.ibm.com/junsulee/c)

# Db2wh fixpack / SB upgrade test  

[Reference step](https://www.ibm.com/docs/en/db2-warehouse?topic=warehouse-updating-mpp-linux)   

## Contents

- [Db2wh fixpack / SB upgrade test](#db2wh-fixpack--sb-upgrade-test)
  - [Contents](#contents)
  - [Current environment](#current-environment)
  - [Download v11.5.8.0 latest CSB images](#download-v11580-latest-csb-images)
  - [Stop warehouse service](#stop-warehouse-service)
  - [Stop existing container on all hosts](#stop-existing-container-on-all-hosts)
  - [Rename the current version container on all hosts](#rename-the-current-version-container-on-all-hosts)
  - [Spin up new container](#spin-up-new-container)
  - [Check the new container](#check-the-new-container)



## Current environment
Internel reference.    
In house PoC test Db2wh fixpack update from 11.5.7.0 to 11.5.8.0.   


Current existing Db2wh image 
```
[root@db2whtest1 ~]# podman images
REPOSITORY               TAG                    IMAGE ID      CREATED      SIZE
icr.io/obs/hdm/db2wh_ee  v11.5.7.0-db2wh-linux  499fca0c1ddb  2 years ago  8.28 GB
```

Current existing container   
```
[root@db2whtest1 ~]# podman ps -a
CONTAINER ID  IMAGE                                          COMMAND     CREATED       STATUS       PORTS       NAMES
b3770a972714  icr.io/obs/hdm/db2wh_ee:v11.5.7.0-db2wh-linux              30 hours ago  Up 30 hours              Db2wh
```

Current version.   
```
[root@db2whtest1 ~]# podman exec -it Db2wh bash
[root@db2whtest1 - Db2wh /]# version -a | grep -i dashdb |egrep "image|special"
image_version=hyc-dsp-docker-local.artifactory.swg-devops.com/ibmdashdb/local:v11.5.7.0-20220114-0701-local
dashDB_build_level=special_13745
dashDB_specialbuild=13745
[root@db2whtest1 - Db2wh /]# su - db2inst1
[db2inst1@db2whtest1 - Db2wh ~]$ db2level |grep Infor
Informational tokens are "DB2 v11.5.7.0", "special_13745",
[db2inst1@db2whtest1 - Db2wh ~]$ exit
[root@db2whtest1 - Db2wh /]# exit
```

[Content](#contents) 

## Download v11.5.8.0 latest CSB images

Run these on all hosts.   

```sh
export MYAPIK="XXXX" ## Use your IBM KEY
echo $MYAPIK | podman login -u iamapikey --password-stdin icr.io
podman pull icr.io/obs/hdm/db2wh_ee:v11.5.8.0-db2wh-linux
```

Now, we have two images.  

```
[root@db2whtest1 db2wh_test_env]# podman images
REPOSITORY               TAG                    IMAGE ID      CREATED        SIZE
icr.io/obs/hdm/db2wh_ee  v11.5.8.0-db2wh-linux  3bb66f5bba27  10 months ago  9.9 GB
icr.io/obs/hdm/db2wh_ee  v11.5.7.0-db2wh-linux  499fca0c1ddb  2 years ago    8.28 GB

[root@db2whtest1 db2wh_test_env]# ssh db2whtest2 "podman images"
REPOSITORY               TAG                    IMAGE ID      CREATED        SIZE
icr.io/obs/hdm/db2wh_ee  v11.5.8.0-db2wh-linux  3bb66f5bba27  10 months ago  9.9 GB
icr.io/obs/hdm/db2wh_ee  v11.5.7.0-db2wh-linux  499fca0c1ddb  2 years ago    8.28 GB

[root@db2whtest1 db2wh_test_env]# ssh db2whtest3 "podman images"
REPOSITORY               TAG                    IMAGE ID      CREATED        SIZE
icr.io/obs/hdm/db2wh_ee  v11.5.8.0-db2wh-linux  3bb66f5bba27  10 months ago  9.9 GB
icr.io/obs/hdm/db2wh_ee  v11.5.7.0-db2wh-linux  499fca0c1ddb  2 years ago    8.28 GB
```


[Content](#contents)    

## Stop warehouse service

On head host only. 
```
[root@db2whtest1 db2wh_test_env]# podman exec -it Db2wh stop
-- Stopping IBM Db2 Warehouse services --

-- Stopping High availability service --
Stopping HA Management on node 'db2whtest1'...
Stopping HA Management on node 'db2whtest2'...
Stopping HA Management on node 'db2whtest3'...

-- Stopping core services --
Stopping dsserver...

Stopping server dsweb.
Server dsweb is not running.
SERVER STATUS: INACTIVE
[2024-03-09.16:01:20]  INFO: DEPLOYMENT_CONFIG: MPP (number of Db2 nodes: 12)
[2024-03-09.16:01:20]  INFO: Closing all connections to the database...
[2024-03-09.16:01:24]  INFO: List applications for database BLUDB
[2024-03-09.16:01:25]  INFO: Checking database consistency for BLUDB:
[2024-03-09.16:01:25]  INFO: Deactivate db BLUDB
[2024-03-09.16:01:28]  INFO: Checking database consistency after deactivating db
[2024-03-09.16:01:54]  INFO: db2 instance was shutdown cleanly.
mgmt/apiserver/analytics service stop statuses: [True, True, True, True, True]

-- Successfully stopped IBM Db2 Warehouse --
``` 

[Content](#contents)  


## Stop existing container on all hosts

```
[root@db2whtest1 db2wh_test_env]# podman stop Db2wh
Db2wh
[root@db2whtest1 db2wh_test_env]# ssh db2whtest2 "podman stop Db2wh"
Db2wh
[root@db2whtest1 db2wh_test_env]# ssh db2whtest3 "podman stop Db2wh"
Db2wh
```

Check if the process is not active.  
```
[root@db2whtest1 db2wh_test_env]# podman ps
CONTAINER ID  IMAGE       COMMAND     CREATED     STATUS      PORTS       NAMES
[root@db2whtest1 db2wh_test_env]# ssh db2whtest2 "podman ps"
CONTAINER ID  IMAGE       COMMAND     CREATED     STATUS      PORTS       NAMES
[root@db2whtest1 db2wh_test_env]# ssh db2whtest3 "podman ps"
CONTAINER ID  IMAGE       COMMAND     CREATED     STATUS      PORTS       NAMES
```

[Content](#contents)  

## Rename the current version container on all hosts
```
[root@db2whtest1 db2wh_test_env]# podman rename Db2wh v11.5.7.0
[root@db2whtest1 db2wh_test_env]# ssh db2whtest2 "podman rename Db2wh v11.5.7.0"
[root@db2whtest1 db2wh_test_env]# ssh db2whtest3 "podman rename Db2wh v11.5.7.0"
```

Renamed container.   
```
[root@db2whtest1 db2wh_test_env]# podman ps -a
CONTAINER ID  IMAGE                                          COMMAND     CREATED       STATUS                       PORTS       NAMES
b3770a972714  icr.io/obs/hdm/db2wh_ee:v11.5.7.0-db2wh-linux              31 hours ago  Exited (130) 11 minutes ago              v11.5.7.0
[root@db2whtest1 db2wh_test_env]# podman ps -a --format '{{.Names}}'
v11.5.7.0

[root@db2whtest1 db2wh_test_env]# ssh db2whtest2 "podman ps -a --format '{{.Names}}'"
v11.5.7.0
[root@db2whtest1 db2wh_test_env]# ssh db2whtest3 "podman ps -a --format '{{.Names}}'"
v11.5.7.0

```

[Content](#contents) 


## Spin up new container  

Run on all hosts concurrently.    

> NOTE
> Do not wait until the command finishes running on one node host before issuing it on another.  
>  
```
podman run -d -it --privileged=true --net=host --name=Db2wh -v /mnt/clusterfs:/mnt/bludata0 -v /mnt/clusterfs:/mnt/blumeta0 icr.io/obs/hdm/db2wh_ee:v11.5.8.0-db2wh-linux
``` 

And monitor the progress.  
```
podman logs --follow Db2wh
```

The log will show it detects the new version image and does upgrade automatically.   

```
Welcome to Db2 Warehouse!
...
[  OK  ] Started DB2 v11.5.8.0.
...
[113878.391526] start_dashDB_local.sh[208]: #################################################
[113878.397322] start_dashDB_local.sh[208]: The IBM Db2 Warehouse stack is already initialized.
[113878.402885] start_dashDB_local.sh[208]: Checking if the container needs to be upgraded to a new version ...
[113878.409035] start_dashDB_local.sh[208]: #################################################
[113881.154838] start_dashDB_local.sh[208]: The container needs to be updated from v11.5.7.0 to v11.5.8.0.
...

* VALIDATION: Validating the nodes file /mnt/blumeta0/nodes.json
Checking status of node db2whtest1
Checking status of node db2whtest2
Checking status of node db2whtest3
...

Updating IBM Db2 Warehouse instance to the new build level ...
Note this task may take few minutes depending on the changes in the new build

...
Updating database transaction log settings ...

...
[2024-03-09.16:37:36]  INFO: Starting Db2 instance
[2024-03-09.16:37:50]  INFO: Activating Database bludb

...
Running the Health check ...
#######################################################################
##      --- IBM Db2 Warehouse stack service status summary ---       ##
#######################################################################


SUMMARY

Db2TablesOnline               : RUNNING
Db2connectivity               : RUNNING
Db2running                    : RUNNING
LDAPrunning                   : RUNNING
WebConsole                    : RUNNING
 
################################################################################
Backing-up the system configuration ...
System configuration backed-up to /mnt/blumeta0/SystemConfig/db2whtest1 on the named volume successfully
********************************************************************************
******          Successfully started IBM Db2 Warehouse           ******
********************************************************************************

```

[Content](#contents)   


## Check the new container   

Now new 'Db2wh' container runs with new updated version.   

```
[root@db2whtest1 db2wh_test_env]# podman ps
CONTAINER ID  IMAGE                                          COMMAND     CREATED         STATUS         PORTS       NAMES
d3a9e294139e  icr.io/obs/hdm/db2wh_ee:v11.5.8.0-db2wh-linux              15 minutes ago  Up 15 minutes              Db2wh

[root@db2whtest1 - Db2wh /]# version -a | grep -i dashdb |egrep "image|special"
image_version=hyc-dsp-docker-local.artifactory.swg-devops.com/ibmdashdb/local:v11.5.8.0-20230510-2311-local
dashDB_build_level=special_29494
dashDB_specialbuild=29494

[root@db2whtest1 - Db2wh /]# su - db2inst1
Last login: Sat Mar  9 16:43:02 UTC 2024 on pts/1
[db2inst1@db2whtest1 - Db2wh ~]$ db2level
DB21085I  This instance or install (instance name, where applicable: 
"db2inst1") uses "64" bits and DB2 code release "SQL11058" with level 
identifier "0609010F".
Informational tokens are "DB2 v11.5.8.0", "special_29494", 
"DYN2304181003AMD64_29494", and Fix Pack "0".
Product is installed at "/opt/ibm/db2/V11.5.0.0".

```
