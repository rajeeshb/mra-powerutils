#!/usr/local/bin/bash
#set -x
cluster="$1"

#Where .keyinfo2: 
#us-east#1-3#myPa55word2
KEY=./.keyinfo2


ret=0
while IFS='#' read -r region clnmbr pw; do
   if [[ ${region}-${clnmbr} == "$cluster" ]]; then
    echo "We have a match"
 else
    echo "No match"
    ret=1
fi
done < "$KEY"

exit $ret
#set +x
