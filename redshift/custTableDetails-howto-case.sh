#!/usr/local/bin/bash

set -e
set -x

# Function that uses a case statement to check for multitenant redshift clusters
cluster_to_endpoint() {
  case "$cluster" in
  c01)
      RUNCMD=$(PGPASSWORD=foobar#! psql -h mradev-events01.foobar.us-east-1.redshift.amazonaws.com -U masteruser -d dev -p 5439 -f getDBName.sql)
      ;;
  c02)
      RUNCMD=$(PGPASSWORD=foobar#! psql -h mradev-events02.foobar.us-east-1.redshift.amazonaws.com -U masteruser -d dev -p 5439 -f getDBName.sql)
      ;;
  c03)
      RUNCMD=$(PGPASSWORD=foobar#! psql -h mradev-events03.foobar.us-east-1.redshift.amazonaws.com -U masteruser -d dev -p 5439 -f getDBName.sql)
      ;;
  c04)
      RUNCMD=$(PGPASSWORD=foobar#! psql -h mradev-events04.foobar.us-east-1.redshift.amazonaws.com -U masteruser -d dev -p 5439 -f getDBName.sql)
      ;;
  *)
      echo "Cluster alias is not on the current list"
  esac
}


while getopts ":c:n:" opt; do
  case $opt in
    c) export cluster="$OPTARG";;
    n) export name="$OPTARG";;
    *) usage
       exit 1
       ;;
  esac
done

# Execute function
cluster_to_endpoint

set +x
