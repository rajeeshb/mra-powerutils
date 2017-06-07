#!/usr/local/bin/bash
set -e
set -x

#Text file holds a list of versions
#Use while loop to iterate through each line
accountlist="alist.txt"
while IFS= read -r line
do 
    echo "${line}"
    _account="${line}"

#############
# Functions
#############
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

## Gotchas
# some variables needed single quotes around double quoted vars - i.e. '"vzw"'
# some double quoted values needed an "\" escape


# Pick the function to use
echo "$1"
$1

# End of while looping through versions
done <"$accountlist"

set +x
