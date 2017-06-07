#!/usr/local/bin/bash

set -e
set -x

#################################
# Slack Help
# http://stackoverflow.com/questions/43805963/how-to-iterate-a-for-loop-and-create-a-customized-string
# !=  => not equal for strings
# -ne => not equal for numbers
# Using (( )) enforces check for numbers


(( $# != 3 )) && echo "Wrong number of arguments" >&2

_subnet=$1
_from=$2
_to=$3
_Output="IPRange.out"

# the numbers are stuffed into an array
for (( i = _from; i <= _to; ++i )); do
    arr+=("\"$_subnet.$i\"") 			#"\" => double quotes the value
done

# Adds comma separation
IFS=,

# How to pull from an array 
# * => all elements in array
echo "${arr[*]}" | tee > "${_Output}"
set +x
