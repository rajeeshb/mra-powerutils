#!/usr/bin/env bash

#set -x
cluster="$1"

#Where .keyinfo2:
#us-east#1-3#myPa55word2
KEY=./.keyinfo2

while IFS=# read -r  region clnbr pw; do
if [[ "${region}-${clnbr}" == ${cluster} ]]; then
    echo "We have a match"
    echo "Password is ${pw}"
 else
    echo "No match"
fi
done < "$KEY"

#set +x
