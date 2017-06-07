#!/usr/local/bin/bash
set -e
set -x

# Usage for getopts
usage () {
    echo "Usage: $0 -r <outputON|outputOFF>"
    echo "Example: $0 -r outputON"
    exit 1;
}

while getopts ":r:" o; do
  case "${o}" in
    r) 
	_results=${OPTARG}
	((_results == "outputON" || _results == "outputOFF" ))
	;;
    *) 
       usage
       ;;
  esac
done
shift $((OPTIND-1))

if [ -z "${_results}" ]; then
     usage
fi

#############
# Functions
#############
outputON ()
{
   host='qa-application-metrics-db.foobar.com'
   _pw='MyPa55W0rd1'
   exp="SELECT * FROM schemaname.tablename where account='mytest' and profile='foobar' order by date desc;";
   time mysql -u admin -p${_pw} -h ${host} -N -e "$exp"
}

outputOFF ()
{
   host1='qa-application-metrics-db.foobar.com'
   host2='application-metrics-db.foobar.com'
   host3='account-usage-metrics.foobar.com'
   _pw1='MyPa55Word1'
   _pw2='MyPa55word2'
   _dt=$(date +'%m-%d-%y %T')
   exp="SELECT * FROM schemaname.tablename where account='mytest' and profile='foobar' order by date desc;";
   echo "$(grep real < <({ time mysql -u admin -p${_pw1} -h ${host1} -N -e "$exp";} 2>&1)):${host1}:${_dt}"
   echo "$(grep real < <({ time mysql -u admin -p${_pw2} -h ${host2} -N -e "$exp";} 2>&1)):${host2}:${_dt}"
   echo "$(grep real < <({ time mysql -u admin -p${_pw2} -h ${host3} -N -e "$exp";} 2>&1)):${host3}:${_dt}"
   #result=$( { time mysql -u admin -p${_pw} -h ${host} -N -e "$exp" >/dev/null; }  2>&1 )
   #echo ${result}":localhost:${_dt}"
}

#### HOW TO TIME A QUERY: 
# Use command "time" or mysql pager
#https://dba.stackexchange.com/questions/72027/query-execution-time-in-mysql 
#http://stackoverflow.com/questions/17257724/grep-time-command-output
#https://www.percona.com/blog/2013/01/21/fun-with-the-mysql-pager-command/

# Now call the function
#echo "r = ${_results}"
${_results}

set +x
