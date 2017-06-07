#!/usr/local/bin/bash
set -e
set -x

# Usage for getopts
usage () {
    echo "Usage: $0 -r <us-east-1|eu-central-1|eu-west-1> -s <starting#> -f <ending#>"
    echo "Example: $0 -r us-east-1 -s 16 -f 17"
    exit 1;
}

while getopts ":r:s:f:" o; do
  case "${o}" in
    r) 
	_region=${OPTARG}
	((_region == "us-east-1" || _region == "eu-central-1" || _region == "eu-west-1"))
	;;
    s) 
	_pstart=${OPTARG}
	;;
    f) 
	_pfinish=${OPTARG}
	;;
    *) 
       usage
       ;;
  esac
done
shift $((OPTIND-1))

if [ -z "${_region}" ] ||  [ -z "${_pstart}" ] ||  [ -z "${_pfinish}" ]; then
     usage
fi

echo "r = ${_region}"
echo "s = ${_pstart}"
echo "f = ${_pfinish}"


#############
# Functions
#############
getIP ()
{
   host='10.123.456.789'
   db='appname_cluster_state'
   _mongo=$(which mongo);
   exp="db.appnamecluster_servers.find({\"node_type\":\"APP_PROCESSOR\",\"region\":'${_region}',\"status\":\"ACTIVE\",\$and:[{\"partition_range_start\":{\$lte:${_pstart}}},{\"partition_range_end\":{\$gte:${_pfinish}}}]},{_id:0,node_host:1}).pretty();";
   ${_mongo} ${host}/${db} --eval "$exp"
}

# Now call the function
getIP

set +x
