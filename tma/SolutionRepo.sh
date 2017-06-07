#!/bin/bash

#######################################################################
# Script: 	SolutionRepo.sh
# Author: 	Mel Adajar
#
# Function: 	Creates pentaho databases needed for RDS  
# TARGETHOST: 	Target host of Amazon RDS server
#
# Requirements: You will need your tma password and setup a .keyinfo
#		file for (jcr_user, pentaho_user, hibuser) 
#######################################################################

if [[ $# != 1 ]]; then
   echo "Usage: ./SolutionRepo.sh <TARGETHOST>" 2>&1
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

export LOG="solrepo.log"
#: ${PSQL_HOME:=/bin}
PSQL=`which psql`

# Run the CREATE USERS script
echo "Creating Users and Databases..." | tee >> $LOG
"$PSQL" -h $HOST_NM 		\
        -p $PORT                \
	-v p1="'$JCKRBT_PWD'"	\
	-v p2="'$PENUSR_PWD'"	\
	-v p3="'$HIBUSR_PWD'"	\
        -U tma 	                \
        -a                      \
        -f crSolrepoUsersandDB.sql postgres | tee >> $LOG

echo "Creating Quartz Tables..." | tee >> $LOG
PGPASSWORD=$PENUSR_PWD "$PSQL" -h $HOST_NM 		\
	-p $PORT 		\
	-U $PENUSR 		\
	-v p2="'$PENUSR_PWD'"	\
        -a                      \
	-f crQuartz.sql quartz | tee >> $LOG

echo "Creating Pentaho operations mart schema and Tables..." | tee >> $LOG
PGPASSWORD=$HIBUSR_PWD "$PSQL" -h $HOST_NM 		\
	-p $PORT 		\
	-U $HIBUSR 		\
	-v p3="'$HIBUSR_PWD'"	\
        -a                      \
        -f crPentahoOperationsMart.sql hibernate | tee >> $LOG
rt_code=$?
exit 1
