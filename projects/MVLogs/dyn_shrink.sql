set echo off
set feed off
set serveroutput on size 1000000
spool /tmp/shrink_mvlog.sql

DECLARE
	v_Table varchar2(30);
 	v_Owner varchar2(30);
	v_SQL   varchar2(4000);
	
CURSOR c_mvname_list IS
        select mowner, master from sys.mlog$ where mowner='MRA_DBA';
BEGIN
	OPEN c_mvname_list;
	dbms_output.put_line('set feed on');
	dbms_output.put_line('set echo on');
	dbms_output.put_line('set timing on');
	--dbms_output.put_line('spool /tmp/shrink_mvlog.log');
       
	LOOP
	    FETCH c_mvname_list into v_Owner, v_Table;
	    EXIT WHEN c_mvname_list%NOTFOUND;
            v_SQL := 'ALTER MATERIALIZED VIEW LOG ON ' || v_Owner || '.' || v_Table || ' ENABLE ROW MOVEMENT;';
 	    dbms_output.put_line(substr(v_SQL,1,255));
            v_SQL := 'ALTER MATERIALIZED VIEW LOG ON ' || v_Owner || '.' || v_Table || ' SHRINK SPACE CASCADE;';
 	    dbms_output.put_line(substr(v_SQL,1,255));
            v_SQL := 'ALTER MATERIALIZED VIEW LOG ON ' || v_Owner || '.' || v_Table || ' DISABLE ROW MOVEMENT;';
 	    dbms_output.put_line(substr(v_SQL,1,255));
	END LOOP;

	--dbms_output.put_line('spool off');
	dbms_output.put_line('exit;');
CLOSE c_mvname_list;
EXCEPTION
	WHEN OTHERS
	THEN
	DBMS_OUTPUT.PUT_LINE('Error Code: '|| SQLCODE);
	DBMS_OUTPUT.PUT_LINE('Error Mesg: '|| SQLERRM);
END;
.
/
spool off;
exit
