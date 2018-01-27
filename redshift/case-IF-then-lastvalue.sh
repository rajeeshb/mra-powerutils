#!/usr/local/bin/bash

# PURPOSE:
# Take a list and based on what values you want to see, do something using a CASE STATEMENT
# Use linecount to do something with the LAST value in the list

file="customer_tallies.out";
linecount=$(wc -l $file | awk '{ print $1 }')
counter=1
while IFS='' read -r column; do
  case "$column" in
    customer_id)
       echo "isnull($column|| '[|]' ||";;
       updated)
       echo "isnull($column::text || '[|]' ||";;
             *)
       echo "isnull($column::text,'[null!]') || '[|]' ||";;
  esac
  if [ "$counter" -eq "$linecount" ]; then
      echo "isnull($column::text,'[null!]')) as md5sum"
  fi
  ((counter++))
done <"$file"
