#!/usr/local/bin/bash
# ****************************************************************************
# Setup Oracle Environment
# ****************************************************************************

#
# Setup environment variables
#
O_VER=11.1.0.6.0
export ORACLE_BASE=/home/oracle
export ORACLE_HOME=/home/oracle/product/11.1.0.6.0
export CRS_HOME=/home/oracle/product/crs
export ASM_HOME=/home/oracle/product/asm
export ORACLE_PATH=$ORACLE_BASE/common/oracle/sql:.:$ORACLE_HOME/rdbms/admin

# Each RAC node must have a unique ORACLE_SID. (i.e. orcl1, orcl2,...)
export ORACLE_SID=asprod1
export PATH=.:${JAVA_HOME}/bin:${PATH}:$HOME/bin:$ORACLE_HOME/bin
export PATH=${PATH}:/usr/bin:/bin:/usr/bin/X11:/usr/local/bin
export PATH=${PATH}:$ORACLE_BASE/common/oracle/bin
export TNS_ADMIN=$ORACLE_HOME/network/admin
export ORA_NLS10=$ORACLE_HOME/nls/data
export LD_LIBRARY_PATH=$ORACLE_HOME/lib
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:$ORACLE_HOME/oracm/lib
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/lib:/usr/lib:/usr/local/lib

# Other variables 
BCKLOG=/tmp/bckuplog
export BCKLOG

STATUS_FILE=/tmp/db_backup_in_progress
export STATUS_FILE

KEYFILE=/home/oracle/.ssh/id_rsa
export KEYFILE

export MAIL_LIST='madajar@mydomain-inc.com'

#
# Setup Error handling
#

trap 'del_backup_status_file 1' ERR

del_backup_status_file()
{
  # Deletes the status file indicating a cold backup is in progress
  ssh  -i $KEYFILE oracle@asetl01.mail.sk1.mydomain.com "rm -f $STATUS_FILE"
  # Check to see if an error condition was raised
  if [ $1 -ne 0 ]; then
     #mailx antispam-backup-ops@mydomain-inc.com -s "ERROR Performing Cold Backup Of ASPROD" << EOF
     mailx -s "ERROR Performing Cold Backup Of ASPROD" $MAIL_LIST
EOF 
  fi
}

create_backup_status_file()
{
  ssh  -i $KEYFILE oracle@asetl01.mail.sk1.mydomain.com "touch $STATUS_FILE"
}

# First things first...create the status file on the ETL server so no etl is performed while a backup is occurring.
create_backup_status_file

#Use srvctl to stop the datbase
echo "Using srvctl to check test msg status of the database..." >> $BCKLOG 2>&1
srvctl status database -d asprod

date >> $BCKLOG 2>&1
#Log into RMAN utility
echo "Logging into RMAN utility to startup and mount db..." >> $BCKLOG 2>&1
rman target / catalog asrman/asrman@rman << eof >> $BCKLOG
 run {
 allocate channel c1 device type sbt;
 allocate channel c2 device type sbt;
 backup tablespace rmantest;
 release channel c1;
 release channel c2;
 }
eof
date >> $BCKLOG 2>&1

#Use srvctl to stop the datbase
echo "Using srvctl to check test msg status of the database..." >> $BCKLOG 2>&1
srvctl status database -d asprod

date >> $BCKLOG 2>&1

# Deletes the backup status file so loading can continue
del_backup_status_file 0

exit
