#!/usr/local/bin/bash
set -e
#set -x

# Usage for getopts
usage () {
    echo "Usage: $0 -n <nodeid>"
    echo "Example: $0 -n i-09z12341e479b90"
    exit 1;
}

while getopts ":n:" o; do
  case "${o}" in
    n) 
	_node=${OPTARG}
	;;
    *) 
       usage
       ;;
  esac
done
shift $((OPTIND-1))

if [ -z "${_node}" ]; then
     usage
fi

#############
# Functions
#############
getIP ()
{
   knife node show i-${_node} | egrep 'IP'
}

# Now call the function
getIP

#set +x
