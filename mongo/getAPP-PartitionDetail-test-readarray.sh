#!/usr/local/bin/bash
set -x
demo() {
        #Hardcode a list of IPs to test
        local result='10.11.3.34
        10.11.2.191
        10.11.3.54
        10.11.4.150
        10.11.3.249
        10.11.2.197'

        #Playing around with readarray or read to iterate through list of IPs
        #  readarray -t servers < <($result); #read lines from a file into an array variable, rather than stopping after the first line
        #  read -a servers <<< $result        #problematic for me initially, stopped and read only first variable
        read -d '' -a servers <<< $result     #works as it uses delimiter of whitespace
        
        echo "Checking ${#servers[@]} servers";
        for i in ${servers[@]}; 
           do
           local host='10.111.2.130'
           local db='myapplication_foobar_state'
           _mongo=$(which mongo);
           local exp="db.myapplicationfoobar_servers.find(
           {\"node_host\":\"${i}\",\"node_type\":\"YOUR_APPNAME\",\"region\":\"us-east-1\",\"status\":\"ACTIVE\"},{\"partition_range_start\":1,\"partition_range_end\":1, _id:0}).pretty();";

           # Store output of mongo command in variable
           output=$(${_mongo} ${host}/${db} --eval "$exp" | grep -o -e "{[^}]*}")

           # Print {} if output variable is empty
           echo "${i}:${output:- {}}"
        done
}
set +x

demo | sort -nk4
