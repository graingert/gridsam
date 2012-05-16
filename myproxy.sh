#!/bin/bash

# Obtain absolute path of this script
GRIDSAM_HOME=$PWD/`dirname "$0"`
cd "$GRIDSAM_HOME"

for j in `ls lib/*.jar`; do
    GS_CLASSPATH=${GS_CLASSPATH}:${j}
done

exec java -classpath "$GS_CLASSPATH:${GRIDSAM_HOME}/conf" \
  -Djava.endorsed.dirs=${GRIDSAM_HOME}/endorsed \
  -Dorg.apache.ws.security.crypto.merlin.file=${GRIDSAM_HOME}/conf/gridsam-default.ks \
  -Dorg.apache.ws.security.crypto.merlin.crldir=${GRIDSAM_HOME}/conf/CRLs \
  -Dlog4j.appender.LOG.File=${GRIDSAM_HOME}/client.log \
  -Djava.util.logging.config.file="${GRIDSAM_HOME}/conf/logging.properties" \
  -Dlog4j.configuration="file://${GRIDSAM_HOME}/conf/log4j.properties" \
  -Daxis.ClientConfigFile="${GRIDSAM_HOME}/conf/client-config.wsdd" \
  -Dgrid.config.dir="${GRIDSAM_HOME}/conf" \
  org.globus.tools.MyProxy $@

