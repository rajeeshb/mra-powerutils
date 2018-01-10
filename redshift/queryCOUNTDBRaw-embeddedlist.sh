#!/usr/local/bin/bash

#set -x

#List of Clusters
LIST=( 
"us-east-1-1"
"us-east-1-2"
"us-east-1-3"
"eu-west-1-12"
"eu-west-1-1"
"eu-central-1-1"
"ap-northeast-1-1"
"ap-southeast-2-1"
)

echo "* designates a SHARED cluster"
for cluster in ${LIST[@]}
do
   runQuery() {
      getCount=$(PGPASSWORD=Y0urPa55word psql -h myapplication-"${cluster}".mydomain.com -U ops_readonly -d dev -p 5439 -t -c "select count(*) from pg_database;")
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
           us-east-1-23)
      		echo "${cluster}:${getCount} * - DEFAULT for us-east";;
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
runQuery
done  

#set +x
