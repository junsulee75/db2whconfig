#!/bin/bash

source config.ini # use /bin/bash for reading from the current directory
source jscommon.sh

nfssvrConfig() {

disp_msglvl1 " Configure NFS server on $headhost"    
disp_msglvl2 "install NFS server packages"     
yum -y install nfs-utils
disp_msglvl2 "create /mnt/clusterfs shared path"      
mkdir -p /mnt/clusterfs

disp_msglvl2 "configure NFS server : /etc/exports"   
nfs_svr_string="/mnt/clusterfs"
for node in $datahost
do
    export nfs_svr_string="$nfs_svr_string $node(rw,sync,no_root_squash,no_all_squash)"
done

NFSSVR_CONFIG=/etc/exports
if [ -f "$NFSSVR_CONFIG" ]; then
    # File exists, so delete it

    disp_msglvl2 "Backing up existing $NFSSVR_CONFIG to $NFSSVR_CONFIG.bak.`date +%Y%m%d_%H%M%S` and delete" 
    cp $NFSSVR_CONFIG $NFSSVR_CONFIG.bak.`date +%Y%m%d_%H%M%S`
    rm -f $NFSSVR_CONFIG 
fi 

echo $nfs_svr_string >> /etc/exports     

disp_msglvl2 "check configured /etc/exports "   
cat /etc/exports


}

nfssvrStart() {
    disp_msglvl1 " NFS server restart "  
    systemctl stop rpcbind nfs-server
    systemctl disable rpcbind nfs-server

    systemctl start rpcbind nfs-server
    systemctl enable rpcbind nfs-server
    
}

nfssvrConfig
nfssvrStart

