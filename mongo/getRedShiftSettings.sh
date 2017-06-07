#!/usr/local/bin/bash
set -e
#set -x

# Usage for getopts
usage () {
    echo "Usage: $0 -a account"
    echo "Example: $0 -a foobar"
}

while getopts ":a:" opt; do
  case $opt in
    a) _account="$OPTARG";;
    *) usage
       exit 1
       ;;
  esac
done

# Make sure account is set
if [[ ! "${_account}" ]]
then 
   usage
   exit 1
fi

# Queries mongodb to get account informaion and specifically settings
list_settings ()
{
   host='11.1.3.137'
   db='mydb'
   _profile='"foo"'
   _version="true"
   _mongo=$(which mongo);
   exp="db.myapplication.find({account:\"${_account}\", profile:${_profile}, \"version_info.published\": ${_version}},{settings : 1}).pretty();";
   ${_mongo} ${host}/${db} --eval "$exp"
}

list_settings
#set +x
