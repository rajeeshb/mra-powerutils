#!/usr/local/bin/bash
set -e
#set -x

# Setup colors and color reset
_tput='/usr/bin/tput'
black=$(${_tput} setaf 0)
red=$(${_tput} setaf 1)
green=$(${_tput} setaf 2)
yellow=$(${_tput} setaf 3)
blue=$(${_tput} setaf 4)
magenta=$(${_tput} setaf 5)
cyan=$(${_tput} setaf 6)
white=$(${_tput} setaf 7)
cr=$(${_tput} sgr 0)

# Usage for getopts
usage () {
    echo "Usage: $0 -n <nodeid>"
    echo "Example: $0 -n i-09e982d641e479b90"
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
getNode ()
{
   echo "${green}$(basename knife) node show ${_node}${cr}"
   knife node show ${_node} | egrep 'Node Name|Environment|FQDN|IP|Run List' 
}

# Now call the function
getNode

#set +x
