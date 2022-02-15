#!/bin/bash

ORACLE_HOME=/oracle/product/11.2.0/dbhome_1; export ORACLE_HOME;
ORACLE_SID=dev1; export ORACLE_SID

srcloc=$HOME/admin/prod2/script; export srcloc;

su - oracle -c "${ORACLE_HOME}/bin/sqlplus -s '/ as sysdba'" <<EOF
set serveroutput on
set trimspool on
set line 500
set head off
set feed off
set echo off
set ver off

spool $srcloc/RunEndHotBackup.sql

begin

  dbms_output.put_line('spool $srcloc/RunEndHotBackup.log');
  dbms_output.put_line('alter database end backup;');
  dbms_output.put_line('alter system switch logfile;');
  dbms_output.put_line('spool off');
end;
/

spool off

set head on
set feed on
set serveroutput off

-- Unremark/uncomment the following line to run the backup script
@$srcloc/RunEndHotBackup.sql
exit
EOF