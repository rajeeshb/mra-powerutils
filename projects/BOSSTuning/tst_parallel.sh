#!/usr/bin/ksh
ORACLE_HOME=/u01/app/oracle/product/11.1.0; export ORACLE_HOME
ORACLE_SID=bosshabi; export ORACLE_SID
ORA_NLS33=/u01/app/oracle/product/11.1.0/ocommon/nls/admin/data; export ORA_NLS33
TNS_ADMIN=/u01/app/oracle/product/11.1.0/network/admin; export TNS_ADMIN
LD_LIBRARY_PATH=/u01/app/oracle/product/11.1.0/lib:/u01/app/oracle/product/11.1.0/lib32:/usr/openwin/lib:/usr/dt/lib:/usr/lib; export LD_LIBRARY_PATH
LD_LIBRARY_PATH_64=/u01/app/oracle/product/11.1.0/lib:/u01/app/oracle/product/11.1.0/lib; export LD_LIBRARY_PATH_64
export PATH=$ORACLE_HOME/bin:/usr/bin:/usr/ccs/bin:/usr/local/bin:/usr/bin/X11:/etc:/usr/x/bin:$ORACLE_HOME/OPatch:/usr/contrib/bin:.
unset NLS_LANG
unset NLSPATH
unset ORA_NLS33

# Setup job
#MYLOG =/tmp/log_`date +%H%M%S`.log'
BASEDIR=/home/oracle/scripts/mra_dba/tuning;
MYLOG=$BASEDIR/mvhistory.log

# Get getTimestamp
getTimestamp() {
    echo `date '+%Y%m%d-%H:%M:%S'`
}

#Run Oracle Procedures
echo "====================================================" >> $MYLOG 2>&1
echo "RUN REFRESH PROCEDURES FIRST ===>" $(getTimestamp) >> $MYLOG 2>&1 
#/u01/app/oracle/product/11.1.0/bin/sqlplus / as sysdba @/home/oracle/scripts/mra_dba/tuning/run_STAGING.sql &
/u01/app/oracle/product/11.1.0/bin/sqlplus / as sysdba @/home/oracle/scripts/mra_dba/tuning/lock.sql &
pid0=$!
wait $pid0 
echo "Waiting for pid:$pid0 ===>$(getTimestamp)" >> $MYLOG 2>&1 
echo "RELEASING THE HORSEMEN    ===>$(getTimestamp)" >> $MYLOG 2>&1 
#/u01/app/oracle/product/11.1.0/bin/sqlplus / as sysdba @/home/oracle/scripts/mra_dba/tuning/run_HORSEMEN1.sql &
/u01/app/oracle/product/11.1.0/bin/sqlplus / as sysdba @/home/oracle/scripts/mra_dba/tuning/lock1.sql &
pid1=$! 
#/u01/app/oracle/product/11.1.0/bin/sqlplus / as sysdba @/home/oracle/scripts/mra_dba/tuning/run_HORSEMEN2.sql &
/u01/app/oracle/product/11.1.0/bin/sqlplus / as sysdba @/home/oracle/scripts/mra_dba/tuning/lock2.sql &
pid2=$!
#/u01/app/oracle/product/11.1.0/bin/sqlplus / as sysdba @/home/oracle/scripts/mra_dba/tuning/run_HORSEMEN3.sql &
/u01/app/oracle/product/11.1.0/bin/sqlplus / as sysdba @/home/oracle/scripts/mra_dba/tuning/lock3.sql &
pid3=$!
#/u01/app/oracle/product/11.1.0/bin/sqlplus / as sysdba @/home/oracle/scripts/mra_dba/tuning/run_HORSEMEN4.sql &
/u01/app/oracle/product/11.1.0/bin/sqlplus / as sysdba @/home/oracle/scripts/mra_dba/tuning/lock4.sql &
pid4=$!
wait $pid1 $pid2 $pid3 $pid4
echo "Waiting for pids: $pid1   ===>$(getTimestamp)" >> $MYLOG 2>&1
echo "Waiting for pids: $pid2   ===>$(getTimestamp)" >> $MYLOG 2>&1
echo "Waiting for pids: $pid3   ===>$(getTimestamp)" >> $MYLOG 2>&1
echo "Waiting for pids: $pid4   ===>$(getTimestamp)" >> $MYLOG 2>&1
echo "Running clean extracts    ===>$(getTimestamp)" >> $MYLOG 2>&1

#/u01/app/oracle/product/11.1.0/bin/sqlplus / as sysdba @/home/oracle/scripts/mra_dba/tuning/run_CLEAN.sql
/u01/app/oracle/product/11.1.0/bin/sqlplus / as sysdba @/home/oracle/scripts/mra_dba/tuning/lock5.sql

echo "Process Complete          ===>$(getTimestamp)" >> $MYLOG  2>&1
exit 0
