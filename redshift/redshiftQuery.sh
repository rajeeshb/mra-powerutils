#!/usr/local/bin/bash

KEY=./.keyinfo3 #Where .keyinfo3 => user#pw
if ! [ -f "$KEY" ]; then
      echo "Key credentials not found." 
      exit 1
fi

IFS='#' read -r user pw < "$KEY"

# Cluster key alias to endpoints
# Declare this array in the beginning
declare -A cluster_to_endpoint=(
        [us-east-3]=mydomain-us-east-1-3.crapola.com
        [eu-west-1]=mydomain-eu-west-1-1.crapola.com
        [eu-central-1]=mydomain-eu-central-1-1.crapola.com
        [ap-northeast-1]=mydomain-ap-northeast-1-1.crapola.com
        [ap-southeast-1]=mydomain-ap-southeast-2-1.crapola.com
)


# Usage for getopts
usage () {
    echo "Usage: $0 -k <key> -q query.sql "
    echo "Example: $0 -k us-east-1 -q getDBName.sql"
    echo "Cluster Key:"
    for i in "${!cluster_to_endpoint[@]}"
    do
      echo "$i:${cluster_to_endpoint[$i]}"
    done | sort
}

while getopts ":k:q:" opt; do
  case $opt in
    k) key="$OPTARG";;
    q) sql="$OPTARG";;
    *) usage
       exit 1
       ;;
  esac
done

#Function runQuery
runQuery()
{
  PGPASSWORD=${pw} psql -h ${cluster_to_endpoint[$key]} -U ${user} -d dev -p 5439 -f ${sql}
}

#Execute
runQuery
