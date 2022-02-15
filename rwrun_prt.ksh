#!/bin/sh
# Doron Dollev 19-07-2021
# Gaby Schwartz 2-may-2005
# for printing reports directly to the printer
# usage: rwrun_prt.sh -Rreport_name -Ffile_name(no path) -z"report parameters" -Pprinter_name
# example: rwrun_prt.sh -Rnt_hatsara.rdf -Fgabyrwclient.pdf -z"p_mispar_zehut=324654532 p_sug_tofes=1" -Pprt_web_pics
RUNTIME="_$$_`date +%y%m%d%H%M%S`"
PROGN=`basename $0`

#bas=`echo $2 | cut -f2 -d'F' |cut -f1 -d'.'`
echo DBG: script $PROGN started at `date` > $LOG/$PROGN$RUNTIME.log
    while getopts R:F:U:P:z: VARIABLE
    do
      case $VARIABLE in
        R) REPORTNAME="$OPTARG";;
        F) FILENAME="$TMPDIR/$OPTARG";;
        P) PRINTERNAME="$OPTARG"
           echo DBG: PRINTERNAME set to $PRINTERNAME >> $LOG/$PROGN$RUNTIME.log ;;
        z) OTHERPARAM=$OPTARG
           OVEDID=`echo $OTHERPARAM|cut -d= -f2|cut -d ' ' -f1`
           echo DBG: OVEDID=$OVEDID >> $LOG/$PROGN$RUNTIME.log
           SEDCMD="s/_[0-9]*_/_${OVEDID}_/"
           echo DBG: SEDCMD=$SEDCMD >> $LOG/$PROGN$RUNTIME.log
           RUNID=`echo $RUNTIME|sed $SEDCMD`
           echo DBG: RUNID=$RUNID >> $LOG/$PROGN$RUNTIME.log
           ;;
        ?) ;;
      esac
    done
mv $LOG/$PROGN$RUNTIME.log $LOG/$PROGN$RUNID.log

echo "DBG: About to run the following command at `date`: $DOMAIN_HOME/reports/bin/rwclient.sh server=$REPORT_SERVER report=$REPORTNAME destype=file desname=$FILENAME desformat=pdf userid=$ORAUSR/$ORAPAS@$TWO_TASK outputimageformat=jpeg ignoremargin=yes batch=yes $OTHERPARAM" >> $LOG/$PROGN$RUNTIME.log
$DOMAIN_HOME/reports/bin/rwclient.sh server=$REPORT_SERVER report="$REPORTNAME" destype=file desname=$FILENAME desformat=pdf userid=$ORAUSR/$ORAPAS@$TWO_TASK outputimageformat=jpeg ignoremargin=yes batch=yes $OTHERPARAM

#ORACLE_HOME=/oracle/product/Middleware/as_1; export ORACLE_HOME

#echo "DBG: About to run the following command at `date`:
#$ORACLE_HOME/bin/rwclient.sh server=$REPORT_SERVER report=$REPORTNAME destype=file desname=$FILENAME desformat=pdf userid=$ORAUSR/$ORAPAS@$TWO_TASK outputimageformat=png ignoremargin=yes batch=yes $OTHERPARAM" >> $LOG/$PROGN$RUNID.log
#$ORACLE_HOME/bin/rwclient.sh server=$REPORT_SERVER report="$REPORTNAME" destype=file desname=$FILENAME desformat=pdf userid=$ORAUSR/$ORAPAS@$TWO_TASK outputimageformat=jpg ignoremargin=yes batch=yes $OTHERPARAM
#echo " 222222" >> $LOG/$PROGN$RUNID.log
ret_status=$?
echo "DBG: Finished running that command at `date` with exit status $ret_status" >> $LOG/$PROGN$RUNID.log
## printer specific settings
echo "DBG: transfering $FILENAME to print server" >> $LOG/$PROGN$RUNID.log;
$FILE=`basename $FILENAME` >> $LOG/$PROGN$RUNID.log;
scp -p $FILE ntpzone1:/tmp >> $LOG/$PROGN$RUNID.log;
##   madbekot printer - upper tray
if [ `echo $PRINTERNAME | cut -d_ -f3` = 'olim' ]
then
echo "DBG: About to run the following command at `date`:
/users/util/printPDF.pl -d $FILE -p $PRINTERNAME " >> $LOG/$PROGN$RUNID.log
##/usr/bin/acroread -toPostScript < $FILENAME | lp -d"$PRINTERNAME"  -o nobanner
ssh ntpzone1 "/users/util/printPDF.pl -d $FILE -p $PRINTERNAME -l" $LOG/$PROGN$RUNID.log
echo "DBG: Finished running that command at `date` with exit status $?" >> $LOG/$PROGN$RUNID.log

## Default settings: lower tray of madbekot or any other printer
else
echo "DBG: About to run the following command at `date`:
/usr/bin/acroread -toPostScript < $FILE -shrink|lp -d$PRINTERNAME -o nobanner" >> $LOG/$PROGN$RUNID.log
ssh ntpzone1 "/usr/bin/acroread -toPostScript < $FILE -shrink|lp -d"$PRINTERNAME" -o nobanner" >> $LOG/$PROGN$RUNID.log
##/users/util/printPDF.pl -d $FILE -p $PRINTERNAME -l $LOG/$PROGN$RUNID.log

echo "DBG: Finished running that command at `date` with exit status $?" >> $LOG/$PROGN$RUNID.log
## end printer specific settings
fi
ssh ntpzone1 "rm -f /tmp/$FILE"
#lpstat -o >> $LOG/$PROGN$RUNID.log
chmod 777 $FILENAME

#rm -f $FILENAME