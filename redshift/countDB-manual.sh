#!/bin/bash

#US-East
echo "cluster1"
PGPASSWORD=PassWord1 psql -h hostname1.us-east-1.redshift.amazonaws.com -U masteruser -d dev -p 5439 -f getDBCount.sql
echo "cluster2"
PGPASSWORD=PassWord2 psql -h hostname2.us-east-1.redshift.amazonaws.com -U masteruser -d dev -p 5439 -f getDBCount.sql

#getDBCount.sql
#select count(datname) from pg_database;
