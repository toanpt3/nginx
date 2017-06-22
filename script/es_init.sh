#! /bin/bash
# toanpt3
# script run ES daemon
	USER=zdeploy          # User run elasticsearch (not root)
	JAVA_HOME=/zserver/java/bin/java  # Where java lives
	### Configurable settings
	NAME=es_ZOA # Project na,e
	ES_HOME=/zserver/java-projects/es_ZOA
	PID_FILE=$ES_HOME/${NAME}.pid
	LOG_DIR=/data/es_ZOA/log
	DATA_DIR=/data/es_ZOA/data
	CONFIG_FILE=$ES_HOME/config/elasticsearch.yml
	## Config Min, Max memory
	ES_MIN_MEM=256m 
	ES_MAX_MEM=1g
	WORK_DIR=/tmp/$NAME
	DAEMON=$ES_HOME/bin/elasticsearch
	DAEMON_OPTS=""

##### END CONFIG
if [ -x /etc/init.d/functions ]; then source /etc/init.d/functions; fi
# Check exec
if [ ! -x $DAEMON ]; then
  echo 'Could not find elasticsearch executable!'
  exit 0
fi
set -e
case "$1" in
  start)
    echo -n "Starting $NAME: "
    mkdir -p $LOG_DIR $DATA_DIR $WORK_DIR
    chown -R $USER:$USER $LOG_DIR $DATA_DIR $WORK_DIR
    if type -p start-stop-daemon > /dev/null; then
      start-stop-daemon --start --pidfile $PID_FILE --user $USER --chuid $USER --startas $DAEMON --pidfile /data/es.pid $DAEMON_OPTS
    else
      runuser -s /bin/bash $USER -c "$DAEMON -d -p $PID_FILE $DAEMON_OPTS"
	#runuser -s /bin/bash $USER -c "$DAEMON $DAEMON_OPTS"
      #daemon --pidfile $PID_FILE --user $USER $DAEMON $DAEMON_OPTS
    fi
    if [ $? == 0 ]
    then
        echo "started."
    else
        echo "failed."
    fi
    ;;
  stop)
    if [ ! -e $PID_FILE ]; then
      echo "$NAME not running (no PID file)"
    else
      echo -n "Stopping $NAME: "
      if type -p start-stop-daemon > /dev/null; then
        start-stop-daemon --stop --pidfile $PID_FILE
      else
        kill $(cat $PID_FILE)
        rm $PID_FILE
      fi
      if [ $? == 0 ]
      then
          echo "stopped."
      else
          echo "failed."
      fi
    fi
    ;;
  restart|force-reload)
    ${0} stop
    sleep 0.5
    ${0} start
    ;;
  status)
    if [ ! -f $PID_FILE ]; then
      echo "$NAME not running"
    else
      if ps auxw | grep $(cat $PID_FILE) | grep -v grep > /dev/null; then
        echo "running on pid $(cat $PID_FILE)"
      else
        echo 'not running (but PID file exists)'
      fi
    fi
    ;;
  *)
    N=/etc/init.d/$NAME
    echo "Usage: $N {start|stop|restart|force-reload|status}" >&2
    exit 1
    ;;
esac

exit 0