#!/usr/local/bin/bash

set -e
set -x
if [[ $# != 3 ]]; then
   echo "Usage:   ./crIPRange.sh <octet> <start#> <ending#>" 2>&1
   echo "Example: ./crIPRange.sh 10.1.2 100 150" 2>&1
   exit 1
fi

_octet="$1"
_startIP="$2"
_IPList="IPList.out"
_IPListFinal="IPList2.out"

for (( c=$2; c<=$3; c++ ))
do
  echo "${_octet}.$c" | tee >> ${_IPList}
  #awk -v ORS=, '{ print $1 }' ${_IPList} | sed 's/,$//' | tee > ${_IPListFinal} 
  sed -E 's/^(.*)$/"\1"/' ${_IPList} | sed -e ':a' -e 'N' -e '$!ba' -e 's/\n/,/g' |  tee > ${_IPListFinal} 
  #awk -v ORS=, '{ print $1 }' ${_IPList} | sed 's/^/"/,$/"/' | tee > ${_IPListFinal} 
done
set +x
