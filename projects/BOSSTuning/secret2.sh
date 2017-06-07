#!/usr/bin/ksh
#Base dir
BASEDIR=/home/oracle/scripts/mra_dba/tuning
export BASEDIR;

#Key
KEY=$BASEDIR/.keyinfo
export KEY;

IFS="
"
arr=( $(<$KEY) )
#set -A arr $(cat $KEY) 
echo "username=${arr[0]}   password=${arr[1]}" 
