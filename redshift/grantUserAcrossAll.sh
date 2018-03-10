#!/usr/local/bin/bash

#
# Script: grantUserAccessAcrossALL.sh
# FUNCTION: 
# Grants readonly access for all dbs and account to our foo_readonly for purpose of monitoring/reporting.
#
# runMain:  Main logic handler that collects all needed db info, cleans up the list and executes the grants across
#           clusters included in the list array
#
# Requirements: PWs for masteruser, foo_readonly (see your admin)
#

set -e
set -x

#Declare your list of clusters and masteruser pw. Clear out this list when complete.
#You can have one or may clusters listed. Remove from list when complete.
declare -A LIST=( 
   [clusterkey]=MyPa55w0rdHere    #EXAMPLE ONLY
)

#VARS
export _clpw1=MyPa55w0rdHere           #Pw for foo_readonly
export _script=/tmp/runGrant.sql
export _file=/tmp/dbnames.out
export _clean=/tmp/clean.out

#FUNCTIONS
runMain() {
    #Login as foo_readonly to create the list of database names
    PGPASSWORD="${_clpw1}" psql -h myproduct-${cluster}.myapplication.com -U foo_readonly -d dev -p 5439 -t -c "select datname from pg_database where datname not like 'template%' and datname not like 'dev%' and datname not like 'padb%';" >> "${_file}"
    
    #Cleans up leading white space and trailing empty line to a clean file
    /usr/bin/awk 'NF { $1=$1; print }' "${_file}" > "${_clean}"
        
    while IFS='' read -r dbname
        do
           #Uses the LIST array to map the correct pw to login as masteruser
           #Use only a single ">" append to the file so it only executes those specific grants for that database
           PGPASSWORD="${LIST[$cluster]}" psql -h myproduct-${cluster}.myapplication.com -U masteruser -d "${dbname}" -p 5439 -t -c "select distinct 'GRANT SELECT ON ALL TABLES IN SCHEMA ' || table_schema ||' TO foo_readonly;' FROM information_schema.tables where table_catalog='${dbname}' and table_schema not in ('pg_catalog','information_schema');" > "${_script}"
           #Tidy up output file, removing empty lines 
           # -i '.bak' is macosx specific where the file extension is needed to create a backup file
           sed -i '.bak' '/^$/d' "${_script}"
           #Now execute the final sql statement against the current db
           PGPASSWORD="${LIST[$cluster]}" psql -h myproduct-${cluster}.myapplication.com -U masteruser -d "${dbname}" -p 5439 -f "${_script}"
        done < "${_clean}"

    #Cleanup temp files
    rm "${_file}" "${_clean}" "${_script}" "${_script}.bak"
}

#MAIN
#Iterate through each cluster in the array/list and execute the runMain function
for cluster in "${!LIST[@]}"
do
   runMain
done

set +x
