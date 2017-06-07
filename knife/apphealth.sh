#!/bin/bash

apphealth ()
{
    _knife=$(which knife);
    _grep=$(which grep);
    _cut=$(which cut);
    _tr=$(which tr);
    _cappl=$(which cappl);
    local int="cloud.local_ipv4";
    local result=$(${_knife} search node "chef_environment:development AND roles:myapp" -a ${int} | ${_grep} ${int} | ${_cut} -d":" -f2 | ${_tr} -d " ");
    read -a servers <<< $result;
    echo "Checking ${#servers[@]} servers";
    for i in ${servers[@]};
    do
        echo -n "$i: ";
        echo $(ssh mydevuser@${i} "${_cappl} -s -m5 localhost:8085/myapp_service/health || echo 'Failed'");
    done
}

Echo "Running myapp health check..."
apphealth
