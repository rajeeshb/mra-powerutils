#!/usr/bin/ksh

delay=5
pid=$1
cmd=$2
usage=0;

if [ "$pid" == "" ] then
usage=1;
echo "PID is required"
fi

if [ "$cmd" == "" ] then
usage=1;
echo "COMMAND is required"
fi

if [ "$usage" == "1" ] then
echo "usage: waitforpid.sh PID COMMAND"
echo " where"
echo " PID = Process id to wait for"
echo " COMMAND = Command to be executed after it completes"
exit
fi

#Redirect stdout and stderr of the ps command to /dev/null ps -p$pid 2>&1 > /dev/null
#Grab the status of the ps command status=$?

#A value of 0 means that it was found running if [ "$status" == "0" ]
#then
while [ "$status" == "0" ]
do
sleep $delay
ps -p$pid 2>&1 > /dev/null
status=$?
done

#The process has started, do something here echo $cmd
$cmd

#A value of non-0 means that it as NOT found running 
else
echo "Process with pid $pid is not running"
fi
