#!/bin/bash

set -e

#######################################################################
# Script:       ProvisionDB.sh
# Author:       Mel Adajar
#
# Function:     Creates a postgresql database for a given CUSTOMERID
# CUSTOMERID:   Number ID, example: 21218
# TARGETHOST:   Target host of Amazon RDS server
# DATA|NODATA:  NODATA should be used for a new database.
# tmapw:        master pw for tma - see admin
#
# Requirements: You will need your tma password and setup the customer
#               keys (.keyinfo) file in this order:
#               (dbowner, _loader, _pentaho, tma_readonly, _qs)
#######################################################################

if [[ $# != 4 ]]; then
   echo "Usage: ./ProvisionDB.sh <CUSTOMERID> <DATA|NODATA> <TARGETHOST> <tmapw>" 2>&1
   exit 1
fi

KEY=./.keyinfo
if ! [ -f "$KEY" ]; then
      echo "Key credentials not found. Create one."
      exit 1
fi
IFS=";" read -a arr < "$KEY"

# Checks for DATA or NODATA option for CreateTable.sql script
case $2 in
    DATA|NODATA)
       filename="CreateTables-$2.sql"
       ;;
    *)echo "Must enter DATA or NODATA"
      exit 1
      ;;
esac

export HOST_NM=$3
export PORT=5432
export DBOWNER_PWD=${arr[0]}
export DATALOAD_PWD=${arr[1]}
export PENTAHO_PWD=${arr[2]}
export READONLY_PWD=${arr[3]}
export QS_PWD=${arr[4]}
export DBOWNER="tma_dmc_$1"
export DLUSER="tma_dmc_$1_dataload"
export PENUSER="tma_dmc_$1_pentaho"
export QSUSER="tma_dmc_$1_qs"
export LOG="provisiondb-$1.log"
export PGPASSWORD="$4"
export DATESTMP=`date +'%m/%d/%Y %H:%M:%S:%3N'`
PSQL=`which psql`

# Query postgres db to see if database already exists 
CHKDBEXISTS=$(psql -h $HOST_NM -p 5432 -U tma postgres --tuples-only -c "SELECT 1 AS result FROM pg_database WHERE datname='$DBOWNER'";)

read -r CHKDBEXISTS <<<"$CHKDBEXISTS"
if [[ ${CHKDBEXISTS:-0} -eq 1 ]]; then
     echo "Database already in the system...$DATESTMP"
     echo "Check your customer ID number....$DATESTMP"
     echo "Exiting..........................$DATESTMP"
     exit 1
   else
     echo "Confirmed database does not exist...$DATESTMP"
     echo "Provision new database starting.....$DATESTMP"
#fi

# Run the CREATE ROLES script
echo "Running roles..." | tee >> $LOG
"$PSQL" -h $HOST_NM             \
        -p $PORT                \
        -U tma                  \
        -v v1=$DBOWNER          \
        -v v2=$DLUSER           \
        -v v3=$PENUSER          \
        -v v4=$1	        \
        -v vQS=$QSUSER	        \
        -v p1="'$DBOWNER_PWD'"  \
        -v p2="'$DATALOAD_PWD'" \
        -v p3="'$PENTAHO_PWD'"  \
        -v p4="'$1'"            \
        -v p5="'$READONLY_PWD'" \
        -v p6="'$QS_PWD'" 	\
        -a                      \
        -f CreateRoles.sql postgres | tee >> $LOG

echo "Starting CreateDB..." | tee >> $LOG
PGPASSWORD=$DBOWNER_PWD "$PSQL" -h $HOST_NM 		\
			        -p $PORT 		\
				-U $DBOWNER 		\
				-v v1=$DBOWNER  	\
				-v v2=$DLUSER 		\
				-v v3=$PENUSER  	\
				-v vQS=$QSUSER  	\
                                -a                      \
				-f CreateDB.sql postgres | tee >> $LOG 	

echo "Starting Create Tables..." | tee >> $LOG
PGPASSWORD=$DBOWNER_PWD "$PSQL" -h $HOST_NM 		\
				-p $PORT 		\
				-U $DBOWNER 		\
				-v v4=$1 	        \
                                -a                      \
				-f CreateTables-$2.sql $DBOWNER | tee >> $LOG

echo "Inserting Enum Dims - Time, Date..." | tee >> $LOG
PGPASSWORD=$DBOWNER_PWD "$PSQL" -h $HOST_NM 		\
				-p $PORT 		\
				-U $DBOWNER 		\
				-v v4=$1 	        \
                                -a                      \
				-f insertDimTimeDimDate.sql $DBOWNER | tee >> $LOG

echo "Starting Create Indexes..." | tee >> $LOG
PGPASSWORD=$DBOWNER_PWD "$PSQL" -h $HOST_NM 		\
				-p $PORT 		\
				-U $DBOWNER 		\
				-v v4=$1 	        \
                                -a                      \
                                -f CreateIndexes.sql $DBOWNER | tee >> $LOG

echo "Starting Create Views..." | tee >> $LOG
PGPASSWORD=$DBOWNER_PWD "$PSQL" -h $HOST_NM 		\
				-p $PORT 		\
				-U $DBOWNER 		\
				-v v4=$1 	        \
                                -a                      \
                                -f CreateViews.sql $DBOWNER | tee >> $LOG

echo "Starting Create Materialized Views..." | tee >> $LOG
PGPASSWORD=$DBOWNER_PWD "$PSQL" -h $HOST_NM 		\
				-p $PORT 		\
				-U $DBOWNER 		\
				-v v4=$1 	        \
                                -a                      \
                                -f CreateMaterializedViews.sql $DBOWNER | tee >> $LOG

echo "Starting GRANTS..." | tee >> $LOG
PGPASSWORD=$DBOWNER_PWD "$PSQL" -h $HOST_NM            \
                                -p $PORT               \
                                -U $DBOWNER            \
                                -v v4=$1               \
                                -v v5=$1_dataload      \
                                -v v6=$1_pentaho       \
                                -v vQS=$1_qs	       \
                                -a                     \
                                -f Grants.sql $DBOWNER | tee >> $LOG
fi
