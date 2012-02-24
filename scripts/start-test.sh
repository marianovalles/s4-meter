#!/bin/bash
# The script generates events using two event generators
E_BADARGS=65
logs=logs
#FIXME Ugly hardcoded paths
S4_IMAGE="/home/valles/programming/s4/build/s4-image"
S4_METER="/home/valles/programming/s4-meter-fork/"
if [ ! -n "$1" ]
then
  echo "Usage: `basename $0` eventrate 1|0(recompile)"
  echo "e.g. `basename $0 100 1`"
  exit $E_BADARGS
fi  
# Clean locks and logs
rm -rf $S4_IMAGE/s4-core/locks/*
rm -rf $S4_IMAGE/s4-core/logs/s4-core/*
rm $logs/*

# Clean deployed apps directory
rm -rf $S4_IMAGE/s4-apps/*

#Find and replace according to the param
sed -i "s/generator.eventRate.*/generator.eventRate\ =\ "$1"/g" s4-meter-controller/src/main/resources/s4-meter.properties

#Reinstall and redeploy 
./gradlew install
./gradlew deploy

#Scripts to start the s4-meter from github.com/leoneu/s4-meter
# Start S4 server.
nohup $S4_IMAGE/scripts/start-s4.sh -r client-adapter > $logs/s4-server.err & 

# Start S4 client adapter server.
#nohup $S4_IMAGE/scripts/run-client-adapter.sh -s client-adapter \
-g s4 -x -d $S4_IMAGE/s4-core/conf/default/client-stub-conf.xml > $logs/s4-client-adapter &

# Start a generator listening on port 8182.
nohup $S4_METER/s4-meter-generator/build/install/s4-meter-generator/bin/s4-meter-generator 8182 > $logs/generator8182.err &

# Start a generator listening on port 8183.
nohup $S4_METER/s4-meter-generator/build/install/s4-meter-generator/bin/s4-meter-generator 8183 > $logs/generator8183 &

# Start the controller.
nohup $S4_METER/s4-meter-controller/build/install/s4-meter-controller/bin/s4-meter-controller > $logs/controller &
