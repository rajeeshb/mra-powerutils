#!/usr/local/bin/bash

# PURPOSE:
# Creates a shell script with AWS UNLOAD statements against a redshift cluster

# Setup pw keys for cluster to cluster
# edit .migration_keys file for correct pws
echo "Set up your source and target credentials first before executing script"
KEY=./.migration_keys
if ! [ -f "$KEY" ]; then
      echo "Key credentials not found. Setup one as pw1;pw2"
      exit 1
fi
IFS="" read -a arr < "$KEY"

export SOURCE_PW="${arr[0]}"

# Usage for getopts
usage () {
    echo "Usage: $0 -c cluster -d database -r region"
    echo "Example: $0 -c rs01 -d ibm -r us-east-1"
    echo "Cluster Key:"
    for i in "${!cluster_to_endpoint[@]}"
    do
      echo "$i:${cluster_to_endpoint[$i]}"
    done | sort
}

while getopts ":c:d:r:" opt; do
  case $opt in
    c) export cluster="$OPTARG";;
    d) export database="$OPTARG";;
    r) export region="$OPTARG";;
    *) usage
       exit 1
       ;;
  esac
done

# Create a Cluster Key to map alias to endpoints 
# Declare this array in the beginning
declare -A cluster_to_endpoint=(
        [rs01]=myapplication-"${region}"-1.melsterdba.com
        [rs02]=myapplication-"${region}"-2.melsterdba.com
        [rs03]=myapplication-"${region}"-3.melsterdba.com
        [rs04]=myapplication-"${region}"-4.melsterdba.com
        [rs05]=myapplication-"${region}"-5.melsterdba.com
        [rs06]=myapplication-"${region}"-6.melsterdba.com
        [rs07]=myapplication-"${region}"-7.melsterdba.com
        [rs08]=myapplication-"${region}"-8.melsterdba.com
        [rs09]=myapplication-"${region}"-9.melsterdba.com
        [rs10]=myapplication-"${region}"-10.melsterdba.com
)

# Setup VARS
# Note: There maybe more than __main profile
export SCHEMAMAIN="${database}__main"
export REGION="${region}"
export HOMEDIR="$(echo $HOME)"
export TMPDIR="${HOMEDIR}/backup-${database}"
export UNLOAD="${TMPDIR}/runUNLOAD.sql"
export RUNTHIS="${TMPDIR}/runBACKUP.sh"
export DTSTMP=$(date '+%Y-%m-%d')

mkdir -p "${TMPDIR}"

# DISPLAY PERTINENT INFO
echo "Source redshift cluster:${cluster_to_endpoint[$cluster]}"
echo "Customer:${database}"
echo "Schema:${SCHEMAMAIN}"

# Complete UNLOAD sql files
# Export your AWS keys - if your keys are in .bash_profile
source ~/.migration_creds2
echo  -e "UNLOAD ('select * from ${SCHEMAMAIN}.actions') to 's3://myapplication-${region}.melsterdba.com/${database}/main/unload/${DTSTMP}/actions/' credentials 'aws_access_key_id=${AWS_ACCESS_KEY_ID};aws_secret_access_key=${AWS_SECRET_ACCESS_KEY}' MANIFEST ADDQUOTES ESCAPE GZIP NULL AS 'ttT4rss2j8';" >> $UNLOAD
echo  -e "UNLOAD ('select * from ${SCHEMAMAIN}.customers') to 's3://myapplication-${region}.melsterdba.com/${database}/main/unload/${DTSTMP}/customers/' credentials 'aws_access_key_id=${AWS_ACCESS_KEY_ID};aws_secret_access_key=${AWS_SECRET_ACCESS_KEY}' MANIFEST ADDQUOTES ESCAPE GZIP NULL AS 'ttT4rss2j8';" >> $UNLOAD
echo  -e "UNLOAD ('select * from ${SCHEMAMAIN}.visitor_replaces') to 's3://myapplication-${region}.melsterdba.com/${database}/main/unload/${DTSTMP}/visitor_replaces/' credentials 'aws_access_key_id=${AWS_ACCESS_KEY_ID};aws_secret_access_key=${AWS_SECRET_ACCESS_KEY}' MANIFEST ADDQUOTES ESCAPE GZIP NULL AS 'ttT4rss2j8';" >> $UNLOAD
echo  -e "UNLOAD ('select * from ${SCHEMAMAIN}.visitor_batches') to 's3://myapplication-${region}.melsterdba.com/${database}/main/unload/${DTSTMP}/visitor_batches/' credentials 'aws_access_key_id=${AWS_ACCESS_KEY_ID};aws_secret_access_key=${AWS_SECRET_ACCESS_KEY}' MANIFEST ADDQUOTES ESCAPE GZIP NULL AS 'ttT4rss2j8';" >> $UNLOAD
echo  -e "UNLOAD ('select * from ${SCHEMAMAIN}.clicks__all_clicks') to 's3://myapplication-${region}.melsterdba.com/${database}/main/unload/${DTSTMP}/clicks__all_clicks/' credentials 'aws_access_key_id=${AWS_ACCESS_KEY_ID};aws_secret_access_key=${AWS_SECRET_ACCESS_KEY}' MANIFEST ADDQUOTES ESCAPE GZIP NULL AS 'ttT4rss2j8';" >> $UNLOAD

echo -e "#!/usr/local/bin/bash" >> "$RUNTHIS"
echo -e "PGPASSWORD=${SOURCE_PW} psql -h ${cluster_to_endpoint[$cluster]} -U masteruser -d ${database} -p 5439 -f $UNLOAD" >> "$RUNTHIS"
