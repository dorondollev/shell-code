#!/bin/bash

ORACLE_HOME=/oracle/product/11.2.0/dbhome_1; export ORACLE_HOME;
ORACLE_SID=dev1; export ORACLE_SID

srcloc=/backup/sbin; export srcloc;

su - oracle -c "${ORACLE_HOME}/bin/sqlplus -s '/ as sysdba'" <<EOF
set feed off
set head off
set echo off
set ver off
set pages
spool ${srcloc}/RunBeginHotBackup.sql

declare

  vdate   varchar2(8);

begin

  select to_char(sysdate,'ddmmyyyy')
    into vdate
   from dual;

  dbms_output.put_line('spool ${srcloc}/RunBeginHotBackup.log');
-- $oradata = /oradata/instance_name/data01
  dbms_output.put_line('alter database backup controlfile to trace as '||chr(39)||'$oradata/Hotbackup_'||vdate||'_ctl_prod2.txt'||chr(39)||';');
  dbms_output.put_line('alter database begin backup;');
  dbms_output.put_line('spool off');
end;
/


spool off

set head on
set feed on
set serveroutput off

-- Unremark/uncomment the following line to run the backup script
@${srcloc}/RunBeginHotBackup.sql
exit
EOF