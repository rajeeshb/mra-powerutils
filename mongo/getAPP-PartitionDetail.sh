#!/usr/local/bin/bash
set -e
#set -x

getPartition ()
{
    _knife=$(which knife);
    _grep=$(which grep);
    _awk=$(which awk);
    _sort=$(which sort);
    cd ~/Documents/your_path_to_chef/.chef

    # Get a list of IPs using knife search and using readarray 
    # -t Remove any trailing newline from a line read, before it is assigned to an array element
    readarray -t servers < <(
       ${_knife} search "chef_environment:production AND role:myapp_processor AND ec2_region:us-east-1" | ${_grep} IP | ${_awk} '{ print $2 }');
    #echo "Checking ${#servers[@]} servers";
   for i in ${servers[@]};
      do
        local host='11.1.2.150'
        local db='myapplication_foobar_state'
        _mongo=$(which mongo);
        local exp="db.myapplicationfoobar_servers.find(
        {\"node_host\":\"${i}\",\"node_type\":\"YOUR_APPNAME\",\"region\":\"us-east-1\",\"status\":\"ACTIVE\"},{\"partition_range_start\":1,\"partition_range_end\":1, _id:0}).pretty();";

        # Store mongo command in output 
        output=$(${_mongo} ${host}/${db} --eval "$exp" | ${_grep} -o -e "{[^}]*}")

        # Format the output and place empty brackets if NO data exists {}
        echo "${i}:${output:- {}}"
     done
}

# Sort the output on partition_range_start key
getPartition | sort -nk4

#set +x
