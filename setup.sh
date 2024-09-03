#!/bin/bash

export PROMPT=0

menu.py 1,1,5   # Enable ip port forwarding 

menu.py 1,2,5    # NFS server configuration
menu.py 1,3,5    # NFS client configuration
menu.py 1,4,5    # Create nodes file  

menu.py 2,1,3    # Db2wh image download
menu.py 2,2,3    # Db2wh 1st run 
