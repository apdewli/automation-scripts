# automation-scripts
This repository is for various scripts which I use in different environments. These scripts can be used by anyone with some customisations.  

**db-rollbac-bkup1.ps1** script is a powershell script to take the back of servers hosted on EC2 and then create new servers from previously backed up images (AMI) in AWS .

**rds-backup.sh** is a bash script to take the backup of RDS overnight and then terminate the instance. and the **rds-restore.sh** script restores the same rds instance from the last backup/snapshot. 
