#!/usr/local/bin/bash
set -e
set -x

host='127.0.0.1'
db='meldev'
_account='"foo"'
_profile='"bar"'
_version=$1
_mongo=$(which mongo);
exp="db.profile_versions_20170420.find({account:${_account}, profile:${_profile}, version:${_version}}).pretty();";
${_mongo} ${host}/${db} --eval "$exp"

set +x
