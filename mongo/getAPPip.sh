#!/usr/local/bin/bash
set -e
set -x

_region=$1
_pstart=$2
_pfinish=$3

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
