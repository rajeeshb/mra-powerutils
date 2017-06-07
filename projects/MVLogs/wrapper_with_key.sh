#/usr/bin/ksh

ORACLE_HOME=/u01/app/oracle/product/11.1.0; export ORACLE_HOME
ORACLE_SID=sm7; export ORACLE_SID
ORA_NLS33=/u01/app/oracle/product/11.1.0/ocommon/nls/admin/data; export ORA_NLS33
TNS_ADMIN=/u01/app/oracle/product/11.1.0/network/admin; export TNS_ADMIN
LD_LIBRARY_PATH=/u01/app/oracle/product/11.1.0/lib:/u01/app/oracle/product/11.1.0/lib32:/usr/openwin/lib:/usr/dt/lib:/usr/lib; export LD_LIBRARY_PATH
LD_LIBRARY_PATH_64=/u01/app/oracle/product/11.1.0/lib:/u01/app/oracle/product/11.1.0/lib; export LD_LIBRARY_PATH_64
export PATH=$ORACLE_HOME/bin:/usr/bin:/usr/ccs/bin:/usr/local/bin:/usr/bin/X11:/etc:/usr/x/bin:$ORACLE_HOME/OPatch:/usr/contrib/bin:.
unset NLS_LANG
unset NLSPATH
unset ORA_NLS33

# Setup job
TIMESTAMP=`date '+%Y%m%d-%H:%M'`;
#BASE=/home/bossasdm/scripts;
BASEDIR=/home/oracle/scripts/mra;
KEY=$BASEDIR/.keyinfo;
SHRINK=/tmp/shrink_mvlog.sql;

# USE THIS IF WE NEED A KEY FILE
# Check before we run
if [ -f "$KEY" ]
then
IFS="
"
set -A arr $(cat $KEY)
echo "Create SHRINK script  ===> $TIMESTAMP"
#/u01/app/oracle/product/11.1.0/bin/sqlplus -s ${arr[0]}/${arr[1]} @/home/oracle/scripts/mra/dyn_shrink.sql 
/u01/app/oracle/product/11.1.0/bin/sqlplus -s ${arr[0]}/${arr[1]} @/home/oracle/scripts/mra/dyn_test.sql 
else
   echo "Boss key not found. Exiting.  ==> $TIMESTAMP" 
   exit 0
fi

# Check for dynamic file exists
if [ -e "$SHRINK" ]
then
echo "Executing SHRINK script  ===> $TIMESTAMP" 
/u01/app/oracle/product/11.1.0/bin/sqlplus -s ${arr[0]}/${arr[1]} @$SHRINK
fi 
exit 0
