#/usr/bin/ksh
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

#Declare variables
TIMESTAMP=`date '+%Y%m%d-%H:%M'`
export TIMESTAMP;

#Base dir
#BASE=/home/bossasdm/scripts
BASEDIR=/home/oracle/scripts/mra_dba/tuning
export BASEDIR;
#Key
KEY=$BASEDIR/.keyinfo
export KEY;

if [ -f "$KEY" ]   
then

#This piece of code IFS=Internal Field Separator
#Allow the use of credentials passed in 2 separate lines "key.info"

IFS="
"
set -A arr $(cat $KEY) 				#This line reads the "key.info" file as located in $2 (basedir)
echo "username=${arr[0]}   password=${arr[1]}" #Use this to test/view data
						#First line read into $arr[0]
						#Second line read into $arr[1]

echo "STARTING PROCEDURES.... $TIMESTAMP" 2>&1
#/u01/app/oracle/product/11.1.0/bin/sqlplus / as sysdba @/home/oracle/scripts/mra_dba/tuning/secret_exp.sql
/u01/app/oracle/product/11.1.0/bin/sqlplus ${arr[0]}/${arr[1]} @/home/oracle/scripts/mra_dba/tuning/dual.sql

else
   echo "key not found. Exiting... $TIMESTAMP" 2>&1
fi

exit 0
