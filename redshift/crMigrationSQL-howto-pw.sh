#!/usr/local/bin/bash

set -x #debug mode
set -e

# Setup pw keys for cluster to cluster
echo "Set up your source and target credentials first before executing script"
KEY=./.keyinfo
if ! [ -f "$KEY" ]; then
      echo "Key credentials not found. Setup one as pw1;pw2"
      exit 1
fi
IFS=";" read -a arr < "$KEY"

export SOURCE_PW=${arr[0]}
export TARGET_PW=${arr[1]}

# Create a Cluster Key to map alias to endpoints - OLD/SOURCE clusters
# Declare this array in the beginning
# Commented out "declare -A" no longer good with newer version of mac
#declare -A cluster_to_endpoint=(
#  cluster_to_endpoint=(
#  [c01]=mradev-events01.foobar.us-east-1.redshift.amazonaws.com
#  [c02]=mradev-events02.foobar.us-east-1.redshift.amazonaws.com
#  [c03]=mradev-events03.foobar.us-east-1.redshift.amazonaws.com
#  [c04]=mradev-events04.foobar.us-east-1.redshift.amazonaws.com
#)


# Mapping cluster alias names to endpoints - OLD/SOURCE clusters
if [[ $oldcluster == 'c01' ]]; then
  HOST="mradev-events01.foobar.us-east-1.redshift.amazonaws.com"
   elif [[ $oldcluster == 'c02' ]]; then
  HOST="mradev-events02.foobar.us-east-1.redshift.amazonaws.com"
   else
  echo "Old source cluster is in correct:"
        exit 1 
fi


# Mapping cluster alias names to endpoints - NEW clusters
if [[ $newcluster == 'c03' ]]; then
  HOST2="mradev-events03.foobar.us-east-1.redshift.amazonaws.com"
   elif [[ $newcluster == 'c04' ]]; then
  HOST2="mradev-events04.foobar.us-east-1.redshift.amazonaws.com"
   else
  echo "New cluster is in correct:"
        exit 1  
fi


# Usage for getopts
usage () {
    echo "Usage: $0 -o oldcluster -d database -t table -n newcluster -r region"
    echo "Example: $0 -o c01 -d ibm -t visitors -n c04 -r us-east-1"
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

# Setup VARS
export SCHEMAMAIN="${database}__main"
export TBL="${table}"
export REGION="${region}"
export TMPDIR="/tmp/${database}-${table}"
export LISTOLD="${TMPDIR}/ListOld.out"
export LISTNEW="${TMPDIR}/ListNew.out"
export LISTFINAL="${TMPDIR}/ListFinal.out"
export UNLOAD="${TMPDIR}/runUNLOAD-$TBL.sql"
export COPY="${TMPDIR}/runCOPY-$TBL.sql"
PSQL=$(which psql)
DTSTMP=$(date '+%Y-%m-%d')

# Create a TMPDIR to hold table lists
#if [[ -d "$TMPDIR" ]]; then
#     echo "Directory already created.."
#     echo "Remove directory and all its files..."
#     rm -r "${TMPDIR}"
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
echo "Source redshift multi-tenant cluster:${cluster_to_endpoint[$oldcluster]}"
echo "Customer:${database}"
echo "Schema:${SCHEMAMAIN}"
echo "Table to Migrate:${table}"

## Check to see if a table exists
# if it does then run get its list of columns
# May need to do check somewhere else
#"$PSQL" -h "${cluster_to_endpoint[$oldcluster]}" -U masteruser -d "$database" -p 5439 << EOF 
#Testing pw
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


##### trying to debug here if possible
#ST=$? #Give me the return code
#echo "$?"
# Need to trap this error: psql: FATAL:  database "mradb" does not exist  and cleanup tmpdir
##### trying to debug here if possible


# GetNewschema from old cluster
echo "Target redshift new cluster:${cluster_to_endpoint[$newcluster]}"
#"$PSQL" -h "${cluster_to_endpoint[$newcluster]}" -U masteruser -d "$database" -p 5439 << EOF 
#Testing pw
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
source ~/.bash_profile
echo  -e "from ${SCHEMAMAIN}.${TBL}') to 's3://mytestbucket.fooiq.com/${database}/main/unload/${DTSTMP}/${TBL}/' credentials 'aws_access_key_id=${AWS_ACCESS_KEY_ID};aws_secret_access_key=${AWS_SECRET_ACCESS_KEY}' MANIFEST ADDQUOTES ESCAPE GZIP NULL AS 'ttT4rss2j8';" >> $UNLOAD
echo  -e " ) FROM 's3://mytestbucket.fooiq.com/${database}/main/unload/${DTSTMP}/${TBL}/manifest' credentials 'aws_access_key_id=${AWS_ACCESS_KEY_ID};aws_secret_access_key=${AWS_SECRET_ACCESS_KEY}' REGION '${REGION}' MANIFEST REMOVEQUOTES ESCAPE GZIP COMPUPDATE OFF NULL AS 'ttT4rss2j8';" >> $COPY
