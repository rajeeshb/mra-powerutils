#!/usr/local/bin/bash

set -e

#VARS
export _clpw1=MyPa55w0rd1          
export _file=/tmp/accountprofiles.out
export _file2=/tmp/cleanout.out

#FUNCTIONS
#Querying Mongodb with inputs from postgres query
getDataCloudProfile ()
{
   _host='10.1.2.456'
   _db='core'
   _version="true"
   _mongo=$(which mongo);
   exp="db.getCollection(\"mycloud_profiles\").find({account : \"${account}\", profile :\"${profile}\", \"version_info.published\":true}, {account:1, profile:1, \"settings.region\":1});";
   ${_mongo} ${_host}/${_db} --eval "$exp" 
}

#Querying postgress
runMain() {
    PGPASSWORD="${_clpw1}" \
    psql -h myendpoint-1-1.rds.amazonaws.com -U master -d myapplication_api -p 5432 -t -c \
    "select distinct(account,profile) from transactions where TYPE = 'DELETE' and myapplication_purge_ids is not null and status = 'PENDING';"\
    | sed 's/[()]//g'\
    | sed 's/ //g' \
    | sed '$d'>> "${_file}"

    #Use output to run in Mongo
    while IFS=',' read -r account profile
        do
           getDataCloudProfile >> /tmp/cleanout.out
    done < "${_file}" 


    #Cleanup file for more readable output 
    sort /tmp/cleanout.out \
    | grep "_id" \
    | sed 's/ //g' \
    | cut -b 1,45- \
    | jq -s -c 'sort_by(.settings) |.[]'
    rm "${_file}"
}

#MAIN
runMain
rm /tmp/cleanout.out
