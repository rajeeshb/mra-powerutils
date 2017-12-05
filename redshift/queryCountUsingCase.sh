#!/usr/local/bin/bash

#set -x
MAP=./.clusterinfo 
if ! [ -f "$MAP" ]; then
      echo "Cluster Map not found." 
      exit 1
fi


while IFS='' read -r cluster; do
#Function runQuery
runQuery()
{
  getCount=$(PGPASSWORD=ABC123#456 psql -h myapp-"${cluster}".foobar.com -U ops_readonly -d dev -p 5439 -t -c "select count(*) from pg_database;")
  case "${cluster}" in
  us-east-1-1)
      echo "${cluster}:${getCount} * ";;
  us-east-1-3)
      echo "${cluster}:${getCount} * ";;
  us-east-1-15)
      echo "${cluster}:${getCount} * ";;
  us-east-1-17)
      echo "${cluster}:${getCount} * ";;
  us-east-1-20)
      echo "${cluster}:${getCount} * ";;
  eu-central-1-1)
      echo "${cluster}:${getCount} * ";;
  ap-northeast-1-1)
      echo "${cluster}:${getCount} * ";;
  ap-southeast-2-1)
      echo "${cluster}:${getCount} * ";;
  *)
      echo "${cluster}:${getCount}"
  esac    
}
#Execute
runQuery

done < "$MAP"

#set +x
