#!/bin/sh
# Gaby Schwartz 2-may-2005
# for printing reports directly to the printer
# usage: rwrun_prt.sh -Rreport_name -Ffile_name(no path) -z"report parameters" -Pprinter_name
# example: rwrun_prt.sh -Rnt_hatsara.rdf -Fgabyrwclient.pdf -z"p_mispar_zehut=324654532 p_sug_tofes=1" -Pprt_web_pics
RUNTIME="_$$_`date +%y%m%d%H%M%S`"
PROGN=`basename $0`
LANDSCAPE=0
NUMBEROFCOPIES=1
#bas=`echo $2 | cut -f2 -d'F' |cut -f1 -d'.'`
echo DBG: script $PROGN started at `date` > $LOG/$PROGN$RUNTIME.log
    while getopts LN:R:F:U:P:z: VARIABLE
    do
      case $VARIABLE in
		L) $LANDSCAPE=1;;
		N) $NUMBEROFCOPIES="$OPTARG";;
        R) REPORTNAME="$OPTARG";;
        F) FILENAME="$TMPDIR/$OPTARG";;
        P) PRINTERNAME="$OPTARG"
           echo "DBG: PRINTERNAME set to $PRINTERNAME" >> $LOG/$PROGN$RUNTIME.log ;;
        z) OTHERPARAM=$OPTARG
           OVEDID=`echo $OTHERPARAM|cut -d= -f2|cut -d ' ' -f1`
           echo "DBG: OVEDID=$OVEDID" >> $LOG/$PROGN$RUNTIME.log
           SEDCMD="s/_[0-9]*_/_${OVEDID}_/"
           echo "DBG: SEDCMD=$SEDCMD" >> $LOG/$PROGN$RUNTIME.log
           RUNID=`echo $RUNTIME|sed $SEDCMD`
           echo "DBG: RUNID=$RUNID" >> $LOG/$PROGN$RUNTIME.log
           ;;
        ?) ;;
      esac
    done
mv $LOG/$PROGN$RUNTIME.log $LOG/$PROGN$RUNID.log

echo "DBG: About to run the following command at `date`: $ORACLE_HOME/bin/rwclient.sh server=$REPORT_SERVER report=$REPORTNAME destype=file desname=$FILENAME desformat=pdf userid=$ORAUSR/$ORAPAS@$TWO_TASK outputimageformat=jpg ignoremargin=yes batch=yes $OTHERPARAM" >> $LOG/$PROGN$RUNID.log
$ORACLE_HOME/bin/rwclient.sh server=$REPORT_SERVER report="$REPORTNAME" destype=file desname=$FILENAME desformat=pdf userid=$ORAUSR/$ORAPAS@$TWO_TASK outputimageformat=jpg ignoremargin=yes batch=yes $OTHERPARAM
#echo " 222222" >> $LOG/$PROGN$RUNID.log
ret_status=$?
echo "DBG: Finished running that command at `date` with exit status $ret_status" >> $LOG/$PROGN$RUNID.log
## printer specific settings

##   madbekot printer - upper tray
if [ `echo $PRINTERNAME | cut -d_ -f3` = 'olim' ]
then
	echo "DBG: Run /users/util/printPDF.pl -d $FILENAME -p $PRINTERNAME " >> $LOG/$PROGN$RUNID.log
#/users/util/printPDF.pl -d $FILENAME -p $PRINTERNAME -l $LOG/$PROGN$RUNID.log
	/usr/sfw/bin/pdf2ps $FILENAME - | lp -d$PRINTERNAME -o nobanner -
	echo "DBG: Finished running that command at `date` with exit status $? " >> $LOG/$PROGN$RUNID.log
elif [ $LANDSCAPE -eq 1 ]
then
	echo "DBG: Running pdf conversion print with $NUMBEROFCOPIES copies " >> $LOG/$PROGN$RUNID.log
	/usr/sfw/bin/pdf2ps $FILENAME - | lp -n$NUMBEROFCOPIES -d$PRINTERNAME -o nobanner -
## Default settings: lower tray of madbekot or any other printer
else
echo "DBG: About to run the following command at `date`: /usr/bin/acroread -toPostScript < $FILENAME -shrink|lp -d$PRINTERNAME -o nobanner" >> $LOG/$PROGN$RUNID.log
/usr/bin/acroread -toPostScript < $FILENAME -shrink|lp -d"$PRINTERNAME" -o nobanner
##/users/util/printPDF.pl -d $FILENAME -p $PRINTERNAME -l $LOG/$PROGN$RUNID.log

echo "DBG: Finished running that command at `date` with exit status $?" >> $LOG/$PROGN$RUNID.log
## end printer specific settings
fi
#lpstat -o >> $LOG/$PROGN$RUNID.log
chmod 777 $FILENAME

#rm -f $FILENAME