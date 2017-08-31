#!/usr/local/bin/bash

#Where .keyinfo2:
#us-east#1-3#myPa55word2
KEY=./.keyinfo2
if ! [ -f "$KEY" ]; then
      echo "Key credentials not found." 
      exit 1
fi


# Usage for getopts
usage () {
    echo "Usage: $0 -c <region> -q query.sql "
    echo "Example: $0 -c us-east-1 -q getDBName.sql"
}

while getopts ":c:q:" opt; do
  case $opt in
    c) cluster="$OPTARG";;
    q) sql="$OPTARG";;
    *) usage
       exit 1
       ;;
  esac
done

#Function runQuery
runQuery()
{
  PGPASSWORD=${pw} psql -h mydomain-${region}-${clnmbr}.crapola.com -U masteruser -d dev -p 5439 -f ${sql}
}

while IFS=# read -r region clnmbr pw; do
if [[ "$region-$clnmbr" == $cluster ]]; then
       echo "We have a match"
       echo "Password is $pw"
       runQuery
       exit 0
    else
       echo "No match"
fi
done < "$KEY"
