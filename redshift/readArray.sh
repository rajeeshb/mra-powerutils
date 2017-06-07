#!/bin/bash
array=(visit visitors visitor_replaces visitor_tallies)
for i in "${array[@]}"
do
  echo "./crMigrationSQL-TEST.sh -o c03 -d foobar -t $i -n c13 -r us-east-1"
  #echo $i
done
