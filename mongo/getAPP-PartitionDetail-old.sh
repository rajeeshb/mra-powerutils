#!/usr/local/bin/bash
set -e
set -x

getPartition ()
{
    _knife=$(which knife);
    _grep=$(which grep);
    _awk=$(which awk);
    cd ~/Documents/path_to_your_chef/.chef
    local result=$(${_knife} search "chef_environment:production AND role:_myapplication_processor AND ec2_region:us-east-1" | ${_grep} IP | ${_awk} '{ print $2 }');
   read -a servers <<< $result; #this is stuff results as single line
   echo "Checking ${#servers[@]} servers";
   for i in ${servers[@]};
   do
       local host='11.1.2.130'
       local db='foobar_cluster_state'
       _mongo=$(which mongo);
       echo -n "$i";
       local exp="db.foobar_servers.find(
       {\"node_host\":\"${i}\",\"node_type\":\"VISITOR_PROCESSOR\",\"region\":\"us-east-1\",\"status\":\"ACTIVE\"},{\"partition_range_start\":1,\"partition_range_end\":1, _id:0}).pretty();"; 
       ${_mongo} ${host}/${db} --eval "$exp" | grep -o -e "{[^}]*}";
  done
}

getPartition
set +x
