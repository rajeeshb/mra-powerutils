#!/bin/bash


if [[ $# != 3 ]]; then
   echo "Usage: ./ProvisionDB.sh <CUSTOMERID> <TARGETHOST> <tmapw>" 2>&1
   exit 1
fi


export HOST_NM=$2
export TMAPWD=$3
export PORT=5432
export DBOWNER="tma_dmc_$1"
export DLUSER="tma_dmc_$1_dataload"
export PENUSER="tma_dmc_$1_pentaho"
export QSUSER="tma_dmc_$1_qs"
PSQL=`which psql`

echo "Dropping database and roles for $DBOWNER..." 
PGPASSWORD=$TMAPWD "$PSQL" -h $HOST_NM 			\
			        -p $PORT 		\
				-U tma 			\
				-v v1=$DBOWNER  	\
				-v v2=$DLUSER 		\
				-v v3=$PENUSER  	\
				-v vQS=$QSUSER  	\
                                -a                      \
				-f Drop.sql postgres 	
