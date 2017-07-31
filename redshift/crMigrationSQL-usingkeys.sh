#!/usr/local/bin/bash

set -e
set -x

# Setup pw keys for cluster to cluster
echo "Set up your source and target credentials first before executing script"
KEY=./.migration_keys
if ! [ -f "$KEY" ]; then
      echo "Key credentials not found. Setup one as pw1;pw2"
      exit 1
fi
IFS="#" read -a arr < "$KEY"

export SOURCE_PW="${arr[0]}"
export TARGET_PW="${arr[1]}"


# Usage for getopts
usage () {
    echo "Usage: $0 -o oldcluster -d database -t table -n newcluster -r region"
    echo "Example: $0 -o rs01 -d ibm -t visitors -n rs04 -r us-east-1"
    echo "Cluster Key:"
    for i in "${!cluster_to_endpoint[@]}"
    do
      echo "$i:${cluster_to_endpoint[$i]}"
    done | sort 
}

while getopts ":o:d:t:n:r:" opt; do
  case $opt in
    o) oldcluster="$OPTARG";;
    d) export database="$OPTARG";;
    t) export table="$OPTARG";;
    n) newcluster="$OPTARG";;
    r) export region="$OPTARG";;
    *) usage
       exit 1
       ;;
  esac
done

# Create a Cluster Key to map alias to endpoints - OLD/SOURCE clusters
# Declare this array in the beginning
declare -A cluster_to_endpoint=(
	[rs01]=mydata-"${region}"-1.mydomain.com
	[rs02]=mydata-"${region}"-2.mydomain.com
	[rs03]=mydata-"${region}"-3.mydomain.com
	[rs04]=mydata-"${region}"-4.mydomain.com
	[rs05]=mydata-"${region}"-5.mydomain.com
	[rs06]=mydata-"${region}"-6.mydomain.com
	[rs07]=mydata-"${region}"-7.mydomain.com
	[rs08]=mydata-"${region}"-8.mydomain.com
	[rs09]=mydata-"${region}"-9.mydomain.com
	[rs10]=mydata-"${region}"-10.mydomain.com
	[rs11]=mydata-"${region}"-11.mydomain.com
	[rs12]=mydata-"${region}"-12.mydomain.com
	[rs13]=mydata-"${region}"-13.mydomain.com
	[rs14]=mydata-"${region}"-14.mydomain.com
	[rs15]=mydata-"${region}"-15.mydomain.com
	[rs16]=mydata-"${region}"-16.mydomain.com
	[rs17]=mydata-"${region}"-17.mydomain.com
	[rs18]=mydata-"${region}"-18.mydomain.com
	[rs19]=mydata-"${region}"-19.mydomain.com
	[rs20]=mydata-"${region}"-20.mydomain.com
)

# Setup VARS
# Note: There maybe more than __main profile
export SCHEMAMAIN="${database}__main"
export TBL="${table}"
export REGION="${region}"
export TMPDIR="/home/madajar/${database}-${table}"
export LISTOLD="${TMPDIR}/ListOld.out"
export LISTNEW="${TMPDIR}/ListNew.out"
export LISTFINAL="${TMPDIR}/ListFinal.out"
export UNLOAD="${TMPDIR}/runUNLOAD-$TBL.sql"
export COPY="${TMPDIR}/runCOPY-$TBL.sql"
PSQL=$(which psql)
DTSTMP=$(date '+%Y-%m-%d')

# Create a TMPDIR to hold table lists
#if [[ -d "${TMPDIR}" ]]; then
#     echo "Directory already created.."
#     echo "Remove directory and all its files..."
     #rm -rf "${TMPDIR}"
#     echo "Create a new temporary directory.."
     mkdir -p "${TMPDIR}"
#   else
#     echo "Error creating temp dir. Exiting.."
#     exit 1
#fi

# Generating UNLOAD and COPY sql files
# Creating header statements 
echo -e "UNLOAD ('select" > "$UNLOAD"
echo -e "COPY ${SCHEMAMAIN}.${TBL} ( " > "$COPY"

# GET LIST OF TABLE COLUMNS TO COMPARE
# GetOldschema from old cluster
echo "Source redshift cluster:${cluster_to_endpoint[$oldcluster]}"
echo "Customer:${database}"
echo "Schema:${SCHEMAMAIN}"
echo "Table to Migrate:${table}"

## Check to see if a table exists
# if it does then run get its list of columns
# May need to do check somewhere else
PGPASSWORD=$SOURCE_PW "$PSQL" -h "${cluster_to_endpoint[$oldcluster]}" -U masteruser -d "$database" -p 5439 << EOF 
        \a
        \t
        \o $LISTOLD
	SELECT column_name
	FROM information_schema.columns
	WHERE table_schema = '$SCHEMAMAIN'
  	AND table_name   = '$TBL'
	order by ordinal_position;
EOF

# GetNewschema from old cluster
echo "Target redshift cluster:${cluster_to_endpoint[$newcluster]}"
PGPASSWORD=$TARGET_PW "$PSQL" -h "${cluster_to_endpoint[$newcluster]}" -U masteruser -d "$database" -p 5439 << EOF 
        \a
        \t
        \o $LISTNEW
	SELECT column_name
	FROM information_schema.columns
	WHERE table_schema = '$SCHEMAMAIN'
  	AND table_name   = '$TBL'
	order by ordinal_position;
EOF

# Perform an intersection on the lists
echo "Creating Final List"
comm -12 <(sort $LISTNEW) <(sort $LISTOLD) > "$LISTFINAL"


# Do a PASTE to create csv file
echo "Changing to csv..."
/usr/bin/paste -sd, "$LISTFINAL" >> "$UNLOAD"
/usr/bin/paste -sd, "$LISTFINAL" >> "$COPY"


# Complete UNLOAD & COPY sql files
# Export your AWS keys - if your keys are in .bash_profile
# Note: created .migration_creds for this purpose only
source ~/.migration_creds
echo  -e "from ${SCHEMAMAIN}.${TBL}') to 's3://mydata-${region}.mydomain.com/${database}/main/unload/${DTSTMP}/${TBL}/' credentials 'aws_access_key_id=${AWS_ACCESS_KEY_ID};aws_secret_access_key=${AWS_SECRET_ACCESS_KEY}' MANIFEST ADDQUOTES ESCAPE GZIP NULL AS 'ttT4rss2j8';" >> $UNLOAD
echo  -e " ) FROM 's3://mydata-${region}.mydomain.com/${database}/main/unload/${DTSTMP}/${TBL}/manifest' credentials 'aws_access_key_id=${AWS_ACCESS_KEY_ID};aws_secret_access_key=${AWS_SECRET_ACCESS_KEY}' REGION '${REGION}' MANIFEST REMOVEQUOTES ESCAPE GZIP COMPUPDATE OFF NULL AS 'ttT4rss2j8';" >> $COPY

set +x
