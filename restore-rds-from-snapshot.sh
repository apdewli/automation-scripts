#!/bin/bash
DATE=`date -u +%Y%m%d`
SNAPID="xxxxxxxxxxxxxxx"
DBID="xxxxxxxxxxxxxxxxx"

#config groups
SECURITYGROUP="RDS-TESTING-SNAPSHOT-SG"
PARAMSGROUP="rds-snpshot-test-pg-56"
SUBNETGROUP="rds-subnet-group"

#AWS Command
CMD="aws --profile xxxxxxxxxxxx";

#rds verifying commands
SNAPSHOT_AVAILABILITY="rds-describe-db-snapshots | grep -i $SNAPID | grep available | wc -l"



wait_until()
{
result=`eval  $* | sed 's/ //g'`
if [[ $result == 0 ]]
then
    sleep 60
    wait_until $*
fi
}

wait_until $SNAPSHOT_AVAILABILITY
$CMD rds create-db-snapshot  $DBID --db-snapshot-identifier $SNAPID
rds-delete-db-instance  $DBID  --skip-final-snapshot -f

#==========================================================================

#!/bin/bash
DATE=`date -u --date=yesterday +%Y%m%d`
SNAPID="xxxxxxxxxxxxxx"
DBID="xxxxxxxxxx"

#config groups
SECURITYGROUP="RDS-TESTING-SNAPSHOT-SG"
PARAMSGROUP="rds-snpshot-test-pg-56"
SUBNETGROUP="rds-subnet-group"

#rds verifying commands
	
SEC_CHANGES="rds-describe-db-instances ${DBID} | grep SECGROUP | grep -i $SECURITYGROUP | grep active |wc -l"
PARAM_CHANGES="rds-describe-db-instances ${DBID} | grep PARAMGRP | grep -i $PARAMSGROUP | grep pending-reboot |wc -l"

wait_until()
{
result=`eval  $* | sed 's/ //g'`
if [[ $result == 0 ]]
then
    sleep 60
    wait_until $*
fi
}

rds-restore-db-instance-from-db-snapshot  $DBID  --db-snapshot-identifier $SNAPID --availability-zone  us-east-1a --db-instance-class  db.m1.small
wait_until $INSTANCE_AVAILABILITY
rds-modify-db-instance  ${DBID}  --db-parameter-group-name ${PARAMSGROUP} --db-security-groups ${SECURITYGROUP}
wait_until $SEC_CHANGES
wait_until $PARAM_CHANGES
rds-reboot-db-instance $DBID
wait_until $INSTANCE_AVAILABILITY
rds-delete-db-snapshot  $SNAPID  -f

exit 0
exit 0
