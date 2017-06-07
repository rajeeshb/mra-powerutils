#!/bin/bash
if [ $# != 1 ]; then
    echo "Usage: getcnf.sh <remote-host>" 2>&1
    exit 1
fi

#Declare variables
HOURDATE=`date '+%Y%m%d%H%M'`
STAMP=`date '+%Y%m%d-%H:%M'`
REMOTE_MYCNF=/home/y/etc/my.cnf
BACKUP_DIR=/home/mysql/postbackup_procs/postbackup_files/
export REMOTE_MYCNF HOURDATE STAMP

#Copy file over
echo "Checking for original mysql file $REMOTE_MYCNF $STAMP" 2>&1
if [ -f $REMOTE_MYCNF ]; then 
if [ ! -f $REMOTE_MYCNF ]; then #Issues where the above statment won't do a file check. 
							    #Also works with using [! -f]
   echo "File exists lets bring a copy over...." 2>&1
   /usr/local/bin/scp $1:$REMOTE_MYCNF $BACKUP_DIR$1.$HOURDATE.cnf
   #/bin/chmod 755 $BACKUP_DIR$1.$HOURDATE.cnf
   echo "END POSTBACKUP" 2>&1
   exit 0
   else	
	echo "Unable to get file" 2>&1
        exit 0
fi
