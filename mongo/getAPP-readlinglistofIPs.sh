#!/usr/local/bin/bash
set -e
set -x

#Text file holds a list of IPs
#Use while loop to iterate through each line
IPs="iplist.txt"
while IFS= read -r line
do 
    echo "$line"
    _IP="$line"

#############
# Functions
#############
getPartition ()
{
   local host='12.1.2.130'
   local db='myapplication_foobar_state'
   _mongo=$(which mongo);
   local exp="db.myapplicationfoobar_servers.find(
   {\"node_host\":${_IP},\"node_type\":\"YOUR_APPNAME\",\"region\":\"us-east-1\",\"status\":\"ACTIVE\"},{\"partition_range_start\":1,\"partition_range_end\":1, _id:0}).pretty();"; 
   ${_mongo} ${host}/${db} --eval "$exp" | grep -o -e "{[^}]*}"
}

getPartition

# End of while looping through versions
done <"$IPs"

set +x
