#!/bin/bash

FILE="/path/to/logFile.log"
ERRORS=0
for i in /path/to/servers/list
do
     ssh $i "init 0" > $FILE 2>&1
     STATUS=$?
     ERRORS=$((ERRORS+$STATUS))
done
if [ -s $FILE ]
     then
           cat $FILE | mailx -s "shutdown all with $ERRORS errors" dorond@moia.gov.il
fi
