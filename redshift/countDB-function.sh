#!/usr/local/bin/bash

set -x

#Setup pw keys for cluster to cluster
KEY=./.keyinfo
if ! [ -f "$KEY" ]; then
      echo "Key credentials not found." 
      exit 1
fi

#While reading each line in the keys list, get the count and check its threshold
#Keys are separated by pound "#" 
while IFS=# read -r region clnmbr pw; do
#echo ${region}:${clnmbr}:${pw}

#Set Threshold
threshold=$1

#Function
getCount()
{
 mycount=$(PGPASSWORD=${pw} psql -h hostname-${region}-1-${clnmbr}.mydomain.com -U masteruser -d dev -p 5439 -t -c "select count(datname) from pg_database;")
}

getCount

echo ${region}:${clnmbr}:${mycount}

#Send an alert if greater than threshold
if [[ "${mycount}" -gt ${threshold} ]]; then
	echo "Database count is high: ${mycount}";
	echo "Sending an alert..."
   else
	echo "Count is ok"
fi

done < "$KEY"

set +x
