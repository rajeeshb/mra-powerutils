#/usr/bin/ksh

if [ $# != 2 ]; then
    echo "USAGE: ./test.sh <user> <pw>" 2>&1
    exit 1
fi

# Setup Oracle Environment
ORACLE_HOME=/u01/app/oracle/product/11.1.0; 
ORACLE_SID=bosshabi; 
ORA_NLS33=/u01/app/oracle/product/11.1.0/ocommon/nls/admin/data; 
TNS_ADMIN=/u01/app/oracle/product/11.1.0/network/admin; 
LD_LIBRARY_PATH=/u01/app/oracle/product/11.1.0/lib:/u01/app/oracle/product/11.1.0/lib32:/usr/openwin/lib:/usr/dt/lib:/usr/lib; 
LD_LIBRARY_PATH_64=/u01/app/oracle/product/11.1.0/lib:/u01/app/oracle/product/11.1.0/lib; 

export ORACLE_HOME ORACLE_SID ORA_NLS33 TNS_ADMIN LD_LIBRARY_PATH LD_LIBRARY_PATH_64
export PATH=$ORACLE_HOME/bin:/usr/bin:/usr/ccs/bin:/usr/local/bin:/usr/bin/X11:/etc:/usr/x/bin:$ORACLE_HOME/OPatch:/usr/contrib/bin:.

unset NLS_LANG
unset NLSPATH
unset ORA_NLS33

TIMESTAMP=`date '+%Y%m%d-%H:%M'`
export TIMESTAMP

echo "STARTING PROCEDURES.... $TIMESTAMP" 2>&1
#/u01/app/oracle/product/11.1.0/bin/sqlplus / as sysdba @/home/oracle/scripts/mra_dba/tuning/secret_exp.sql
#/u01/app/oracle/product/11.1.0/bin/sqlplus / as sysdba @/home/oracle/scripts/mra_dba/tuning/run_FOURHORSEMEN.sql
/u01/app/oracle/product/11.1.0/bin/sqlplus $1/$2 @/home/oracle/scripts/mra_dba/tuning/lock.sql

exit 0
