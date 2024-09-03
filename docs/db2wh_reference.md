# DB2wh reference   

## Contents

- [DB2wh reference](#db2wh-reference)
  - [Contents](#contents)
  - [Command reference](#command-reference)
    - [LDAP](#ldap)
  - [Logs](#logs)
    - [collect DB2 warehouse logs](#collect-db2-warehouse-logs)
  - [Debug status](#debug-status)
  - [Files](#files)


## Command reference  

```
podman exec -it Db2wh bash   # Go into the container   
podman exec -it Db2wh status   # status check  
podman exec -it Db2wh setpass <new password> # Change bluadmin password   

/opt/ibm/dsserver/scripts/recovery/mgmt_health_check.pl -what LDAPrunning -debug  # service check each   
```

### LDAP
```
systemctl status slapd.service     ## internal LDAP service check  
netstat -an |egrep "State|:389"    ## ldap connection 
ldapsearch -x -Z    # list all LDAP user names   
```
[Content](#contents)  

## Logs  
```
/var/log/Db2wh_local.log    
```

### collect DB2 warehouse logs
```
podman exec -it Db2wh getlogs > db2wh.log
```

```
cat db2wh.log

...
Logs successfully collected and saved to <host volume>/tmp/Db2wh_240412033640_logs.zip 
Your mounted host volume was specified in the docker run command (e.g. docker run ... -v <host volume>:/mnt/bludata0)
```

```
# ls /mnt/clusterfs/tmp
Db2wh_240412033640_logs.zip  Db2wh_Local_240214134053_logs.zip
```


[Content](#contents)    

## Debug status

LDAP status debug   
```
dsadm@db2wh1 - Db2wh ~]$ /opt/ibm/dsserver/scripts/recovery/mgmt_health_check.pl -what LDAPrunning -debug
Redirecting to /bin/systemctl status slapd.service
Test case: LDAPrunning
	config: Dynamite
	longdescription: Check if LDAP server is running
Results:
	cmd:  service slapd status | grep PID | grep slapd 2>&1
	debug:message: found slapd pid: 578659

	output:  Main PID: 578659 (slapd)

	rc: 0
	status: 0
	tc: health_check::test_service_running




SUMMARY

LDAPrunning                   : RUNNING

```
[Content](#contents) 

## Files

```
/opt/ibm/dsserver/scripts/userExists.sh      
```

```sh
#!/bin/sh
# check for user existence.

LDAP_INFO_FILE="/mnt/blumeta0/ldap/external/.ldap_info.json"

dsserver_home="/opt/ibm/dsserver"
getpropfrompropfile() {
    sort ${1} | uniq | grep  "^${2}=" | sed "s%${2}=\(.*\)%\1%"
}

getdswebserverprop() {
    propsFileName=${dsserver_home}/Config/dswebserver.properties
    getpropfrompropfile ${propsFileName} ${1}
}

if [[ $# -lt 1 ]]; then
    cat <<USAGE
Error: No arguments
Usage: $0 <user id> [ <time limit> ]

- user id: user id to check for

- time limit: wait at most time limit (default 30) seconds for a search to
  complete when internal LDAP look-up is used

ex: $0 user1
    $0 user2 15
USAGE
    exit 1
fi

if [[ -f $LDAP_INFO_FILE ]]; then    ## external LDAP configuration 이 있으면. 
    # Clear all entries in the SSSD cache to ensure we're getting a live result
    # This is needed to safely check for user existence.
    sudo sss_cache -E &> /dev/null
    id $1 &> /dev/null
    rc=$?
else
    secret_encrypted=$(getdswebserverprop "ldap.root.passwd")
    secret=$(${dsserver_home}/scripts/decrypt.sh $secret_encrypted)
    timelimit=${2:-30}
    [[ $timelimit =~ ^[0-9]+$ ]] || timelimit=30
    chk=$(ldapsearch -x -Z -v -l $timelimit -D "cn=bluldap,dc=blustratus,dc=com" -w $secret -b "dc=blustratus,dc=com" 2> /dev/null | grep uid: | grep -w $1 | cut -f2 -d:)
    if [[ X"$chk" != "X" ]]; then
        rc=0
    else
        rc=1
    fi
fi

if [[ $rc -eq 0 ]]; then
    echo "user exists"
else
    echo "user does not exist"
fi
exit $rc
```

[Content](#contents) 


