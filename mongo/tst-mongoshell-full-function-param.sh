#!/usr/local/bin/bash
set -e
set -x

#Text file holds a list of versions
#Use while loop to iterate through each line
VERSIONS="vlist.txt"
while IFS= read -r line
do 
    echo "$line"
    _version="$line"

#############
# Functions
#############
list_versions ()
{
   host='127.0.0.1'
   db='meldev'
   _account='"foo"'
   _profile='"bar"'
   _mongo=$(which mongo);
   exp="db.profile_versions_20170420.find({account:${_account}, profile:${_profile}, version:${_version}}).pretty();";
   ${_mongo} ${host}/${db} --eval "$exp"
}

unset_versions ()
{
   host='127.0.0.1'
   db='meldev'
   _account='"foo"'
   _profile='"bar"'
   _mongo=$(which mongo);
   exp="db.profile_versions_20170420.update({account:${_account}, profile:${_profile}, version:${_version}},{ \$unset : { labels : true }});";
   ${_mongo} ${host}/${db} --eval "$exp"
}

update_versions ()
{
   host='127.0.0.1'
   db='meldev'
   _account='"foo"'
   _profile='"bar"'
   _mongo=$(which mongo);
   exp="db.profile_versions_20170420.update({account:${_account}, profile:${_profile}, version:${_version}},{ \$set : { labels : { \"1\" : { \"name\" : \"data layer patch\", \"color\" : \"regal-rose\" }, \"2\" : { \"name\" : \"Global Functions\", \"color\" : \"melon-mambo\" }, \"3\" : { \"name\" : \"All Pages\", \"color\" : \"rich-razzelberry\" }, \"4\" : { \"name\" : \"Test & Target\", \"color\" : \"pacific-point\" }, \"5\" : { \"name\" : \"SiteCat\", \"color\" : \"tempting-turquoise\" }, \"6\" : { \"name\" : \"Video Tracking\", \"color\" : \"old-olive\" }, \"7\" : { \"name\" : \"Test & Target\", \"color\" : \"pacific-point\" }}}})";
   ${_mongo} ${host}/${db} --eval "$exp"
}

## Gotchas
# some variables needed single quotes around double quoted vars - i.e. '"foo"'
# some double quoted values needed an "\" escape


# Pick the function to use
echo "$1"
$1

# End of while looping through versions
done <"$VERSIONS"

set +x
