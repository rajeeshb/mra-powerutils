#!/usr/local/bin/bash

set -x


#Sample .keyinfo
#  us-east#1#Pa55w0rd1
#  eu-west#2#Change!mE

while IFS=# read -r region clnmbr pw; do
  getCount()
    {
     mycount=$(PGPASSWORD=${pw} psql -h hostname-${region}-1-${clnmbr}.mydomian.com -U masteruser -d dev -p 5439 -t -c "select count(datname) from pg_database;")
    }
  getCount
done < ".keyinfo"

set +x
