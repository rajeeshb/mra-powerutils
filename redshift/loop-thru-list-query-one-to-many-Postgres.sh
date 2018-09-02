#!/usr/local/bin/bash

#
# Script: getDBandSchemas.sh
# FUNCTION:
# For each cluster name that is used as input, get the database name and schemas.
# For our purposes database name = "account" and schemas="profiles". This is a one-to-many relationship. 
#

#set -e
#set -x

# COLORIZE OUTPUT
# Use with echo -e: "-e" escapes the backlash
RED="\033[0;31m"
YELLOW="\033[0;33m"
GREEN="\033[0;32m"
BLUE="\033[0;34m"
NC="\033[0m"


#A list of all the current clusters in prod
declare -A cluster_to_endpoint=(
        [use01]=myapplication-us-east-1-1.foobar.com
        [euc01]=myapplication-eu-central-1-1.foobar.com
        [euw01]=myapplication-eu-west-1-1.foobar.com
        [apne01]=myapplication-ap-northeast-1-1.foobar.com
        [apse01]=myapplication-ap-southeast-2-1.foobar.com
)

#VARS
export _data_bags=/path_to_your_databags_file
export _script=/tmp/report.out
export _file=/tmp/dbnames.out
export _clean=/tmp/clean.out


# Usage for getopts
usage () {
    echo -e "${BLUE}Usage:${GREEN}$0 -c <cluster>"
    echo -e "${BLUE}Example:${GREEN}$0 -c use01"
    echo -e "${BLUE}ClusterMap:"
        for i in "${!cluster_to_endpoint[@]}"
    do
      echo -e "${BLUE}$i:${GREEN}${cluster_to_endpoint[$i]}"
    done | sort
}

while getopts ":c:" opt; do
  case $opt in
    c) cluster="$OPTARG";;
    *) usage
       exit 1
       ;;
  esac
done


#FUNCTIONS
getPW(){
  grep -E 'url.*'${cluster_to_endpoint[$cluster]}'' -A4 ${_data_bags}/production.json \
  | grep "pwd" \
  | awk -F'"' '$0=$4'
}

runMain() {
    echo  "REDSHIFT CLUSTER: ${cluster_to_endpoint[$cluster]}" >> "${_script}"
    PGPASSWORD="${_pgpw}" psql -h "${cluster_to_endpoint[$cluster]}" -U masteruser -d dev -p 5439 -t -c "select datname from pg_database where datname not like 'template%' and datname not like 'dev%' and datname not like 'padb%';" >> "${_file}"

    #Cleans up leading white space and trailing empty line to a clean file
    /usr/bin/awk 'NF { $1=$1; print }' "${_file}" > "${_clean}"
        
    while IFS='' read -r dbname
        do
           echo "ACCOUNT:${dbname}" >> "${_script}"
           PGPASSWORD="${_pgpw}" psql -h "${cluster_to_endpoint[$cluster]}" -U masteruser -d "${dbname}" -p 5439 -t -c "select distinct '    PROFILE:' || table_schema FROM information_schema.tables where table_catalog='${dbname}' and table_schema not in ('pg_catalog','information_schema');" >> "${_script}"
           #Tidy up output file, removing empty lines 
           # -i '.bak' is macosx specific where the file extension is needed to create a backup file
           sed -i '.bak' '/^$/d' "${_script}"
        done < "${_clean}"

    #Cleanup temp files
    rm "${_file}" "${_clean}" "${_script}.bak"
}

#Execute
_pgpw=$(getPW)
runMain

#set +x
