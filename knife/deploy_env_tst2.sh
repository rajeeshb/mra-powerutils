#!/bin/bash

#set -x
if [[ $# != 1 ]]; then
     echo "Usage: ./script.sh <count|ip>"
     echo "Example: ./script.sh count"
     echo "Example: ./script.sh ip   "
     exit 1
fi

getCount() {
     knife ssh -x mydevuser -a ec2.local_ipv4 "chef_environment:development AND roles:mongodb_cluster AND recipes:mongodb\:\:mongos AND ipaddress:10.4.*" 'netstat -na | grep EST | wc -l' | dos2unix| awk '$2 > 2000 {print $2}'
}

getIP() {
    knife ssh -x mydevuser -a ec2.local_ipv4 "chef_environment:development AND roles:mongodb_cluster AND recipes:mongodb\:\:mongos AND ipaddress:10.4.*" 'netstat -na | grep EST | wc -l' | dos2unix| awk '$2 > 2000 {print $1}'
}

if [[ "$1" = "count" ]]; then
     for OUTPUT in $(getCount)
     do
    	echo "DB connection count is high: $OUTPUT"
     done
     exit 0
elif [[ "$1" = "ip" ]]; then
     for OUTPUT in $(getIP)
     do
        echo "IP number is: $OUTPUT"
     done
     exit 0
else
     echo "No info."
     exit 1
fi

#set +x
