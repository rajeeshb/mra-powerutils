#!/bin/bash

set -x

if [[ $# != 2 ]]; then
   echo "Usage: ./script.sh <ENV> <DC-COMPONENT>"
   echo "Example: ./deployENV.sh qa11 foo_uploader"
   exit 1
fi 

environment="$1"
roles="$2"
creds=( '-x' 'mydevuser' '-a' 'ec2.local_ipv4' )

# Deploy functions
#deploy() {
#    knife ssh "${creds[@]}" "chef_environment:$environment AND roles:*$roles*"
#    "ps -ef | grep java | grep -v grep; sudo initctl stop datacloud-$roles; sudo chef-client; sleep 30; tail -10 /var/log/appname/$roles.log; sudo initctl list | grep data" 
#}

#deploy_urest() {
#    knife ssh "${creds[@]}" "chef_environment:$environment AND roles:*$roles*" "ps -ef | grep jetty | grep -v grep; sudo service jetty stop; sudo chef-client; sleep 30; tail -1 /var/log/jetty/`date +%Y_%m_%d`.stderrout.log; ps -ef | grep jetty | grep -v grep"
#}
#


# Deploy functions
deploy() {
    knife ssh "${creds[@]}" "chef_environment:$environment AND roles:*$roles*" \
    "ps -ef | grep java | grep -v grep; tail -10 /var/log/appname/$roles.log; sudo initctl list | grep data"
}

deploy_urest() {
    knife ssh "${creds[@]}" "chef_environment:$environment AND roles:*$roles*" \
    "ps -ef | grep jetty | grep -v grep; tail -1 /var/log/jetty/$(date +%Y_%m_%d).stderrout.log;"
}


echo "Deploying $environment:$roles"
if [[ "$2" = "urest" ]]; then
   deploy_urest
else
   deploy
fi

set +x
