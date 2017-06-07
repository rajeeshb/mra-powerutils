#!/usr/local/bin/bash

#set -x

#Setup pw keys for cluster to cluster
KEY=./.keyinfo
if ! [ -f "$KEY" ]; then
      echo "Key credentials not found." 
      exit 1
fi


# Usage for getopts
usage () {
    echo "Usage: $0 -q query.sql "
    echo "Example: $0 -q getDBName.sql"
}

while getopts ":q:" opt; do
  case $opt in
    q) sql="$OPTARG";;
    *) usage
       exit 1
       ;;
  esac
done

#Keys are separated by pound "#" 
while IFS=# read -r region clnmbr pw; do

#Function
runQuery()
{
 mycount=$(PGPASSWORD=${pw} psql -h myapp-${region}-1-${clnmbr}.mydomain.com -U masteruser -d dev -p 5439 -f ${sql})
}

#Execute function
runQuery

done < "$KEY"

#set +x
