#!/bin/bash

apphealth ()
{
    _knife=$(which knife);
    _grep=$(which grep);
    _cut=$(which cut);
    _tr=$(which tr);
    _curl=$(which curl);
    local int="cloud.local_ipv4";
    cd ~/Documents/mydev/.chef
    local result=$(${_knife} search node "chef_environment:development AND roles:mydev_service AND ec2_region:us-east-1" -a ${int} | ${_grep} ${int} | ${_cut} -d":" -f2 | ${_tr} -d " ");
    read -a servers <<< $result;
    echo "Checking ${#servers[@]} servers";
    for i in ${servers[@]};
    do
        echo -n "$i: ";
        echo $(${_curl} -s -m15 ${i}:8085/health || echo "Failed");
    done
}

echo "Running FooBar Service Health Check..."; date; 
vshealth
