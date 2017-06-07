#!/bin/bash
if [ $# != 1 ]; then
	    echo "Usage: getzrmlogs.sh <remote-host>" >&2
	        exit 1
	fi

	#Declare variables
	STAMP=`date '+%Y%m%d-%H:%M'`
	REMOTE_MYCNF=/var/log/mysql-zrm/mysql-zrm.log
	REMOTE_GZ=/var/log/mysql-zrm/mysql-zrm.log.1.gz
	REMOTE_DIR=/var/log/mysql-zrm/
	BACKUP_DIR=/home/mysql/dev/logs/
	NEWLOG="zrm-temp.log"

	#Copy file over
	echo "STARTING $STAMP..." >&2
	echo "Local log file $BACKUP_DIR$1.mysql-zrm.log exists, clean up for new copy..." >&2
	/bin/rm $BACKUP_DIR$1.mysql-zrm.log
	echo "Creating new logfile and copy here...." >&2
	ssh $1 "zcat $REMOTE_GZ >> $REMOTE_DIR$NEWLOG"
	sleep 10
	ssh $1 "cat $REMOTE_MYCNF >> $REMOTE_DIR$NEWLOG"
	/usr/bin/scp $1:$REMOTE_DIR$NEWLOG $BACKUP_DIR$1.mysql-zrm.log
	echo "end remote copy" >&2
	echo "Cleaning up remote files" >&2
	ssh $1 "rm $REMOTE_DIR$NEWLOG"
