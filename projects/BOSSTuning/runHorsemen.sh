#/usr/bin/ksh

# Setup Oracle Environment
ORACLE_HOME=/u01/app/oracle/product/11.1.0; 
ORACLE_SID=mydevhabi; 
ORA_NLS33=/u01/app/oracle/product/11.1.0/ocommon/nls/admin/data; 
TNS_ADMIN=/u01/app/oracle/product/11.1.0/network/admin; 
LD_LIBRARY_PATH=/u01/app/oracle/product/11.1.0/lib:/u01/app/oracle/product/11.1.0/lib32:/usr/openwin/lib:/usr/dt/lib:/usr/lib; 
LD_LIBRARY_PATH_64=/u01/app/oracle/product/11.1.0/lib:/u01/app/oracle/product/11.1.0/lib; 
export PATH=$ORACLE_HOME/bin:/usr/bin:/usr/ccs/bin:/usr/local/bin:/usr/bin/X11:/etc:/usr/x/bin:$ORACLE_HOME/OPatch:/usr/contrib/bin:.
unset NLS_LANG
unset NLSPATH
unset ORA_NLS33

# Setup job
TIMESTAMP=`date '+%Y%m%d-%H:%M'`;
#BASE=/home/mydevasdm/scripts;
BASEDIR=/home/oracle/scripts/mra_dba/tuning;
KEY=$BASEDIR/.keyinfo;

# Check before we run
if [ -f "$KEY" ]
then
IFS="
"
set -A arr $(cat $KEY)
echo "Running 4 HORSEMEN ===>$TIMESTAMP" 2>&1
#/u01/app/oracle/product/11.1.0/bin/sqlplus / as sysdba @/home/oracle/scripts/mra_dba/tuning/run_FOURHORSEMEN.sql
#/u01/app/oracle/product/11.1.0/bin/sqlplus ${arr[0]}/${arr[1]} @/home/oracle/scripts/mra_dba/run_FOURHORSEMEN.sql
/u01/app/oracle/product/11.1.0/bin/sqlplus ${arr[0]}/${arr[1]} @/home/oracle/scripts/mra_dba/tuning/dual.sql

else
   echo "Boss key not found. Exiting.  ==>$TIMESTAMP" 2>&1
fi

exit 0
