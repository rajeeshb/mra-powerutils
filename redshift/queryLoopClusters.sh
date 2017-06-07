#!/usr/local/bin/bash

set -x

#Usage:  ./script.sh myquery.sql

#Setup pw keys for cluster to cluster
KEY=./.keyinfo
if ! [ -f "$KEY" ]; then
      echo "Key credentials not found." 
      exit 1
fi

# Import your sql script
sql=$1

#Keys are separated by pound "#" 
while IFS=# read -r region clnmbr pw; do

#Function
runQuery()
{
 mycmd=$(PGPASSWORD=${pw} psql -h myapp-${region}-1-${clnmbr}.mydomain.com -U masteruser -d dev -p 5439 -f ${sql})
}

#Execute function
runQuery

done < "$KEY"

set +x
