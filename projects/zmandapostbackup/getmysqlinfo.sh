#!/bin/bash

if [ $# != 5 ]; then
    echo "Usage: getmysqlinfo.sh <user> <pw> <database> <remote-host> <mycnf.out> " 2>&1
    exit 1
fi

#Declare variables
HOURDATE=`date '+%Y%m%d%H%M'`
STAMP=`date '+%Y%m%d-%H:%M'`
MYSQL_BIN=/home/y/bin64
OUTDIR=/home/mysql/postbackup_procs/postbackup_files/
export MYSQL_BIN OUTDIR HOURDATE STAMP

echo "STARTING POSTBACKUP" 2>&1
echo "$STAMP" 2>&1
echo "Mysql remote connection to $4" 2>&1
echo "Grabbing variable information...." 2>&1
$MYSQL_BIN/mysql -u $1 -p$2 --database $3 -h $4 --port 3306 -e "show variables;" > $OUTDIR$4.$HOURDATE.$5
#/home/y/bin64/mysql -u backup-dba -pyah00email --database mysql -h rpudb01.mail.sp2.com --port 3306 -e "show variables;"
