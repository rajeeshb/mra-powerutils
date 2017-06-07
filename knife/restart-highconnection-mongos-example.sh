#!/bin/bash

#set -x
if [[ $# != 1 ]]; then
     echo "Usage: ./script.sh <count|restart>"
     echo "Example: ./script.sh count"
     echo "Example: ./script.sh restart"
     exit 1
fi

getCount() {
     knife ssh -x mydevuser -a ec2.local_ipv4 "chef_environment:development AND roles:mongodb_cluster AND recipes:mongodb\:\:mongos AND ipaddress:10.2.*" 'netstat -na | grep EST | wc -l' | dos2unix| awk '$2 > 30000 {print $2}'
}

getIP() {
    knife ssh -x mydevuser -a ec2.local_ipv4 "chef_environment:development AND roles:mongodb_cluster AND recipes:mongodb\:\:mongos AND ipaddress:10.2.*" 'netstat -na | grep EST | wc -l' | dos2unix| awk '$2 > 30000 {print $1}'
}

if [[ "$1" = "count" ]]; then
     for OUTPUT in $(getCount)
     do
    	echo "DB connection count is high: $OUTPUT"
     done
     exit 0
elif [[ "$1" = "restart" ]]; then
     for OUTPUT in $(getIP)
     do
        echo "Restarting $OUTPUT"
        #ssh -q $OUTPUT sudo stop mongos; ssh -q $OUTPUT sudo start mongos; ssh -q $OUTPUT date; sleep 15
        ssh -q $OUTPUT sudo initctl list | grep mongos; ssh -q $OUTPUT date; sleep 15
     done
     exit 0
else
     echo "There is nothing to restart"
     exit 1
fi

#set +x
