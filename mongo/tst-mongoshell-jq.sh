#!/usr/local/bin/bash
set -e
set -x

host='127.0.0.1'
db='meldev'
_account="foo"
_profile="bar"
_version=$1

json=$(jq -n --arg account "$_account" --arg profile "$_profile" --arg version "$_version" \
  '{account: $account, profile: $profile, version: $version | tonumber}')

exp="db.profile_versions_20170420.find($json).pretty();"
mongo "${host}/${db}" --eval "$exp"
