#!/bin/bash

 

#---Variables---#

JBOSS_HOME="/usr/local/jboss"

JBOSS_LOG_FILE="${JBOSS_HOME}/logs/jboss_startup.log"

SHORT_DATE=$(date +"%Y%m%d%H%M")

 

#---Check to see if JBOSS is already running - ensure only one instance---#

JBOSS_RUNNING=$(ps -ef | grep "Djboss.server.base.dir" | grep -v grep | wc -l)

 

if [ $JBOSS_RUNNING -lt 1 ]; then

        #--Check log file size--#

        LOG_FILE_SIZE=$(stat -c %s $JBOSS_LOG_FILE)

        if [ $LOG_FILE_SIZE -ge 50000 ] ; then

          mv $JBOSS_LOG_FILE $JBOSS_LOG_FILE.$SHORT_DATE

        fi

 

        #---Start JBOSS---#

        nohup $JBOSS_HOME/bin/standalone.sh > $JBOSS_LOG_FILE 2> $JBOSS_LOG_FILE &

        if [ $? -ne 0 ]; then

           echo "Error starting JBOSS - $?"

        else

           echo "JBOSS started successfully"

        fi

else

        #---Stop JBOSS---#

        echo "Stopping JBOSS..."

        $JBOSS_HOME/bin/jboss-cli.sh --connect ":shutdown"

fi