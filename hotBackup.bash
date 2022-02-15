#!/usr/bin/bash
# /usr/local/backup/bin

PATH=$PATH:/usr/sbin
export PATH

ORACLE_HOME="/oracle/product/11.2.0/dbhome_1"
export ORACLE_HOME

ORACLE_SID=$1
export ORACLE_SID

OK=0
ERROR=1

SRCLOC="/backup/bin"
export SRCLOC

TARGETDIR="/backup/$ORACLE_SID/oradata"
export TARGETDIR

SRCDIR="/oradata/$ORACLE_SID"
export SRCDIR

LOGFILE="/var/adm/syslog.dated/current/${ORACLE_SID}hotBackup.log";
export LOGFILE
touch $LOGFILE

EMAILMESSAGE="/tmp/emailmessage.txt"
export EMAILMESSAGE

FROM=`/usr/xpg4/bin/id -un`
export FROM

echo "To: dorond@moia.gov.il" >$EMAILMESSAGE
echo "From: $FROM" >>$EMAILMESSAGE
echo "Cc: gabbys@moia.gov.il" >>$EMAILMESSAGE

ERASEDATA=(data01 arch01 redo01 redo02)
COPYDATA=(data01 redo01 redo02)

mail_subject()
{
        STATUS=$1
        if [ $STATUS -gt 0 ]
        then
                SUBJECT="oracle $ORACLE_SID hotbackup ended with errors"
        else
                SUBJECT="oracle $ORACLE_SID hotbackup ended successfully"
        fi
        echo "Subject: $SUBJECT" >>$EMAILMESSAGE
        echo "" >>$EMAILMESSAGE
        cat $LOGFILE >>$EMAILMESSAGE
        cat $EMAILMESSAGE | sendmail -t
}

copy_dir()
{
        echo "inside copy_dir"
        DATADIR=$1

        ls -A $SRCDIR/$DATADIR/* >/dev/null 2>&1
        if [ $? -gt 0 ]
        then
                echo "source directory $DATADIR is empty"
                mail_subject $ERROR
                exit 2
        else
                echo "copying $SRCDIR/$DATADIR/* $TARGETDIR/$DATADIR/"
                cp -pr $SRCDIR/$DATADIR/* $TARGETDIR/$DATADIR/
                if [ $? -gt 0 ]
                then
                        echo "errors during copying from $SRCDIR/$DATADIR to $TARGETDIR/$DATADIR"
                        exit 1
                fi
        fi
}

remove_dir_content()
{
        echo "inside remove_dir_content"
        DIR=$1

        if [ -d $SRCDIR/$DIR ]
        then
                rm -rf $DIR/*
                echo "removing content from dir: $DIR"
                if [ $? -gt 0 ]
                then
                        echo "error removing $DIR content"
                        exit 1;
                else
                        echo "$DIR content removed successfully"
                fi
        fi
}

`ps -ef | grep pmon | grep -v grep | grep $ORACLE_SID`
if [ $? -gt 0 ]
then
        print "oracle is down"
        mail_subject $ERROR
        exit 1;
fi

${ORACLE_HOME}/bin/sqlplus -s '/ as sysdba' <<EOF
set feed off
set head off
set pages
select to_char(sysdate,'ddmmyyyy') from dual;
exit
EOF

echo "start Begin Backup in $SRCDIR"
`find $SRCDIR -name "Hotbackup_*.txt" -exec rm -f {} \;`
if [ $? -gt 0 ]
then
        echo "Couldn't remove Hotbackup_*.txt";
fi

$ORACLE_HOME/bin/sqlplus -s '/ as sysdba' @${SRCLOC}/BeginHotBackup.sql
if [ $? -gt 0 ]
then
        echo "Error running BeginHotBackup.sql"
fi

num_err=`grep "ORA-" $LOGFILE | wc -l`

if [ $num_err -gt 0 ]
then
        echo "errors in oracle check log file"
        echo "Ending Backup Mode because of errors..."
        $ORACLE_HOME/bin/sqlplus -s '/ as sysdba' @${SRCLOC}/EndHotBackup.sql
        mail_subject $ERROR
        exit 1;
fi

echo "remove last backup from $TARGETDIR"

if [ -d $TARGETDIR ]
then
        cd $TARGETDIR
        for i in ${ERASEDATA[*]}
        do
                remove_dir_content $i
        done
        `rm -f Hotbackup_*.txt`
else
        echo "$TARGETDIR not found"
        mail_subject $ERROR
        exit 1;
fi

for j in ${COPYDATA[*]}
do
        echo "copy $SRCDIR/$j to $TARGETDIR/$j"
        copy_dir $j
done

echo "start End Backup Mode"
$ORACLE_HOME/bin/sqlplus -s '/ as sysdba' @${SRCLOC}/EndHotBackup.sql
if [ $? -gt 0 ]
then
        echo "errors during sqlplus EndHotBackup.sql"
fi

`find $SRCDIR/arch01 -type f -mtime 0 -exec cp -p {} $TARGETDIR/arch01/ \;`

if [ -e $SRCLOC/${ORACLE_SID}Last_Arch.log ]
then
        LASTARCHNUM=`perl -nlwe 'tr/ //d; print if length' $SRCLOC/${ORACLE_SID}Last_Arch.log`
        mv $SRCLOC/${ORACLE_SID}Last_Arch.log $SRCLOC/${ORACLE_SID}Last_Arch.erase
        if [ -z $LASTARCHNUM ]
        then
                echo "last archive string not found"
                mail_subject $ERROR
                exit 1
        else
                echo "copying last archive log from $SRCDIR/arch01/ to $TARGETDIR/arch01/..."
                `find $SRCDIR/arch01 -name "*$LASTARCHNUM*" -exec cp -p {} $TARGETDIR/arch01/ \;`
                if [ $? -eq 0 ]
                then
                        echo "done"
                        mail_subject $OK
                        exit 0
                else
                        echo "errors occured during finding and copying a string file $LASTARCHNUM"
                        mail_subject $ERROR
                        exit 1
                fi
        fi
else
        echo "Last_Arch.log file: $SRCLOC/${ORACLE_SID}Last_Arch.log Not found"
        mail_subject $ERROR
        exit 1
fi