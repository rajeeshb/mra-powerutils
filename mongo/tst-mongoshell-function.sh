#!/usr/local/bin/bash

list_versions ()
{
    host='127.0.0.1';
    db='meldev';
    _mongo=$(which mongo);
    ${_mongo} ${host}/${db} --eval 'db.profile_versions_20170420.findOne()'
}

list_versions
