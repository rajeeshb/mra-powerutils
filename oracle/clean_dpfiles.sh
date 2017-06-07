#!/usr/local/bin/bash

if [ $# != 3 ]; then
    echo "Usage: clean_dpfiles.sh <directory> <log|dmp|par> <numberofdays>" 2>&1
    exit 1
fi

#Declare variables
HOURDATE=`date '+%Y%m%d%H%M'`
CLEANDIR=$1
export CLEANDIR HOURDATE

echo "Listing files to remove..." 2>&1
/usr/bin/find $CLEANDIR -name "*.$2" -mtime +$3 -exec ls -ltr '{}' \;

echo "Removing files ---> $HOURDATE" 2>&1
/usr/bin/find $CLEANDIR -mtime +$3 -exec rm '{}' \;
