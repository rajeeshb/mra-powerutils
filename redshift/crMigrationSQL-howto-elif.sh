#!/usr/local/bin/bash
set -e

usage () {
    echo "Usage: $0 -o oldcluster -d database -t table -n newcluster"
}

while getopts ":o:d:t:n:" opt; do
  case $opt in
    o) oldcluster="$OPTARG";;
    d) export database="$OPTARG";;
    t) export table="$OPTARG";;
    n) newcluster="$OPTARG";;
    *) echo "Error unknown option -$OPTARG" 
       usage
       exit 1
       ;;
  esac
done

# Setup VARS
#export SCHEMAMAIN="${database}__main"
export SCHEMAMAIN="${database}__france"
export TBL="${table}"
export TMPDIR="/tmp/${database}-${table}"
export LISTOLD="${TMPDIR}/ListOld.out"
export LISTNEW="${TMPDIR}/ListNew.out"
export LISTFINAL="${TMPDIR}/ListFinal.out"
export UNLOAD="${TMPDIR}/runUNLOAD-$TBL.sql"
export COPY="${TMPDIR}/runCOPY-$TBL.sql"
PSQL=$(which psql)
DTSTMP=$(date '+%Y-%m-%d')

# Export your keys
source ~/.bash_profile

# Mapping cluster alias names to endpoints - OLD/SOURCE clusters
if [[ $oldcluster == 'cluster1' ]]; then
	HOST="mradev-events01.foobar.us-east-1.redshift.amazonaws.com"
   elif [[ $oldcluster == 'cluster2' ]]; then
	HOST="mradev-events02.foobar.us-east-1.redshift.amazonaws.com"
   else
	echo "Old source cluster is in correct:"
        exit 1 
fi


# Mapping cluster alias names to endpoints - NEW clusters
if [[ $newcluster == 'cluster3' ]]; then
	HOST2="mradev-events3-redshiftcluster.foobar.us-east-1.redshift.amazonaws.com"
   elif [[ $newcluster == 'cluster4' ]]; then
	HOST2="mradev-events4-redshiftcluster.foobar.us-east-1.redshift.amazonaws.com"
   else
	echo "New cluster is in correct:"
        exit 1  
fi

# Create a TMPDIR to hold table lists
# if exists, then just clean up the files 
if [ ! -d "$TMPDIR" ]; then
     echo "Creating a temporary directory:${TMPDIR}"
     mkdir -p "${TMPDIR}"
   else
     echo "Directory already created"
     echo "Cleaning up old files..."
     rm "$LISTOLD"
     rm "$LISTNEW"
     rm "$LISTFINAL"
     rm "$UNLOAD"
     rm "$COPY" 
     #exit 1
fi

# Generating UNLOAD and COPY sql files
# Creating header statements 
echo -e "UNLOAD ('select" > "$UNLOAD"
echo -e "COPY ${SCHEMAMAIN}.${TBL} ( " > "$COPY"

# GET LIST OF TABLE COLUMNS TO COMPARE
# GetOldschema from old cluster
echo "Source redshift cluster:${HOST}"
echo "Customer:${database}"
echo "Schema:${SCHEMAMAIN}"
echo "Table to Migrate:${table}"
"$PSQL" -h "$HOST" -U masteruser -d "$database" -p 5439 << EOF 
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

# GetNewschema from old cluster
echo "Target redshift cluster:${HOST2}"
"$PSQL" -h "$HOST2" -U masteruser -d "$database" -p 5439 << EOF 
        \a
        \t
        \o $LISTNEW
	SELECT column_name
	FROM information_schema.columns
	WHERE table_schema = '$SCHEMAMAIN'
  	AND table_name   = '$TBL'
	order by ordinal_position;
EOF

# Performa an intersection on the lists
echo "Creating Final List"
comm -12 <(sort $LISTNEW) <(sort $LISTOLD) > "$LISTFINAL"

# Do a PASTE to create csv file
echo "Changing to csv..."
/usr/bin/paste -sd, "$LISTFINAL" >> "$UNLOAD"
/usr/bin/paste -sd, "$LISTFINAL" >> "$COPY"

# Complete UNLOAD & COPY sql files
# Export your AWS keys
source ~/.bash_profile
echo  -e "from ${SCHEMAMAIN}.${TBL}') to 's3://mytestbucket.fooiq.com/${database}/main/unload/${DTSTMP}/${TBL}/' credentials 'aws_access_key_id=${AWS_ACCESS_KEY_ID};aws_secret_access_key=${AWS_SECRET_ACCESS_KEY}' MANIFEST ADDQUOTES ESCAPE GZIP NULL AS 'ttT4rss2j8';" >> $UNLOAD
echo  -e " ) FROM 's3://mytestbucket.fooiq.com/${database}/main/unload/${DTSTMP}/${TBL}/manifest' credentials 'aws_access_key_id=${AWS_ACCESS_KEY_ID};aws_secret_access_key=${AWS_SECRET_ACCESS_KEY}' MANIFEST REMOVEQUOTES ESCAPE GZIP COMPUPDATE OFF NULL AS 'ttT4rss2j8';" >> $COPY
