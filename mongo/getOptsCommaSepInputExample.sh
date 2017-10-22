#!/usr/local/bin/bash
set -e
set -x

# Usage for getopts
usage () {
    echo "Usage: $0 -m <find|add> -a <accountname> -i <10.10.123.456,10.10.123.457>"
    echo "Example: $0 -m find -a dominos"
    echo "Example: $0 -m add -a dominos -i 10.10.123.456"
    echo "=OR= (for more than one IP)"
    echo "Example: $0 -m add -a dominos -i 10.10.123.456,10.10.123.457"
    exit 1;
}

while getopts ":m:a:i:" o; do
  case "${o}" in
    m) 
	_mode=${OPTARG}
         if [[ "${_mode}" != find && "${_mode}" != add ]]; then
        usage
        fi
	;;
    a) 
	_account=${OPTARG}
	;;
    i) 
        _ip=${OPTARG}
	;;
    *) 
       usage
       ;;
  esac
done
shift $((OPTIND-1))


#############
# Functions
#############

getWhitelist ()
{
   host='127.0.0.1'
   db='meldev'
   _mongo=$(which mongo);
   exp="db.account_ip_whitelists_20170817.find({\"account\":'${_account}'},{ip_list: 1}).pretty();";
   ${_mongo} ${host}/${db} --eval "$exp"
}

# Read a list
# use "printf" to handle comma separated list
addToWhitelist ()
{
   host='127.0.0.1'
   db='meldev'
   _mongo=$(which mongo);
   echo "${_ip}";
   IFS=, read -a arr <<<"${_ip}"
   printf -v ips ',"%s"' "${arr[@]}"
   ips="${ips:1}" 
   exp="db.account_ip_whitelists_20170817.update({'account':'${_account}'},{\$addToSet:{'ip_list': {\$each:[$ips]}}})";
   "${_mongo}" "${host}/${db}" --eval "$exp"
}


case "${_mode}" in
  'find')
      echo "Finding information for the account ${_account}"
      getWhitelist
      ;;
  'add') 
      echo "Adding the following IP: ${_ip}"
      addToWhitelist
      ;;
esac

set +x
