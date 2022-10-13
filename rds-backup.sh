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
