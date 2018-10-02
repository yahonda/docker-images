#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2018 Oracle and/or its affiliates. All rights reserved.
#
# Since: January, 2018
# Author: sanjay.singh@oracle.com, paramdeep.saini@oracle.com
# Description: Add a Grid node and add Oracle Database instance based on following parameters:
#              $PUBLIC_HOSTNAME
#              $PUBLIC_IP
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#

####################### Variables and Constants #################
declare -r FALSE=1
declare -r TRUE=0
declare -r GRID_USER='grid'          ## Default gris user is grid.
declare -r ORACLE_USER='oracle'      ## default oracle user is oracle.
declare -r ETCHOSTS="/etc/hosts"     ## /etc/hosts file location.
declare -x DOMAIN                    ## Domain name will be computed based on hostname -d, otherwise pass it as env variable.
declare -x PUBLIC_IP                 ## Computed based on Node name.
declare -x PUBLIC_HOSTNAME           ## PUBLIC HOSTNAME set based on hostname
declare -x EXISTING_CLS_NODE         ## Computed during the program execution.
declare -x EXISTING_CLS_NODES        ## You must all the exisitng nodes of the cluster in comma separated strings. Otherwise installation will fail.
declare -x DHCP_CONF='false'         ## Pass env variable where value set to true for DHCP based installation.
declare -x NODE_VIP                  ## Pass it as env variable.
declare -x VIP_HOSTNAME              ## Pass as env variable.
declare -x SCAN_NAME                 ## Pass it as env variable.
declare -x SCAN_IP                   ## Pass as env variable if you do not have DNS server. Otherwise, do not pass this variable.
declare -x SINGLENIC='false'         ## Default value is false as we should use 2 nics if possible for better performance.
declare -x PRIV_IP                   ## Pass PRIV_IP is not using SINGLE NIC
declare -x CONFIGURE_GNS='false'     ## Default value set to false. However, under DSC checks, it is reverted to true.
declare -x COMMON_SCRIPTS            ## COMMON SCRIPT Locations. Pass this env variable if you have custom responsefile for grid and other scripts for DB.
declare -x PRIV_HOSTNAME             ## if SINGLENIC=true then PRIV and PUB hostname will be same. Otherise pass it as env variable.
declare -x CMAN_HOSTNAME             ## If you want to use connection manager to proxy the DB connections
declare -x CMAN_IP                   ## CMAN_IP if you want to use connection manager to proxy the DB connections
declare -x OS_PASSWORD               ## if not passed as env variable, it will be set to PASSWORD
declare -x GRID_PASSWORD             ## if not passed as env variable , it will be set to OS_PASSWORD
declare -x ORACLE_PASSWORD           ## if not passed as env variable, it will be set to OS_PASSWORD
declare -x PASSWORD                  ## If not passed as env variable , it will be set as system generated password
declare -x CLUSTER_TYPE='STANDARD'   ## Default instllation is STANDARD. You can pass DOMAIn or MEMBERDB.
declare -x GRID_RESPONSE_FILE        ## IF you pass this env variable then user based responsefile will be used. default location is COMMON_SCRIPTS.
declare -x SCRIPT_ROOT               ## SCRIPT_ROOT will be set as per your COMMON_SCRIPTS.Do not Pass env variable SCRIPT_ROOT.

progname=$(basename "$0")
###################### Variabes and Constants declaration ends here  ####################


############Sourcing Env file##########
if [ -f "/etc/rac_env_vars" ]; then
source "/etc/rac_env_vars"
fi
##########Source ENV file ends here####


###################Capture Process id and source functions.sh###############
source "$SCRIPT_DIR/functions.sh"
###########################sourcing of functions.sh ends here##############

####error_exit function sends a TERM signal, which is caught by trap command and returns exit status 15"####
trap '{ exit 15; }' TERM
###########################trap code ends here##########################

all_check()
{
check_pub_host_name
check_cls_node_names
check_ip_env_vars
check_passwd_env_vars
check_rspfile_env_vars
check_db_env_vars
}

#####################Function related to public hostname, IP and domain name check begin here ########

check_pub_host_name()
{
local domain_name
local stat

if [ -z "${PUBLIC_IP}" ]; then
    PUBLIC_IP=$(dig +short "$(hostname)")
    print_message "Public IP is set to ${PUBLIC_IP}"
else
    print_message "Public IP is set to ${PUBLIC_IP}"
fi

if [ -z "${PUBLIC_HOSTNAME}" ]; then
  PUBLIC_HOSTNAME=$(hostname)
  print_message "RAC Node PUBLIC Hostname is set to ${PUBLIC_HOSTNAME}"
 else
  print_message "RAC Node PUBLIC Hostname is set to ${PUBLIC_HOSTNAME}"
fi

if [ -z "${DOMAIN}" ]; then
domain_name=$(hostname -d)
 if [ -z "${domain_name}" ];then
   print_message  "Domain name is not defined. Setting Domain to 'example.com'"
    DOMAIN="example.com"
 else
    DOMAIN=${domain_name}
fi
 else
 print_message "Domain is defined to $DOMAIN"
fi

}

############### Function related to public hostname, IP and domain checks ends here ##########

############## Function related to check exisitng cls nodes begin here #######################
check_cls_node_names()
{
if [ -z "${EXISTING_CLS_NODES}" ]; then
	error_exit "For Node Addition, please provide the existing clustered node name."
else
	
   if isStringExist ${EXISTING_CLS_NODES} ${PUBLIC_HOSTNAME}; then
	  error_exit "EXISTING_CLS_NODES ${EXISTING_CLS_NODES} contains new node name ${PUBLIC_HOSTNAME}"
   fi

print_message "Setting Existing Cluster Node for node addition operation. This will be retrieved from ${EXISTING_CLS_NODES}"

EXISTING_CLS_NODE="$( cut -d ',' -f 1 <<< "$EXISTING_CLS_NODES" )"

if [ -z "${EXISTING_CLS_NODE}" ]; then
   error_exit " Existing Node Name of the cluster not set or set to empty string"
else
   print_message "Existing Node Name of the cluster is set to ${EXISTING_CLS_NODE}"

if resolveip ${EXISTING_CLS_NODE}; then
 print_message "Existing Cluster node resolved to IP. Check passed"
else
  error_exit "Existing Cluster node does not resolved to IP. Check Failed"
fi
fi
fi
}

############## Function related to check exisitng cls nodes begin here #######################

check_ip_env_vars ()
{
if [ "${DHCP_CONF}" != 'true' ]; then
  print_message "Default setting of AUTO GNS VIP set to false. If you want to use AUTO GNS VIP, please pass DHCP_CONF as an env parameter set to true"
  DHCP_CONF=false
if [ -z "${NODE_VIP}" ]; then
   error_exit "RAC Node ViP is not set or set to empty string"
else
   print_message "RAC VIP set to ${NODE_VIP}"
fi

if [ -z "${VIP_HOSTNAME}" ]; then
   error_exit "RAC Node Vip hostname is not set ot set to empty string"
else
   print_message "RAC Node VIP hostname is set to ${VIP_HOSTNAME} "
fi

if [ -z ${SCAN_NAME} ]; then
  print_message "SCAN_NAME set to the empty string"
else
  print_message "SCAN_NAME name is ${SCAN_NAME}"
fi

if resolveip ${SCAN_NAME}; then
 print_message "SCAN Name resolving to IP. Check Passed!"
else
  error_exit "SCAN Name not resolving to IP. Check Failed!"
fi

if [ -z ${SCAN_IP} ]; then
   print_message "SCAN_IP set to the empty string"
else
  print_message "SCAN_IP name is ${SCAN_IP}"
fi
fi

if [ "${SINGLENIC}" == 'true' ];then
PRIV_IP=${PUBLIC_IP}
PRIV_HOSTNAME=${PUBLIC_HOSTNAME}
fi

if [ -z "${PRIV_IP}" ]; then
   error_exit "RAC Node private ip is not set ot set to empty string"
else
  print_message "RAC Node PRIV IP is set to ${PRIV_IP} "
fi

if [ -z "${PRIV_HOSTNAME}" ]; then
   error_exit "RAC Node private hostname is not set ot set to empty string"
else
  print_message "RAC Node private hostname is set to ${PRIV_HOSTNAME}"
fi


if [ -z ${CMAN_HOSTNAME} ]; then
  print_message  "CMAN_NAME set to the empty string"
else
  print_message "CMAN_HOSTNAME name is ${CMAN_HOSTNAME}"
fi

if [ -z ${CMAN_IP} ]; then
   print_message "CMAN_IP set to the empty string"
else
  print_message "CMAN_IP name is ${CMAN_IP}"
fi

}
################check ip env vars function  ends here ############################

################ Check passwd env vars function  begin here ######################
check_passwd_env_vars()
{
if [ -z ${PASSWORD} ]; then
   print_message "Password is empty string"
   PASSWORD=O$(openssl rand -base64 6 | tr -d "=+/")_1
else
  print_message "Password string is set"
fi

if [ -z "${GRID_PASSWORD}" ]; then
   print_message  "GRID_PASSWORD is empty string for $GRID_USER user"
else
  print_message "OS Password string is set for Grid  user"
fi

if [ -z "${ORACLE_PASSWORD}" ]; then
    print_message  "ORACLE_PASSWORD is empty string for $ORACLE_USER user"
else
  print_message "OS Password string is set for  Oracle user"
fi

if [ -z "${GRID_PASSWORD}" ]; then
if [ -z "${OS_PASSWORD}" ]; then
   error_exit  "OS_Password is empty string for $GRID_USER user. Password is required to setup ssh between clustered nodes"
else
  print_message "OS Password string is set for Grid user"
   GRID_PASSWORD="${OS_PASSWORD}"
fi
fi

if [ -z "${ORACLE_PASSWORD}" ]; then
if [ -z "${OS_PASSWORD}" ]; then
   error_exit  "OS_Password is empty string for $ORACLE_USER user. Password is required to setup ssh between clustered nodes"
else
  print_message "OS Password string is set for Oracle user"
   ORACLE_PASSWORD="${OS_PASSWORD}"
fi
fi

}

############### Check password env vars function ends here ########################

############### Check grid Response file function begin here ######################
check_rspfile_env_vars ()
{
if [ -z "${GRID_RESPONSE_FILE}" ];then
print_message "GRID_RESPONSE_FILE env variable set to empty. $progname will use standard cluster responsefile"
else
if [ -f $COMMON_SCRIPTS/$GRID_RESPONSE_FILE ];then
cp $COMMON_SCRIPTS/$GRID_RESPONSE_FILE $logdir/$GRID_RESPONSE_FILE
else
error_exit "$COMMON_SCRIPTS/$GRID_RESPONSE_FILE does not exist"
fi
fi

if [ -z "${SCRIPT_ROOT}" ]; then
SCRIPT_ROOT=$COMMON_SCRIPTS
print_message "Location for User script SCRIPT_ROOT set to $COMMON_SCRIPTS"
else
print_message "Location for User script SCRIPT_ROOT set to $SCRIPT_ROOT"
fi

}

############ Check responsefile function end here ######################

########### Check db env vars function begin here #######################
check_db_env_vars ()
{
if [ $CLUSTER_TYPE == 'MEMBERDB' ]; then
print_message "Checking StorageOption for MEMBERDB Cluster"

if [ -z "${STORAGE_OPTIONS_FOR_MEMBERDB}" ]; then
print_message "Storage Options is set to STORAGE_OPTIONS_FOR_MEMBERDB"
else
print_message "Storage Options is set to STORAGE_OPTIONS_FOR_MEMBERDB"
fi

fi
if [ -z "${ORACLE_SID}" ]; then
   print_message "ORACLE_SID is not defined"
else
  print_message "ORACLE_SID is set to $ORACLE_SID"
fi

}

################# Check db env vars end here ##################################

################ All Check Functions end here #####################################


########################################### SSH Function begin here ########################
setupSSH()
{
local password
local ssh_pid
local stat

IFS=', ' read -r -a CLUSTER_NODES  <<< "$EXISTING_CLS_NODES"
EXISTING_CLS_NODES+=",$PUBLIC_HOSTNAME"
CLUSTER_NODES=$(echo $EXISTING_CLS_NODES | tr ',' ' ')

print_message "Cluster Nodes are $CLUSTER_NODES"
print_message "Running SSH setup for $GRID_USER user between nodes ${CLUSTER_NODES}"
cmd='su - $GRID_USER -c "$EXPECT $SCRIPT_DIR/$SETUPSSH $GRID_USER \"$GRID_HOME/oui/prov/resources/scripts\"  \"${CLUSTER_NODES}\"  \"$GRID_PASSWORD\""'
(eval $cmd) &
ssh_pid=$!
wait $ssh_pid
stat=$?

if [ "${stat}" -ne 0 ]; then
error_exit "ssh setup for Grid user failed!, please make sure you have pass the corect password. You need to make sure that password must be same on all the clustered nodes or the nodes set in existing_cls_nodes env variable for $GRID_USER  user"
fi

print_message "Running SSH setup for $ORACLE_USER user between nodes ${CLUSTER_NODES[@]}"
cmd='su - $ORACLE_USER -c "$EXPECT $SCRIPT_DIR/$SETUPSSH $ORACLE_USER \"$DB_HOME/oui/prov/resources/scripts\"  \"${CLUSTER_NODES}\"  \"$ORACLE_PASSWORD\""'
(eval $cmd) &
ssh_pid=$!
wait $ssh_pid
stat=$?

if [ "${stat}" -ne 0 ]; then
error_exit "ssh setup for Oracle  user failed!, please make sure you have pass the corect password. You need to make sure that password must be same on all the clustered nodes or the nodes set in existing_cls_nodes env variable for $ORACLE_USER user"
fi
}

checkSSH ()
{

local password
local ssh_pid
local stat
local status

IFS=', ' read -r -a CLUSTER_NODES  <<< "$EXISTING_CLS_NODES"
EXISTING_CLS_NODES+=",$PUBLIC_HOSTNAME"
CLUSTER_NODES=$(echo $EXISTING_CLS_NODES | tr ',' ' ')

cmd='su - $GRID_USER -c "ssh -o BatchMode=yes -o ConnectTimeout=5 $GRID_USER@$node echo ok 2>&1"'
echo $cmd

for node in ${CLUSTER_NODES}
do

status=$(eval $cmd)

if [[ $status == ok ]] ; then
  print_message "SSH check fine for the $node"
  
elif [[ $status == "Permission denied"* ]] ; then
   error_exit "SSH check failed for the $GRID_USER@$node beuase of permission denied error! SSH setup did not complete sucessfully" 
else
   error_exit "SSH check failed for the $GRID_USER@$node! Error occurred during SSH setup"
fi

done

status="NA"
cmd='su - $ORACLE_USER -c "ssh -o BatchMode=yes -o ConnectTimeout=5 $ORACLE_USER@$node echo ok 2>&1"'
 echo $cmd
for node in ${CLUSTER_NODES}
do

status=$(eval $cmd)

if [[ $status == ok ]] ; then
  print_message "SSH check fine for the $ORACLE_USER@$node"
elif [[ $status == "Permission denied"* ]] ; then
   error_exit "SSH check failed for the $ORACLE_USER@$node becuase of permission denied error! SSH setup did not complete sucessfully"
else
   error_exit "SSH check failed for the $ORACLE_USER@$node! Error occurred during SSH setup"
fi

done

}

######################################  SSH Function End here ####################################

######################Add Node Functions ####################################
runorainstroot()
{
$INVENTORY/orainstRoot.sh
}

runrootsh ()
{
local ORACLE_HOME=$1
$ORACLE_HOME/root.sh
}

generate_response_file ()
{
cp $SCRIPT_DIR/$ADDNODE_RSP $logdir/$ADDNODE_RSP
chmod 666 $logdir/$ADDNODE_RSP

if [ -z "${GRID_RESPONSE_FILE}" ]; then
sed -i -e "s|###INVENTORY###|$INVENTORY|g" $logdir/$ADDNODE_RSP
sed -i -e "s|###GRID_BASE###|$GRID_BASE|g" $logdir/$ADDNODE_RSP
sed -i -r "s|###PUBLIC_HOSTNAME###|$PUBLIC_HOSTNAME|g"  $logdir/$ADDNODE_RSP
sed -i -r "s|###HOSTNAME_VIP###|$VIP_HOSTNAME|g"  $logdir/$ADDNODE_RSP
fi

}

###### Cluster Verification function #######
CheckRemoteCluster ()
{
local cmd;
local stat;
local node=$EXISTING_CLS_NODE
local oracle_home=$GRID_HOME
local ORACLE_HOME=$GRID_HOME

print_message "Checking Cluster"

cmd='su - $GRID_USER -c "ssh $node \"$ORACLE_HOME/bin/crsctl check crs\""'
eval $cmd

if [ $?  -eq 0 ];then
print_message "Cluster Check on remote node passed"
else
error_exit "Cluster Check on remote node failed"
fi

cmd='su - $GRID_USER -c "ssh $node \"$ORACLE_HOME/bin/crsctl check cluster\""'
eval $cmd

if [ $? -eq 0 ]; then
print_message "Cluster Check went fine"
else
error_exit "Cluster  Check failed!"
fi

cmd='su - $GRID_USER -c "ssh $node \"$ORACLE_HOME/bin/srvctl status mgmtdb\""'
eval $cmd

if [ $? -eq 0 ]; then
print_message "MGMTDB Check went fine"
else
error_exit "MGMTDB Check failed!"
fi

cmd='su - $GRID_USER -c "ssh $node \"$ORACLE_HOME/bin/crsctl check crsd\""'
eval $cmd

if [ $? -eq 0 ]; then
print_message "CRSD Check went fine"
else
error_exit "CRSD Check failed!"
fi


cmd='su - $GRID_USER -c "ssh $node \"$ORACLE_HOME/bin/crsctl check cssd\""'
eval $cmd

if [ $? -eq 0 ]; then
print_message "CSSD Check went fine"
else
error_exit "CSSD Check failed!"
fi

cmd='su - $GRID_USER -c "ssh $node \"$ORACLE_HOME/bin/crsctl check evmd\""'
eval $cmd

if [ $? -eq 0 ]; then
print_message "EVMD Check went fine"
else
error_exit "EVMD Check failed"
fi

}

checkCluster ()
{
local cmd;
local stat;
local oracle_home=$GRID_HOME

print_message "Checking Cluster"

cmd='su - $GRID_USER -c "$GRID_HOME/bin/crsctl check crs"'
eval $cmd

if [ $?  -eq 0 ];then
print_message "Cluster Check passed"
else
error_exit "Cluster Check failed"
fi

cmd='su - $GRID_USER -c "$GRID_HOME/bin/crsctl check cluster"'
eval $cmd

if [ $? -eq 0 ]; then
print_message "Cluster Check went fine"
else
error_exit "Cluster  Check failed!"
fi

cmd='su - $GRID_USER -c "$GRID_HOME/bin/srvctl status mgmtdb"'
eval $cmd

if [ $? -eq 0 ]; then
print_message "MGMTDB Check went fine"
else
error_exit "MGMTDB Check failed!"
fi

cmd='su - $GRID_USER -c "$GRID_HOME/bin/crsctl check crsd"'
eval $cmd

if [ $? -eq 0 ]; then
print_message "CRSD Check went fine"
else
error_exit "CRSD Check failed!"
fi

cmd='su - $GRID_USER -c "$GRID_HOME/bin/crsctl check cssd"'
eval $cmd

if [ $? -eq 0 ]; then
print_message "CSSD Check went fine"
else
error_exit "CSSD Check failed!"
fi

cmd='su - $GRID_USER -c "$GRID_HOME/bin/crsctl check evmd"'
eval $cmd

if [ $? -eq 0 ]; then
print_message "EVMD Check went fine"
else
error_exit "EVMD Check failed"
fi

print_message "Removing $logdir/cluvfy_check.txt as cluster check has passed"
rm -f $logdir/cluvfy_check.txt

}

checkClusterClass ()
{
print_message "Checking Cluster Class"
local cluster_class

cmd='su - $GRID_USER -c "$GRID_HOME/bin/crsctl get cluster class"'
cluster_class=$(eval $cmd)
print_message "Cluster class is $cluster_class"
CLUSTER_TYPE=$(echo $cluster_class | awk -F \' '{ print $2 }' | awk '{ print $1 }')
}


###### Grid install & Cluster Verification utility Function #######
cluvfyCheck()
{

local node=$EXISTING_CLS_NODE
local responsefile=$logdir/$ADDNODE_RSP
local hostname=$PUBLIC_HOSTNAME
local vip_hostname=$VIP_HOSTNAME
local cmd
local stat

if [ -f "$logdir/cluvfy_check.txt" ]; then
print_message "Moving any exisiting cluvfy $logdir/cluvfy_check.txt to $logdir/cluvfy_check_$TIMESTAMP.txt"
mv $logdir/cluvfy_check.txt $logdir/cluvfy_check."$(date +%Y%m%d-%H%M%S)".txt
fi

cmd='su - $GRID_USER -c "ssh $node  \"$GRID_HOME/runcluvfy.sh stage -pre nodeadd -n $hostname -vip $vip_hostname\" | tee -a $logdir/cluvfy_check.txt"'
eval $cmd

print_message "Checking $logdir/cluvfy_check.txt if there is any failed check."
FAILED_CMDS=$(sed -n -f - $logdir/cluvfy_check.txt << EOF
 /.*FAILED.*/ {
   /.*DNS\/NIS.*/{
   d\
}
  /.*SCAN.*/{
    d\
}
   /.*resolv.conf.*/{
   d\
}
   /Network Time Protocol/{
   d\
}
  /.*ntpd.*/{
   d\
}
p
}
EOF
)
cat $logdir/cluvfy_check.txt > $STD_OUT_FILE

if [[ $FAILED_CMDS =~ .*FAILED*. ]]
then
print_message "cluvfy failed for following  \n $FAILED_CMDS"
error_exit "Pre Checks failed for Grid installation, please check $logdir/cluvfy_check.txt"
fi

print_message "Checks related to /etc/resov.conf, DNS and ntp.conf checks will be ignored. However, it is recommended to use DNS server for RAC"
}

addGridNode ()
{

local node=$EXISTING_CLS_NODE
local responsefile=$logdir/$ADDNODE_RSP
local hostname=$PUBLIC_HOSTNAME
local vip_hostname=$VIP_HOSTNAME
local cmd
local stat

print_message "Copying $responsefile on remote node $node"
cmd='su - $GRID_USER -c "scp $responsefile $node:$logdir"'
eval $cmd

print_message "Running GridSetup.sh on $node to add the node to existing cluster"
cmd='su - $GRID_USER -c "ssh $node  \"$GRID_HOME/gridSetup.sh -silent -waitForCompletion -noCopy -skipPrereqs -responseFile $responsefile\" | tee -a $logfile"'
eval $cmd

print_message "Node Addition performed. removing Responsefile"
rm -f $responsefile
cmd='su - $GRID_USER -c "ssh $node \"rm -f $responsefile\""'
eval $cmd

}

###########DB Node Addition Functions##############
addDBNode ()
{
local node=$EXISTING_CLS_NODE
local new_node_hostname=$PUBLIC_HOSTNAME
local stat=3
local cmd

cmd='su - $ORACLE_USER -c "ssh $node \"$DB_HOME/addnode/addnode.sh \"CLUSTER_NEW_NODES={$new_node_hostname}\" -skipPrereqs -waitForCompletion -ignoreSysPrereqs -noCopy  -silent\" | tee -a $logfile"'
eval $cmd

if [ $? -eq 0 ]; then
print_message "Node Addition went fine for $new_node_hostname"
else
error_exit "Node Addition failed for $new_node_hostname"
fi
}

addDBInst ()
{
# Check whether ORACLE_SID is passed on
local HOSTNAME=$PUBLIC_HOSTNAME
local node=$EXISTING_CLS_NODE
local stat=3
local cmd

if [ -z "${ORACLE_SID}" ];then
 error_exit "ORACLE SID is not defined. Cannot Add Instance"
fi

if [ -z "${HOSTNAME}" ]; then
error_exit "Hostname is not defined"
fi

cmd='su - $ORACLE_USER -c "ssh $node \"$DB_HOME/bin/dbca -addInstance -silent  -nodeName  $HOSTNAME -gdbName $ORACLE_SID\" | tee -a $logfile"'
eval $cmd
}

checkDBStatus ()
{
local status

if [ -f "/tmp/db_status.txt" ]; then
status=$(cat /tmp/db_status.txt)
else
status="NOT OPEN"
fi

rm -f /tmp/db_status.txt

# SQL Plus execution was successful and database is open
if [ "$status" = "OPEN" ]; then
   print_message "#################################################################"
   print_message " Oracle Database $ORACLE_SID is up and running on $(hostname)    "
   print_message "#################################################################"
# Database is not open
else
   error_exit "$ORACLE_SID is not up and running on $(hostname)"
fi

}


setremotelistener ()
{
local status
local cmd

if resolveip $CMAN_HOSTNAME; then
print_message "Executing script to set the remote listener"
su - $ORACLE_USER -c "$SCRIPT_DIR/$REMOTE_LISTENER_FILE $ORACLE_SID $SCAN_NAME $CMAN_HOSTNAME.$DOMAIN"
fi

}

########################## DB Functions End here ##########################

###################################
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! #
############# MAIN ################
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! #
###################################


###### Etc Host and other Checks and setup before proceeding installation #####
all_check
print_message "Setting random password for root/$GRID_USER/$ORACLE_USER user"
print_message "Setting random password for $GRID_USER user"
setpasswd $GRID_USER  $GRID_PASSWORD
print_message "Setting random password for $ORACLE_USER user"
setpasswd $ORACLE_USER $ORACLE_PASSWORD
print_message "Setting random password for root user"
setpasswd root $PASSWORD

####  Setting up SSH #######
setupSSH
checkSSH

#### Grid Node Addition #####
print_message "Checking Cluster Status on $EXISTING_CLS_NODE"
CheckRemoteCluster
print_message "Generating Responsefile for node addition"
generate_response_file
print_message "Running Cluster verification utility for new node $PUBLIC_HOSTNAME on $EXISTING_CLS_NODE"
cluvfyCheck
print_message "Running Node Addition and cluvfy test for node $PUBLIC_HOSTNAME"
addGridNode
print_message "Running root.sh on node $PUBLIC_HOSTNAME"
runrootsh $GRID_HOME 
checkCluster
print_message "Checking Cluster Class"
checkClusterClass

###### DB Node Addition ######
if [ "${CLUSTER_TYPE}" != 'Domain' ]; then
print_message  "Performing DB Node addition"
addDBNode
print_message "Running root.sh"
runrootsh $DB_HOME
print_message "Adding DB Instance"
addDBInst 
print_message "Checking DB status"
su - $ORACLE_USER -c "$SCRIPT_DIR/$CHECK_DB_FILE $ORACLE_SID"
checkDBStatus
print_message "Running User Script"
su - $ORACLE_USER -c "$SCRIPT_DIR/$USER_SCRIPTS_FILE $SCRIPT_ROOT"
print_message "Setting Remote Listener"
setremotelistener
fi
echo $TRUE
