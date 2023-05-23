#!/bin/bash

#export POOL="BDKZONE3app"
#export DATASET="$POOL/bdk3"
export SNAPNUM=2
export POOL="BDKZONE3backup"
export DATASET="$POOL/stam"
export DATE=`date +%s`
export SNAPSHOT_NAME="$DATE.snap"
export ORACLE_SID="dev3_cdb"
export ORACLE_HOME="/oracle/product/19.3.0/dbhome_1"
export BKPDIR="/backup/bin"
export SCRPTDIR="/root/scripts"

get_zpool_size()
{
        ZPOOL=$1
        SIZE=`zpool list $ZPOOL | awk '{print $5}' | grep -v CAP`
        SIZE=$(echo "$SIZE" | sed 's/%//')
        if [[ $SIZE -lt 80 ]]
        then
                echo "Size does not exceed 80%"
                return 0
        elif [[ $SIZE -lt 90 ]]
        then
                echo "Size does not exceed 90%"
                return 1
        else
    echo "I can't create zfs snapshot when zpool is over 90%"
                return 2
        fi
}

del_snaps()
{
  INDEX=$1
  output=`zfs list -t snapshot | grep "$DATASET"`
  snapshots=()
  echo "INDEX: $INDEX"
  while IFS= read -r line; do
    IFS=" " read -ra words <<< "$line"
    snapshots+=("${words[0]}")
  done <<< "$output"
  for ((i = 0; i < INDEX; i++)); do
    echo "Element $i: ${snapshots[i]}"
    OUTPUT=`zfs destroy ${snapshots[i]}`
    STAT=$?
    if [[ $STAT -eq 0 ]];then
      echo "ZFS ${snapshots[i]} destroyed successfuly"
      echo "output: $OUTPUT"
    else
      echo "Didn't destory zfs ${snapshots[i]}"
      echo "Ended with exit status: $STAT"
      echo "output: $OUTPUT"
    fi
  done
}

snap_fs()
{
  CURDATE=`date +%s`
  output=`zfs snapshot $DATASET@$CURDATE.snap`
  STAT=$?
  if [[ $STAT -gt 0 ]];then
    echo "DATASET $DATASET snapshot ended unsuccessfully"
    echo "With exit status $STAT"
    return 1
  else
    echo "DATASET $DATASET snapshot ended successfully"
    return 0
  fi
}

check_backup()
{
        su - oracle -c "$ORACLE_HOME/bin/sqlplus -s '/ as sysdba' @${BKPDIR}/CheckBackupMode.sql" > ${SCRPTDIR}/CheckBackupMode.log
        if [[ $? -gt 0 ]]
        then
                echo "Error running CheckBackupMode.sql"
                #mail_subject $ERROR
                exit 1;
        fi
}

begin_backup()
{
        echo "... run BeginHourlyBkp.sql ..."
        su - oracle -c "$ORACLE_HOME/bin/sqlplus -s '/ as sysdba' @${BKPDIR}/BeginHourlyBkp.sql" > ${SCRPTDIR}/BeginHourlyBkp.log
        if [ $? -gt 0 ]
        then
                echo "Error running BeginHourlyBackup.sql"
                #mail_subject $ERROR
                exit 1;
        fi

        echo "... validate BeginHourlyBkp.log ..."
        cat ${SCRPTDIR}/BeginHourlyBkp.log
        num_err=`grep "ORA-" BeginHourlyBkp.log | wc -l`
        if [ $num_err -gt 0 ]
        then
                echo "$num_err Oracle Errors occurred when run BeginHourlyBkp.sql file \n"
                #mail_subject $ERROR
                exit 1;
        fi
}

end_backup()
{
        su - oracle -c "$ORACLE_HOME/bin/sqlplus -s '/ as sysdba' @${BKPDIR}/EndHourlyBkp.sql" > ${SCRPTDIR}/EndHourlyBkp.log
        if [ $? -gt 0 ]
        then
                echo "Errors during sqlplus EndHourlyBkp.sql"
                #mail_subject $ERROR
                exit 1;
        fi

        echo "... validate EndHourlyBkp.log ..."
        cat ${SCRPTDIR}/EndHourlyBkp.log
        num_err=`grep "ORA-" ${SCRPTDIR}/EndHourlyBkp.log | wc -l`
        if [ $num_err -gt 0 ]
        then
                echo "$num_err Oracle Errors occurred when run EndHourlyBkp.sql file \n"
                #mail_subject $ERROR
                exit 1;
        fi
}

chk_bkp_log()
{
  MSG=$1
  grep $MSG ${SCRPTDIR}/CheckBackupMode.log > /dev/null
  if [[ $? -gt 0 ]]
  then
    if [[ $MSG = "WARNING" ]]
    then
      echo "WARNING - Database currently is in backup mode"
      exit 1
    elif [[ $MSG = "OK" ]]
    then
      echo "WARNING - Database currently is NOT in backup mode"
      exit 1
    fi
  else
    if [[ $MSG = "WARNING" ]]
    then
      echo "OK - Database currently is NOT in backup mode"
    elif [[ $MSG = "OK" ]]
    then
      echo "OK - Database currently is in backup mode"
    fi
  fi
}

if [[ -f ${BKPDIR}/CheckBackupMode.sql ]] && [[ -f ${BKPDIR}/BeginHourlyBkp.sql ]] && [[ -f ${BKPDIR}/EndHourlyBkp.sql ]]
then
        echo "Trying check backup mode"
        check_backup
else
        echo "Missing sql file"
        exit 2
fi

if [[ -f ${SCRPTDIR}/CheckBackupMode.log ]]
then
  chk_bkp_log "WARNING"
        get_zpool_size $POOL
        STATUS=$?
  echo "STATUS: $STATUS"
        QTY=`zfs list -t snapshot | grep "$DATASET" | wc -l`
  if [[ $STATUS -eq 0 ]];then
    echo "zfs delete snapshots except $SNAPNUM"
    if [[ $QTY -gt $SNAPNUM ]];then
      QTY=$((QTY - SNAPNUM))
      del_snaps $QTY
    fi
  elif [[ $STATUS -ge 1 ]];then
    echo "zfs delete all snapshots"
    del_snaps $QTY
    if [[ $STATUS -eq 2 ]];then
      echo "after deleting all snapshots check if zpool space reduced"
      get_zpool_size $POOL
      STATE=$?
      if [[ $STATE -eq 2 ]];then
        echo "Sorry can't continue free some space from $POOL"
        exit 2
      fi
  fi
  else
      echo "Space freed less than 90%, generate zfs snapshot"
  fi
else
        echo "For some reason ${SCRPTDIR}/CheckBackupMode.log does not exist"
        exit 2
fi
begin_backup
check_backup
chk_bkp_log "OK"
snap_fs
EXIT=$?
end_backup
check_backup
if [[ $EXIT -gt 0 ]]; then
  exit $EXIT
fi
chk_bkp_log "WARNING"
