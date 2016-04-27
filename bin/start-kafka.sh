#!/bin/bash

#echo "--- env ----" && env
echo "*************"
echo "KAFKA_ZOOKEEPER_CONNECT=$KAFKA_ZOOKEEPER_CONNECT"
echo "KAFKA_ADVERTISED_HOST_NAME=$KAFKA_ADVERTISED_HOST_NAME"

if [[ -z "$KAFKA_PORT" ]]; then
    export KAFKA_PORT=9092
fi
echo "KAFKA_PORT $KAFKA_PORT"

if [[ -z "$KAFKA_ADVERTISED_PORT" ]]; then
    export KAFKA_ADVERTISED_PORT=$(docker port `hostname` $KAFKA_PORT | sed -r "s/.*:(.*)/\1/g")
fi
echo "KAFKA_ADVERTISED_PORT $KAFKA_ADVERTISED_PORT"

if [[ -z "$KAFKA_BROKER_ID" ]]; then
    # By default auto allocate broker ID
    export KAFKA_BROKER_ID=-1
fi
echo "KAFKA_BROKER_ID $KAFKA_BROKER_ID"

if [[ -z "$KAFKA_LOG_DIRS" ]]; then
    export KAFKA_LOG_DIRS="/kafka/kafka-logs-$HOSTNAME"
fi
echo "KAFKA_LOG_DIRS $KAFKA_LOG_DIRS"

if [[ -z "$KAFKA_ZOOKEEPER_CONNECT" ]]; then
    export KAFKA_ZOOKEEPER_CONNECT=$(docker ps --filter 'label=com.docker.compose.service=zookeeper' --format '{{.Names}}' | awk '{{printf "%s:2181\n", $1}}' | paste -sd ,)
fi
echo "KAFKA_ZOOKEEPER_CONNECT $KAFKA_ZOOKEEPER_CONNECT"

echo "KAFKA_HEAP_OPTS $KAFKA_HEAP_OPTS"
if [[ -n "$KAFKA_HEAP_OPTS" ]]; then
    sed -r -i "s/(export KAFKA_HEAP_OPTS)=\"(.*)\"/\1=\"$KAFKA_HEAP_OPTS\"/g" $KAFKA_HOME/bin/kafka-server-start.sh
    unset KAFKA_HEAP_OPTS
fi

if [[ -z "$KAFKA_ADVERTISED_HOST_NAME" && -n "$HOSTNAME_COMMAND" ]]; then
    export KAFKA_ADVERTISED_HOST_NAME=$(eval $HOSTNAME_COMMAND)
fi

echo "*************"
echo "KAFKA_ZOOKEEPER_CONNECT=$KAFKA_ZOOKEEPER_CONNECT"
echo "KAFKA_ADVERTISED_HOST_NAME=$KAFKA_ADVERTISED_HOST_NAME"

#echo "--- env ----" && env

for VAR in `env`
do
  if [[ $VAR =~ ^KAFKA_ && ! $VAR =~ ^KAFKA_HOME ]]; then
    kafka_name=`echo "$VAR" | sed -r "s/KAFKA_(.*)=.*/\1/g" | tr '[:upper:]' '[:lower:]' | tr _ .`
    env_var=`echo "$VAR" | sed -r "s/(.*)=.*/\1/g"`
    if egrep -q "(^|^#)$kafka_name=" $KAFKA_HOME/config/server.properties; then
        sed -r -i "s@(^|^#)($kafka_name)=(.*)@\2=${!env_var}@g" $KAFKA_HOME/config/server.properties #note that no config values may contain an '@' char
    else
        echo "$kafka_name=${!env_var}" >> $KAFKA_HOME/config/server.properties
    fi
  fi
done

# Capture kill requests to stop properly
trap "$KAFKA_HOME/bin/kafka-server-stop.sh; echo 'Kafka stopped.'; exit" SIGHUP SIGINT SIGTERM

create-topics.sh & 
$KAFKA_HOME/bin/kafka-server-start.sh $KAFKA_HOME/config/server.properties
