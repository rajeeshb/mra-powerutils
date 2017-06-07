#!/bin/bash

set -x

if [[ $# != 2 ]]; then
   echo "Usage: ./script.sh <ENV> <DC-COMPONENT>"
   exit 1
fi 

# Avoid CAPS on all vars to avoid environment variables 
# and special shell variables
#ENVIRONMENT="$1"
#ROLES="$2"
environment="$1"
roles="$2"

# This doesn't work:
#CREDS="-x mydevuser -a ec2.local_ipv4"
# This does:
# Store args. individually as array elements
#CREDS=( '-x' 'mydevuser' '-a' 'ec2.local_ipv4' )
creds=( '-x' 'mydevuser' '-a' 'ec2.local_ipv4' )


# "${CREDS[@]}" passes the elements of the array safely as *individual* arguments.
#function deploy {
#    knife ssh "${CREDS[@]}" "chef_environment:$ENVIRONMENT AND roles:*$ROLES*" "uname"
#}

# Remove "function" in front of function name for portability
deploy() {
    knife ssh "${creds[@]}" "chef_environment:$environment AND roles:*$roles*" "uname"
}

echo "Test 1"
deploy

echo "Test 2"
knife ssh "${creds[@]}" "chef_environment:$environment AND roles:*"$roles"*" "uname"

echo "Test 3"
knife ssh -x mydevuser -a ec2.local_ipv4 "chef_environment:tmu02 AND roles:*service_processor*" "uname"

set +x
