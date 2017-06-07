#!/usr/local/bin/bash

set -e
set -x

# Create a Function for each command
# http://mywiki.wooledge.org/BashFAQ/050
# http://stackoverflow.com/questions/42755407/how-to-create-an-alias-map-to-a-list-of-commands-with-arguments-passed-in
run_c01 () {
    RUNCMD=$(PGPASSWORD=foobar#! psql -h mradev-events1.foobar.us-east-1.redshift.amazonaws.com -U masteruser -v v1="$name"  -d dev -p 5439 -f getDBName.sql)
}

run_c02 () {
    RUNCMD=$(PGPASSWORD=foobar#! psql -h mradev-events2.foobar.us-east-1.redshift.amazonaws.com -U masteruser -v v1="$name" -d dev -p 5439 -f getDBName.sql)
}

run_c03 () {
    RUNCMD=$(PGPASSWORD=foobar#! psql -h mradev-events3.foobar.us-east-1.redshift.amazonaws.com -U masteruser -v v1="$name" -d dev -p 5439 -f getDBName.sql)
}

run_c15 () {
    RUNCMD=$(PGPASSWORD=foobar#! psql -h mradev-events4.foobar.us-east-1.redshift.amazonaws.com -U masteruser -v v1="$name" -d dev -p 5439 -f getDBName.sql)
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

# Check that function is called and execute
if declare -f run_"$cluster" >/dev/null 2>&1; 
    then run_"$cluster"; 
fi

set +x
