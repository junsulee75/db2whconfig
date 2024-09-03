#!/bin/bash

source config.ini # use /bin/bash for reading from the current directory
source jscommon.sh

nfsClientConfig() {

    disp_msglvl1 "Configure NFS client"  

    nfs_package="nfs-utils"
    ## NFS client configuration line to add to /etc/fstab of data nodes.   
    nfsClientStr=`echo "$headhost:/mnt/clusterfs    /mnt/clusterfs    nfs    rw,relatime,vers=3,rsize=1048576,wsize=1048576,namlen=255,hard,intr,proto=tcp,port=0,timeo=600,retrans=2,sec=sys,nolock    0 0"`

    for HOST in $datahost
    do
        disp_msglvl2 " $HOST : install NFS package " 
        # install nfs if not exist
        if ssh $SSH_NO_BANNER $HOST yum list installed "$nfs_package" >/dev/null 2>&1; then
            echo "NFS package $nfs_package is already installed. Skipping..."
        else
            ssh $SSH_NO_BANNER $HOST yum -y install nfs-utils
        fi
        
        # ex) ssh -q -o LogLevel=QUIET jsdb2wh2 "sed -i '/clusterfs/d' /etc/fstab"
        disp_msglvl2 "$HOST : Remove the line having /mnt/clusterfs from /etc/fstab  "
        #disp_msglvl2 "$HOST : current existing /etc/fstab "
        #ssh $SSH_NO_BANNER $HOST  "cat /etc/fstab"
        ssh $SSH_NO_BANNER $HOST  "sed -i '/clusterfs/d' /etc/fstab"
        #disp_msglvl2 "$HOST : /etc/fstab after deleting the line"
        #ssh $SSH_NO_BANNER $HOST  "cat /etc/fstab"
        
        disp_msglvl2 " $HOST : Add NFS client configuration line to /etc/fstab  "
        ssh $SSH_NO_BANNER $HOST  "echo $nfsClientStr >> /etc/fstab"
        ssh $SSH_NO_BANNER $HOST  "grep clusterfs /etc/fstab"

        disp_msglvl2 " $HOST : Create mount point directory /mnt/clusterfs"  
        ssh $SSH_NO_BANNER $HOST  "mkdir -p /mnt/clusterfs;rm -f /mnt/clusterfs/testfile.*;ls /mnt/clusterfs"
    done
}

nfsClientRestart() {
    
    for HOST in $datahost
    do
        disp_msglvl2 "$HOST : nfs client stop"
        ssh $SSH_NO_BANNER $HOST "systemctl disable rpcbind"
        ssh $SSH_NO_BANNER $HOST "systemctl stop rpcbind"
        
        disp_msglvl2 "$HOST : nfs client start"
        ssh $SSH_NO_BANNER $HOST "systemctl start rpcbind"
        ssh $SSH_NO_BANNER $HOST "systemctl enable rpcbind"
        
    done
    
}


nfsClientMount(){
        
    for HOST in $datahost
    do
        disp_msglvl2 "$HOST : mount"
        ssh $SSH_NO_BANNER $HOST "mount /mnt/clusterfs"
        ssh $SSH_NO_BANNER $HOST "touch /mnt/clusterfs/testfile.$HOST"
        ssh $SSH_NO_BANNER $HOST "ls -al /mnt/clusterfs"
    done
}
nfsClientConfig
nfsClientRestart
nfsClientMount
    


