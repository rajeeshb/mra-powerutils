#/usr/bin/ksh

# Checks for parameters
if [ $# != 2 ]; then
    echo "Usage: shrinkwrap.sh <oracle_sid> <test|shrink>" 2>&1
    exit 1
fi

# ORACLE ENV VARIABLES
ORACLE_HOME=/u01/app/oracle/product/11.1.0; export ORACLE_HOME
ORACLE_SID=$1; export ORACLE_SID
ORA_NLS33=/u01/app/oracle/product/11.1.0/ocommon/nls/admin/data; export ORA_NLS33
TNS_ADMIN=/u01/app/oracle/product/11.1.0/network/admin; export TNS_ADMIN
LD_LIBRARY_PATH=/u01/app/oracle/product/11.1.0/lib:/u01/app/oracle/product/11.1.0/lib32:/usr/openwin/lib:/usr/dt/lib:/usr/lib; export LD_LIBRA
RY_PATH
LD_LIBRARY_PATH_64=/u01/app/oracle/product/11.1.0/lib:/u01/app/oracle/product/11.1.0/lib; export LD_LIBRARY_PATH_64
export PATH=$ORACLE_HOME/bin:/usr/bin:/usr/ccs/bin:/usr/local/bin:/usr/bin/X11:/etc:/usr/x/bin:$ORACLE_HOME/OPatch:/usr/contrib/bin:.
unset NLS_LANG
unset NLSPATH
unset ORA_NLS33

# Setup job
TIMESTAMP=`date '+%Y%m%d-%H:%M'`;
#BASEDIR=/home/bossasdm/scripts;
BASEDIR=/home/oracle/scripts/mra;
SHRINK=/tmp/shrink_mvlog.sql;

# Check correct scripts exist
case $2 in
   test|shrink)
      filename="$BASEDIR/dyn_$2.sql"
      ;;
   *)echo "Must enter test or shrink"
     exit 1
     ;;
esac


# Check for any errors in calling script
if [ -f "$filename" ];
then
        echo "Correct dynamic sql scripts exist..."
        echo "Creating SHRINK sql script....... $TIMESTAMP"
        echo "============================================"
        /u01/app/oracle/product/11.1.0/bin/sqlplus -s / as sysdba @$BASEDIR/dyn_$2.sql
        echo "============================================"
        # Check to make sure no errors during creation of dynamic sql script
        echo "Check for any errors....."
        if /usr/bin/grep -q "ORA-" "$SHRINK"
        then
                echo "Error found creation of sql script...... $TIMESTAMP"
                echo "Exiting..."
                exit 1
                else
                     echo "Shrink script looks good..... $TIMESTAMP"
                     echo "Executing SHRINK script...... $TIMESTAMP"
                     /u01/app/oracle/product/11.1.0/bin/sqlplus -s / as sysdba @$SHRINK
        fi
else
    echo "Nothing happened...check logs"
    exit 1
fi
echo "COMPLETED"
exit 0
