[Go to main page](https://github.ibm.com/junsulee/c)

# Db2wh manual installation    

Manual installation steps output to see how it works first.        
Test based on [KC page](https://www.ibm.com/docs/en/db2-warehouse?topic=setting-up-db2-warehouse)    

I will run command as script mode at most as those will be added to scripts with the tests.    

## Contents

- [Db2wh manual installation](#db2wh-manual-installation)
  - [Contents](#contents)
  - [Prerequisites](#prerequisites)
  - [Create VMs](#create-vms)
  - [Enable ip port forwarding.](#enable-ip-port-forwarding)
  - [Install podman](#install-podman)
  - [Create a path  (SMP)](#create-a-path--smp)
  - [Create NFS file system   (MPP only)](#create-nfs-file-system---mpp-only)
    - [Header node (NFS server)](#header-node-nfs-server)
    - [Data nodes (NFS clients)](#data-nodes-nfs-clients)
  - [Get API keys and logon](#get-api-keys-and-logon)
  - [Pull the Db2 Warehouse Enterprise Edition container image](#pull-the-db2-warehouse-enterprise-edition-container-image)
  - [Create node configuration file ( MPP Only  )](#create-node-configuration-file--mpp-only--)
  - [Deploy](#deploy)
  - [Check the progress](#check-the-progress)
  - [Failure scenario](#failure-scenario)
    - [Deployment failure due to small system memory 8GB](#deployment-failure-due-to-small-system-memory-8gb)


## Prerequisites 

Nothing special. 

## Create VMs      

For MPP(DPF),create 3 linux hosts on fyre.     
For SMP(Single), create 1 linux host on fyre.    

- Redhat 8.8 (Version may not matter. Just chose a current latest for Redhat8.X)  
- 16 GB Memory x 3 hosts (MPP) / 16 GB memory x 1 host (SMP)    

If you use quick burn, the max memory per host is 8 GB.   
For MPP, by default, Db2wh create 8 partitions on each host, then mostly it fails    
because 8 GB is too small for 8 partition.   
Deployment will fail with instance memory OOM.          
Then, you may plan the number of less parttions if this is just a test purpose.   
Necessary options are described in [Deploy](#deploy) section.    
4 partition on each host deploys successfully for 8 GB memory hosts.     



[Content](#contents)    

## Enable ip port forwarding.   

On all hosts, run this.   

```
sysctl -w net.ipv4.ip_forward=1
``` 

And check if the change is applied.  

## Install podman   

On all hosts, install podman or docker.   
Podman is installed already on quickburn fyre Redhat 8.8. Good !   
So no need to install podman this time.   
Check if `podman` command works.    
```
# which podman
/usr/bin/podman
# rpm -qa |grep -i podman
podman-catatonit-4.4.1-12.module+el8.8.0+18735+a32c1292.x86_64
podman-4.4.1-12.module+el8.8.0+18735+a32c1292.x86_64

# podman 
```
[Content](#contents)    

## Create a path  (SMP) 

```
mkdir -p /mnt/clusterfs
```


## Create NFS file system   (MPP only)   

For SMP(Single) on one host, skip NFS configuration steps.   

### Header node (NFS server)  
First node will be NFS server.    
From the first node,   

Install nfs  
```
yum -y install nfs-utils
```

Create the path to use as NFS   
```
mkdir -p /mnt/clusterfs
```

Configure NFS server   
```
# nfs_svr_string="/mnt/clusterfs"
# datahostlist1=`grep fyre.ibm.com /etc/hosts |awk '{print $2;}'|grep -v 1.fyre.ibm.com`
# echo $datahostlist1
jsdb2wh2.fyre.ibm.com jsdb2wh3.fyre.ibm.com

# for node in $datahostlist1
> do
> export nfs_svr_string="$nfs_svr_string $node(rw,sync,no_root_squash,no_all_squash)"
> done
# echo $nfs_svr_string
/mnt/clusterfs jsdb2wh2.fyre.ibm.com(rw,sync,no_root_squash,no_all_squash) jsdb2wh3.fyre.ibm.com(rw,sync,no_root_squash,no_all_squash) 

# echo $nfs_svr_string >> /etc/exports
# cat /etc/exports
/mnt/clusterfs jsdb2wh2.fyre.ibm.com(rw,sync,no_root_squash,no_all_squash) jsdb2wh3.fyre.ibm.com(rw,sync,no_root_squash,no_all_squash)
```

Start NFS server   

```
# systemctl start rpcbind nfs-server
# systemctl enable rpcbind nfs-server
Created symlink /etc/systemd/system/multi-user.target.wants/nfs-server.service → /usr/lib/systemd/system/nfs-server.service.
```

[Content](#contents) 

### Data nodes (NFS clients)   
On each data node,  

install NFS client driver   

```
# yum -y install nfs-utils
```

Configure nfs client.  

```
# nfs_svr=`grep 1.fyre.ibm.com /etc/hosts |awk '{print $3;}'`
# echo $nfs_svr
# echo "$nfs_svr:/mnt/clusterfs    /mnt/clusterfs    nfs    rw,relatime,vers=3,rsize=1048576,wsize=1048576,namlen=255,hard,intr,proto=tcp,port=0,timeo=600,retrans=2,sec=sys,nolock    0 0" 
# echo "$nfs_svr:/mnt/clusterfs    /mnt/clusterfs    nfs    rw,relatime,vers=3,rsize=1048576,wsize=1048576,namlen=255,hard,intr,proto=tcp,port=0,timeo=600,retrans=2,sec=sys,nolock    0 0" >> /etc/fstab
# cat /etc/fstab 

```

start NFS client driver

```
# systemctl start rpcbind
# systemctl enable rpcbind
```

Mount.  
```
# mkdir -p /mnt/clusterfs
# mount /mnt/clusterfs
```
Test the file write.  

```
touch /mnt/clusterfs/testfile.`hostname`
```

[Content](#contents) 

## Get API keys and logon  

You will need your IBM CLOUD API KEY to access Db2wh image registry.   

How to generate IBM CLOUD AP KEY ? Refer the [link](https://www.ibm.com/docs/en/db2-warehouse?topic=warehouse-getting-container-images)   
1.  Log into IBM Cloud - https://cloud.ibm.com/login. 
2.  Go to Manage > Click Access > Click IBM Cloud API keys.
3.  Then create.

Example of mine.   
Run the same on on all hosts.  

```
[root@jsdb2wh1 ~]# echo xEK_-ybcbRnttexfjGShcecrSyMW5ZgFxT0S0L5BmNIF | podman login -u iamapikey --password-stdin icr.io
Login Succeeded!
```

> JS TODO : Error doing remote script.  

[Content](#contents) 

## Pull the Db2 Warehouse Enterprise Edition container image 

Getting image is `podman get` command.   
You may do in advance or skip this as we will run `podman run` command anyway   
and it will download image and deploy.   
However, no harm to do this in advance. 
This takes some time.    

For MPP, do this on all hosts.  

```
[root@jsdb2wh1 ~]# podman pull icr.io/obs/hdm/db2wh_ee:v11.5.8.0-db2wh-linux
...
[root@jsdb2wh1 ~]# podman image list
REPOSITORY               TAG                    IMAGE ID      CREATED       SIZE
icr.io/obs/hdm/db2wh_ee  v11.5.8.0-db2wh-linux  3bb66f5bba27  6 months ago  9.9 GB
```

`podman run` command will pull the image actually.   
On MPP, I prefer to pull the images in advance, then run `podman run`.     

Do the same thing on other hosts too.   

> JS TODO : Error doing remote script.  


[Content](#contents) 

## Create node configuration file ( MPP Only  )    

```
[root@jsdb2wh1 clusterfs]# cat /mnt/clusterfs/nodes
head_node=jsdb2wh1:10.11.26.85
data_node1=jsdb2wh2:10.11.26.153
data_node2=jsdb2wh3:10.11.26.196
```

## Deploy

Run the command from **all hosts** concurrently.   
For MPP, you need to run this command on all hosts concurrently.      

Change the version if needed.  

```
podman run -d -it --privileged=true --net=host --name=Db2wh -v /mnt/clusterfs:/mnt/bludata0 -v /mnt/clusterfs:/mnt/blumeta0 icr.io/obs/hdm/db2wh_ee:v11.5.8.0-db2wh-linux
```

Command to create ORACLE compatible DB using `-e ENABLE_ORACLE_COMPATIBILITY=YES`    
```
podman run -d -it --privileged=true --net=host --name=Db2wh -v /mnt/clusterfs:/mnt/bludata0 -v /mnt/clusterfs:/mnt/blumeta0 -e ENABLE_ORACLE_COMPATIBILITY=YES icr.io/obs/hdm/db2wh_ee:v11.5.8.0-db2wh-linux
```

For MPP only,    
Command to adjust the number of partitions on each host using   `-e MLN_DISTRIBUTION="X:Y"` , 
where X is number on the head node, Y on data nodes    
This example is setting 4 partitions each host.  
Or may use `MLN_TOTAL=Z` if number of partition would be same for each node.     
```
podman run -d -it --privileged=true --net=host --name=Db2wh -v /mnt/clusterfs:/mnt/bludata0 -v /mnt/clusterfs:/mnt/blumeta0 -e ENABLE_ORACLE_COMPATIBILITY=YES -e MLN_DISTRIBUTION="4:4" icr.io/obs/hdm/db2wh_ee:v11.5.8.0-db2wh-linux
```

some other example cases.   

```
podman run -d -it --privileged=true --net=host --name=Db2wh --pids limit=-1 -e DB_TERRITORY=KR  -v /data:/mnt/bludata0  -v /data:/mnt/blumeta0 icr.io/obs/hdm/db2wh_ee:v11.5.8.0-db2wh-linux 
```

[Content](#contents) 

## Check the progress  

On header node,  

```
# podman logs --follow Db2wh
``` 

If you run `podman run` command only on header node, the log will be stuck at the following.   

```
Detected architecture x86-64.

Welcome to Db2 Warehouse!

Set hostname to <jsdb2wh1.fyre.ibm.com>.
Initializing machine ID from random generator.
Cannot add dependency job for unit systemd-tmpfiles-clean.timer, ignoring: Unit is masked.
[  OK  ] Reached target Swap.
[  OK  ] Created slice Root Slice.
[  OK  ] Listening on Delayed Shutdown Socket.
...
[  OK  ] Started DB2 v11.5.8.0.
         Starting LSB: Bring up/down networking..
...
[22951.290298] start_dashDB_local.sh[208]: IBM Db2 Warehouse stack is NOT initialized yet.
```

After running `podman run` command on all hosts, the log will be moving.   

```
...
[28189.744155] start_dashDB_local.sh[208]: configure_user_management completed successfully.
[28192.769087] start_dashDB_local.sh[208]: Creating IBM Db2 Warehouse instance and directories
[28227.055191] start_dashDB_local.sh[208]: Initialize IBM Db2 Warehouse instance to use up to 80% of the memory assigned to container namespace
[28231.553072] start_dashDB_local.sh[208]: ***********************************************************
[28231.553440] start_dashDB_local.sh[208]: **                  You're almost there                  **
[28231.553680] start_dashDB_local.sh[208]: ***********************************************************
...
```

[Content](#contents) 

## Failure scenario 

### Deployment failure due to small system memory 8GB   

Error message
```
# podman logs --follow Db2wh  
...
Unable to communticate to node jsdb2wh1 over the port(s) 50000-50001,60000-60024
Check the network and firewall settings, and ensure that the indicated port/port range is open
On MPP clusters, check network and firewall settings on each node
* port(s) 50000-50001,60000-60024: CLOSED
==============================================
Running communication test on node: jsdb2wh2
==============================================
Running database port check ...
==============================================
Running communication test on node: jsdb2wh3
==============================================
Running database port check ...
Distributing MLNs ...
Configuring MPP partitions ...
Starting services on node jsdb2wh2
Starting services on node jsdb2wh3
Configuring IBM Db2 Warehouse for COLUMN storage...
database SSL configuration
New Root CA generated. Download the new certificate to trust when using SSL connections to the database.
Restarting Db2...
Creating database...
Database BLUDB was not created successfully. Unable to continue.
IBM Db2 Warehouse installation failed. Retry the operation by re-deploying a container.

* If this is an initial deployment:
  a) Remove the container using the 'docker rm -f Db2wh' command.
  b) Remove the image using the 'docker rmi <image>' command.
  c) Delete the contents of the mounted host volume specified in the docker run command
    (e.g. docker run ... -v <host volume>:/mnt/bludata0)
    Note: THIS WILL RESULT IN DATA LOSS
  d) Redeploy the image.

Note: Db2wh is an example of a container name. Use the container name
 that you specified for the docker run command.

If the same failure occurs, contact IBM Service.
Running 'Docker storage driver' test...
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
FATAL RUNTIME ERROR DETECTED
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
Dumping system configuration details to help diagnose the problem
Running 'Docker storage driver' test...
Generation of diagnostic information complete; stopping deployment of container immediately
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
FATAL RUNTIME ERROR DETECTED
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
Dumping system configuration details to help diagnose the problem
Running 'Docker storage driver' test...
Generation of diagnostic information complete; stopping deployment of container immediately
```

Go into the container  

```
[root@jsdb2wh1 ~]# podman exec -it Db2wh bash
```
Run `status`

```
[root@jsdb2wh1 - Db2wh /]# status
Getting IBM Db2 Warehouse status...

-- IBM Db2 Warehouse Services Status --
b'Redirecting to /bin/systemctl status slapd.service'
SUMMARY

Db2TablesOnline               : STOPPED
Db2connectivity               : STOPPED
Db2running                    : RUNNING
LDAPrunning                   : RUNNING
WebConsole                    : STOPPED
LDAPsearch                    : SUCCESS
Spark                         : DISABLED
* If the 'LDAPsearch' status in the output is SUCCESS, IBM Db2 Warehouse
  can access the LDAP server.

Getting IBM Db2 Warehouse High Availability Status...
-- IBM Db2 Warehouse System Manager Status --
HA Management is DOWN. Core container service initialization failed.. check /var/log/Db2wh_local.log for more info.

-- IBM Db2 Warehouse Cluster Status --
+----------+--------------+------+--------+-------+
| NodeName |      IP      | Type |  Role  | State |
+----------+--------------+------+--------+-------+
| jsdb2wh1 | 10.11.26.85  | HEAD | ACTIVE |  DOWN |
| jsdb2wh2 | 10.11.26.153 | DATA | ACTIVE |  DOWN |
| jsdb2wh3 | 10.11.26.196 | DATA | ACTIVE |  DOWN |
+----------+--------------+------+--------+-------+

**************** IBM Db2 Warehouse license information ****************
 * License type             : Trial
 * License expiry date      : 02/26/2024
 * Number of days remaining : 89
 * License status           : Active
***********************************************************************
```

Then, check `/var/log/Db2wh_local.log`.    

Instance started successfully.   
```
[2023-11-29 08:26:47,862] - dashdb_db2_functions.sh:31(is_db2_started) - DEBUG: Db2 is already stopped ...
[2023-11-29 08:26:47,869] - dashdb_db2_functions.sh:108(db2start_or_exit) - DEBUG: db2start
[2023-11-29 08:27:01,436] - dashdb_db2_functions.sh:109(db2start_or_exit) - DEBUG: 11/29/2023 08:26:59     0   0   SQL1063N  DB2START processing was successful.
[2023-11-29 08:27:01,576] - dashdb_db2_functions.sh:109(db2start_or_exit) - DEBUG: 11/29/2023 08:27:01    23   0   SQL1063N  DB2START processing was successful.
...
[2023-11-29 08:27:01,582] - dashdb_db2_functions.sh:109(db2start_or_exit) - DEBUG: SQL1063N  DB2START processing was successful.
[2023-11-29 08:27:01,594] - dashdb_db2_functions.sh:134(db2start_or_exit) - DEBUG: Verifying db2 processes are fully operational
[2023-11-29 08:27:03,673] - ssh_parallel:57 - DEBUG: ssh_parallel called with arguments : Namespace(command='db2pd -inst > /dev/null 2>&1', mln=True, nodes=None, quiet=False, timeout=300, user='db2inst1')
[2023-11-29 08:27:15,147] - dashdb_db2_functions.sh:152(db2start_or_exit) - DEBUG: IBM Db2 Warehouse engine startup verified
```

But DB creation failed.  
```
...
[2023-11-29 08:27:15,867] - initialize_dashDB2.sh:123(main) - INFO: Creating database...
[2023-11-29 08:27:15,948] - initialize_dashDB2.sh:124(main) - DEBUG: 1. Create BLUDB
[2023-11-29 08:27:18,062] - initialize_dashDB2.sh:124(main) - DEBUG: CREATE DATABASE BLUDB ALIAS BLUDB USING CODESET UTF-8 TERRITORY US COLLATE USING IDENTITY PAGESIZE 32768 ENCRYPT AUTOCONFIGURE APPLY NONE
[2023-11-29 08:30:57,972] - initialize_dashDB2.sh:124(main) - DEBUG: SQL0101N  The statement was not processed because a limit such as a memory
[2023-11-29 08:30:57,981] - initialize_dashDB2.sh:124(main) - DEBUG: limit, an SQL limit, or a database limit was reached.  LINE NUMBER=1.
[2023-11-29 08:30:57,987] - initialize_dashDB2.sh:124(main) - DEBUG: SQLSTATE=54001
...
```

db2 get dbm cfg  
```

 Global instance memory (% or 4KB)     (INSTANCE_MEMORY) = 80
 Member instance memory (% or 4KB)                       = GLOBAL
```

db2diag : system memory might be too small. I created 8 GB memory for each host.  
May need to try with 16 GB memory for each host.   

```
2023-11-29-08.30.07.959040+000 I125105E1115          LEVEL: Warning
PID     : 46151                TID : 140514519148288 PROC : db2sysc 0
INSTANCE: db2inst1             NODE : 000            DB   : BLUDB
APPHDL  : 0-54                 APPID: *N0.db2inst1.231129082738
UOWID   : 58                   ACTID: 54
AUTHID  : DB2INST1             HOSTNAME: jsdb2wh1.fyre.ibm.com
EDUID   : 127                  EDUNAME: db2agent (BLUDB) 0
FUNCTION: DB2 UDB, SQO Memory Management, SqloMemController::requestMemory, probe:50
MESSAGE : ZRC=0x8B0F0000=-1961951232=SQLO_NOMEM "No Memory Available"
          DIA8300C A memory heap error has occurred.
DATA #1 : String, 36 bytes
OOM - Instance memory request failed
DATA #2 : String, 35 bytes
Logging disabled until next success
DATA #3 : unsigned integer, 8 bytes
1048576
DATA #4 : unsigned integer, 8 bytes
0
DATA #5 : String, 13 bytes
APPL-BLUDB
DATA #6 : unsigned integer, 8 bytes
81657856
DATA #7 : unsigned integer, 8 bytes
0
DATA #8 : unsigned integer, 8 bytes
806821888
DATA #9 : unsigned integer, 8 bytes
807100416
DATA #10: unsigned integer, 8 bytes
0
```

By default, DB2wh will create 8 parttions per host.   
You may use `-e MLN_DISTRIBUTION="X:Y"`     
X is number on the head node, Y on data nodes.     


[Content](#contents) 

