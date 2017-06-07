#/usr/bin/ksh
#/u01/app/oracle/product/11.1.0/bin/sqlplus / as sysdba @re-cr8_DETAIL_INTERACTION_MV.sql
#/u01/app/oracle/product/11.1.0/bin/sqlplus / as sysdba @re-cr8_DETAIL_INCIDENT_MV.sql
#/u01/app/oracle/product/11.1.0/bin/sqlplus / as sysdba @re-cr8_DETAIL_INCIDENT_WORKLOG_MV.sql
#/u01/app/oracle/product/11.1.0/bin/sqlplus / as sysdba @re-cr8_DETAIL_INTERACTION_WORKLOG_MV.sql
#/u01/app/oracle/product/11.1.0/bin/sqlplus / as sysdba @brp999-Deprc8DEVICE_CONTACTS2.sql
#/u01/app/oracle/product/11.1.0/bin/sqlplus / as sysdba @brp999-Deprc8DEVICE_CONTACTS3.sql
/u01/app/oracle/product/11.1.0/bin/sqlplus / as sysdba @secret_exp.sql
exit 0
