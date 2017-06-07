#!/bin/bash

#######################################################################
# Script: 	ValidateDB.sh
# Author: 	Mel Adajar
#
# Function: 	Creates a postgresql database for a given CUSTOMERID
# CUSTOMERID: 	Number ID, example: 21218
# TARGETHOST: 	Target host of Amazon RDS server
#
# DB Name:      tma_dmc_<CUSTOMERID>
#
# Requirements: You will need your tma password and setup the customer
#               keys for (dbowner, loader, pentaho users
#######################################################################

if [[ $# != 1 ]]; then
   echo "Usage: ./ValidateDB.sh <TARGETHOST>" 2>&1
   exit 1
fi

KEY=./.keyinfo
if ! [ -f "$KEY" ]; then
      echo "Key credentials not found. Create one."
      exit 1
fi
IFS=";" read -a arr < "$KEY"


export HOST_NM=$1
export PORT=5432
export JCKRBT_PWD=${arr[0]}
export PENUSR_PWD=${arr[1]}
export HIBUSR_PWD=${arr[2]}
export JCKRBT="jcr_user"
export PENUSR="pentaho_user"
export HIBUSR="hibuser"
export PENUSR_DB="quartz"
export HIBUSR_DB="hibernate"
export RPT="validationrpt.out"
#: ${PSQL_HOME:=/bin}
PSQL=`which psql`

echo "Running Validate $PENUSR_DB..." | tee >> $RPT
PGPASSWORD=$PENUSR_PWD "$PSQL" -h $HOST_NM 		\
				-p $PORT 		\
				-U $PENUSR 		\
                                -a                      \
				-f Validate.sql $PENUSR_DB | tee >> $RPT
echo "Running Validate $HIBUSR_DB..." | tee >> $RPT
PGPASSWORD=$PENUSR_PWD "$PSQL" -h $HOST_NM 		\
				-p $PORT 		\
				-U $HIBUSR 		\
                                -a                      \
				-f Validate.sql $HIBUSR_DB | tee >> $RPT
rt_code=$?
exit 1
