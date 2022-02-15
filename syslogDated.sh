#!/bin/ksh

export PATH="/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin"
export DATEFORMAT=`date +%e-%b-%H:%M`;
export PWD=`pwd`;
export SYSLOGDIR="/var/adm/syslog.dated";

if [ -d $SYSLOGDIR ] ; then 
	echo "$SYSLOGDIR exist";
	mkdir $SYSLOGDIR/$DATEFORMAT;
	ls -l $SYSLOGDIR;
	cd $SYSLOGDIR;
	echo "Working dir is: $PWD";
	ls -l $SYSLOGDIR;
	chmod 0775 $SYSLOGDIR/$DATEFORMAT;
	ls -l $SYSLOGDIR;
	ln -s $SYSLOGDIR/$DATEFORMAT $SYSLOGDIR/tmp;
	ls -l $SYSLOGDIR;
	mv $SYSLOGDIR/tmp $SYSLOGDIR/current;
	ls -l $SYSLOGDIR;
else
	echo "$SYSLOGDIR not exist";
fi
