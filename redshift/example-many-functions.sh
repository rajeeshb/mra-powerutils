#!/usr/local/bin/bash

set -e
#set -x

#
## USAGE FOR GETOPTS/PARAMS NEEDED FOR THIS PROGRAM:
#
usage () {
    echo "Usage: $0 -c cluster -d database -p profile -t ABC|XYZ"
    echo "Example: $0 -c myapplication-us-east-1-3.melsterdba.com -d random -p main -t ABC"
}

while getopts ":c:d:p:t:" opt; do
  case $opt in
    c) export cluster="$OPTARG";;
    d) export database="$OPTARG";;
    p) export profile="$OPTARG" ;;
    t) export type="$OPTARG"
       if [[ "$t" != XYZ && "$t" != ABC ]]; then
          usage
       fi
       ;;
    *) usage
       exit 1
       ;;
  esac
done

#
# SETUP VARIABLES AND FILE OUTPUTS
# Note: There maybe more than just the __main profile
#
schemamain="${database}__${profile}"
dbtype="${type}"
homedir="$(echo $HOME)"
tmpdir="${homedir}/dedup-${database}-${type}"
DTSTMP=$(date '+%Y-%m-%d')
PSQL=$(which psql)
PASTE=$(which paste)
# SQL TEXT FILES
SQL="${tmpdir}/runDEDUP-$dbtype.sql"
SQL2="${tmpdir}/runDEDUP-customer_arrays_and_counts.sql"
# COLUMN OUTPUT FROM DB QUERIES
COLS1="${tmpdir}/click_counts.out"
COLS2="${tmpdir}/customer_counts.out"
COLS3="${tmpdir}/click_arrays.out"
COLS4="${tmpdir}/customer_arrays.out"
# COLORIZE OUTPUT
# Use with echo -e: "-e" escapes the backlash
RED="\033[0;31m"
YELLOW="\033[0;33m"
GREEN="\033[0;32m"
BLUE="\033[0;34m"
NC="\033[0m"



# CREATE THE DIRECTORY FOR THE FILE OUTPUTS
echo -e "Making a temp directory for SQL:${YELLOW}${tmpdir}"
mkdir -p "${tmpdir}"

# OUTPUT THE INFORMATIVE DETAILS
echo -e "Redshift cluster:${BLUE}${cluster}"
echo -e "Customer:${BLUE}${database}"
echo -e "Schema:${BLUE}${schemamain}"
echo -e "Database to Dedup:${BLUE}${table}"


#
# MAIN FUNCTIONS FOR THIS PROGRAM:
# buildSQL:       -Main buildSQL function that creates ALL sql scripts to dedup. It calls buildSQL2 for TALLIS & LISTS tables.
#                      -If type => ABC then it creates the dedup sql needed for these tables: (CLICKS, CUSTOMERS, CLICKOR_REPLACES, CLICKOR_BATCHES)
#                      -If type => XYZ then it creates the dedup sql needed for these tables: (events__all_events)
# buildSQL2:      -Create the dedup sql for: (CLICK_TALLIES, CLICKOR_TALLIES, CLICK_LISTS, CLICKOR_LISTS)
#
# getPW:          -Prompt for the redshift cluster pw to be used by the column queries
#
# queryCOLS(1-4): -Database queries to get column names for ABC tables used by buildSQL2
#
# MD5 functions:
# For every column other than the primary_key and timestamp column, we need to create a md5sum hash
# Each function vary slightly to create the proper formatting for different queries 
#   -addFindDupsMD5   
#   -addInsertTempMD5
#   -addDeleteMD5
#


# BUILD SQL
buildSQL()
{
 case "${type}" in 
 ABC)
    echo -e "/*###CLICKS###*/" >> $SQL
    echo -e "--1) FIND OUT HOW MANY DUPS" >> $SQL
    echo -e "select count(*), min(updated), max(updated) \n from ( \n select click_id, updated \n from  \n ${schemamain}.clicks \n group by click_id, updated \n having count(*) > 1 \n);" >> $SQL
    echo -e "\n" >> $SQL
    echo -e "--2) CREATE THE TEMP TABLE" >> $SQL
    echo -e "CREATE TABLE IF NOT EXISTS \n ${schemamain}.clicks_TEMP \n (LIKE  ${schemamain}.clicks INCLUDING DEFAULTS)\n;" >> $SQL
    echo -e "\n" >> $SQL
    echo -e "--3) COPY ROWS OF DUPES TO TEMP TABLE" >> $SQL
    echo -e "insert into ${schemamain}.clicks_TEMP \n (\n SELECT DISTINCT * from ${schemamain}.clicks where click_id in\n (\n select click_id from ${schemamain}.clicks group by click_id, updated having count(*) > 1\n)\n);" >> $SQL
    echo -e "\n" >> $SQL
    echo -e "--4) DELETE DUPS FROM ORIGINAL TABLE" >> $SQL
    echo -e "delete from ${schemamain}.clicks\n WHERE (click_id,updated) in\n (\n select click_id,updated from ${schemamain}.clicks_TEMP\n);\n" >> $SQL
    echo -e "\n" >> $SQL
    echo -e "--5) COPY DE-DUPED ROWS BACK INTO ORIGINAL TABLE" >> $SQL
    echo -e "insert into ${schemamain}.clicks select DISTINCT * from ${schemamain}.clicks_TEMP;\n" >> $SQL
    echo -e "\n" >> $SQL
    echo -e "--6) RUN THE FIND DUPS QUERY AGAIN TO VERIFY THAT ALL DUPS HAVE BEEN CLEARED" >> $SQL

    echo -e "/*###CUSTOMERS###*/" >> $SQL
    echo -e "--1) FIND OUT HOW MANY DUPS" >> $SQL
    echo -e "select count(*), min(updated), max(updated) \n from ( \n select customer_id, updated \n from  \n ${schemamain}.customers \n group by customer_id, updated \n having count(*) > 1 \n);" >> $SQL
    echo -e "\n" >> $SQL
    echo -e "--2) CREATE THE TEMP TABLE" >> $SQL
    echo -e "CREATE TABLE IF NOT EXISTS \n ${schemamain}.customers_TEMP \n (LIKE  ${schemamain}.customers INCLUDING DEFAULTS)\n;" >> $SQL
    echo -e "\n" >> $SQL
    echo -e "--3) COPY ROWS OF DUPES TO TEMP TABLE" >> $SQL
    echo -e "insert into ${schemamain}.customers_TEMP \n (\n SELECT DISTINCT * from ${schemamain}.customers where customer_id in\n (\n select customer_id from ${schemamain}.customers group by customer_id, updated having count(*) > 1\n)\n);" >> $SQL
    echo -e "\n" >> $SQL
    echo -e "--4) DELETE DUPS FROM ORIGINAL TABLE" >> $SQL
    echo -e "delete from ${schemamain}.customers\n WHERE (customer_id,updated) in\n (\n select customer_id,updated from ${schemamain}.customers_TEMP\n);\n" >> $SQL
    echo -e "\n" >> $SQL
    echo -e "--5) COPY DE-DUPED ROWS BACK INTO ORIGINAL TABLE" >> $SQL
    echo -e "insert into ${schemamain}.customers select DISTINCT * from ${schemamain}.customers_TEMP;\n" >> $SQL
    echo -e "\n" >> $SQL
    echo -e "--6) RUN THE FIND DUPS QUERY AGAIN TO VERIFY THAT ALL DUPS HAVE BEEN CLEARED" >> $SQL

    echo -e "/*###CLICKOR_REPLACES###*/" >> $SQL
    echo -e "--1) FIND OUT HOW MANY DUPS" >> $SQL
    echo -e "select count(*), min(updated), max(updated) \n from ( \n select customer_replaces_id, updated \n from  \n ${schemamain}.customer_replaces \n group by customer_replaces_id, updated \n having count(*) > 1 \n);" >> $SQL
    echo -e "\n" >> $SQL
    echo -e "--2) CREATE THE TEMP TABLE" >> $SQL
    echo -e "CREATE TABLE IF NOT EXISTS \n ${schemamain}.customer_replaces_TEMP \n (LIKE  ${schemamain}.customer_replaces INCLUDING DEFAULTS)\n;" >> $SQL
    echo -e "\n" >> $SQL
    echo -e "--3) COPY ROWS OF DUPES TO TEMP TABLE" >> $SQL
    echo -e "insert into ${schemamain}.customer_replaces_TEMP \n (\n SELECT DISTINCT * from ${schemamain}.customer_replaces where customer_replaces_id in\n (\n select customer_replaces_id from ${schemamain}.customer_replaces group by customer_replaces_id, updated having count(*) > 1\n)\n);" >> $SQL
    echo -e "\n" >> $SQL
    echo -e "--4) DELETE DUPS FROM ORIGINAL TABLE" >> $SQL
    echo -e "delete from ${schemamain}.customer_replaces\n WHERE (customer_replaces_id,updated) in\n (\n select customer_replaces_id,updated from ${schemamain}.customer_replaces_TEMP\n);\n" >> $SQL
    echo -e "\n" >> $SQL
    echo -e "--5) COPY DE-DUPED ROWS BACK INTO ORIGINAL TABLE" >> $SQL
    echo -e "insert into ${schemamain}.customer_replaces select DISTINCT * from ${schemamain}.customer_replaces_TEMP;\n" >> $SQL
    echo -e "\n" >> $SQL
    echo -e "--6) RUN THE FIND DUPS QUERY AGAIN TO VERIFY THAT ALL DUPS HAVE BEEN CLEARED" >> $SQL

    echo -e "/*###CLICKOR_BATCHES###*/" >> $SQL
    echo -e "--1) FIND OUT HOW MANY DUPS" >> $SQL
    echo -e "select count(*), min(batch_time), max(batch_time) \n from ( \n select customer_id, batch_time \n from  \n ${schemamain}.customer_batches \n group by customer_id, batch_time \n having count(*) > 1 \n);" >> $SQL
    echo -e "\n" >> $SQL
    echo -e "--2) CREATE THE TEMP TABLE" >> $SQL
    echo -e "CREATE TABLE IF NOT EXISTS \n ${schemamain}.customer_batches_TEMP \n (LIKE  ${schemamain}.customer_batches INCLUDING DEFAULTS)\n;" >> $SQL
    echo -e "\n" >> $SQL
    echo -e "--3) COPY ROWS OF DUPES TO TEMP TABLE" >> $SQL
    echo -e "insert into ${schemamain}.customer_batches_TEMP \n (\n SELECT DISTINCT * from ${schemamain}.customer_batches where customer_id in\n (\n select customer_id from ${schemamain}.customer_batches group by customer_id, batch_time having count(*) > 1\n)\n);" >> $SQL
    echo -e "\n" >> $SQL
    echo -e "--4) DELETE DUPS FROM ORIGINAL TABLE" >> $SQL
    echo -e "delete from ${schemamain}.customer_batches\n WHERE (customer_id,batch_time) in\n (\n select customer_id,batch_time from ${schemamain}.customer_batches_TEMP\n);\n" >> $SQL
    echo -e "\n" >> $SQL
    echo -e "--5) COPY DE-DUPED ROWS BACK INTO ORIGINAL TABLE" >> $SQL
    echo -e "insert into ${schemamain}.customer_batches select DISTINCT * from ${schemamain}.customer_batches_TEMP;\n" >> $SQL
    echo -e "\n" >> $SQL
    echo -e "--6) RUN THE FIND DUPS QUERY AGAIN TO VERIFY THAT ALL DUPS HAVE BEEN CLEARED" >> $SQL

    echo -e "/*### FINAL CHECK AGAINST CUSTOMERS VIEW ###*/" >> $SQL	
    echo -e "select count(*), min(updated), max(updated)\n from (\n select updated\n from\n ${schemamain}.customers_view\n group by \"customer - id\", updated\n having count(*) > 1\n);" >> $SQL
    echo -e "\n" >> $SQL

    echo -e "/*### CLEANUP TEMP TABLES ONCE EVERYTHING LOOKS GOOD ###*/" >> $SQL
    echo -e "drop table ${schemamain}.clicks_TEMP;" >> $SQL
    echo -e "drop table ${schemamain}.customers_TEMP;" >> $SQL
    echo -e "drop table ${schemamain}.customer_replaces_TEMP;" >> $SQL
    echo -e "drop table ${schemamain}.customer_batches_TEMP;" >> $SQL

    echo -e "Creating a separate sql script for list and counts..."
    buildSQL2
    ;;
 XYZ)
    echo -e "/*### XYZ - EVENT TABLES TO DEDUP ###*/" >> $SQL
    echo -e "select count(*), min(eventtime), max(eventtime) \n from ( \n select eventtime \n from  \n ${schemamain}.events__all_events\n group by eventid, eventtime \n having count(*) > 1 \n);" >> $SQL
    echo -e "\n" >> $SQL
    echo -e "CREATE TABLE IF NOT EXISTS \n ${schemamain}.events__all_events_TEMP\n \n (LIKE  ${schemamain}.events__all_events\n INCLUDING DEFAULTS)\n;" >> $SQL
    echo -e "\n" >> $SQL
    echo -e "insert into ${schemamain}.events__all_events_TEMP \n (\n SELECT DISTINCT * from ${schemamain}.events__all_events where eventid in\n (\n select eventid from ${schemamain}.events__all_events group by eventid, eventtime having count(*) > 1\n)\n);" >> $SQL
    echo -e "\n" >> $SQL
    echo -e "delete from ${schemamain}.events__all_events\n WHERE eventid in\n (\n select eventid from ${schemamain}.events__all_events_TEMP\n);\n" >> $SQL
    echo -e "\n" >> $SQL
    echo -e "insert into ${schemamain}.events__all_events select * from ${schemamain}.events__all_events_TEMP;\n" >> $SQL
    echo -e "\n" >> $SQL
    echo -e "/*### CLEANUP TEMP TABLES ONCE EVERYTHING LOOKS GOOD ###*/" >> $SQL
    echo -e "drop table ${schemamain}.events__all_events_TEMP;" >> $SQL
    
    ;;
 *)
    echo -e "No sql. Check script for error" >> $SQL
    ;;
 esac
}


buildSQL2()
{
    getPW
    queryCOLS1 "$CLPWD"
    echo -e "/*####CLICK_TALLIES####*/" >> $SQL2 
    echo -e "--1) FIND OUT HOW MANY DUPS" >> $SQL2
    echo -e "select count(*), min(updated), max(updated)\nfrom ( \nselect" >> $SQL2
    addFindDupsMD5 $COLS1 >> $SQL2
    echo -e "from  \n${schemamain}.click_counts \ngroup by md5sum, click_id, updated having count(*) > 1);" >> $SQL2
    echo -e "\n" >> $SQL2
    echo -e "--2) CREATE THE TEMP TABLE" >> $SQL2
    echo -e "CREATE TABLE IF NOT EXISTS \n ${schemamain}.click_counts_TEMP \n (LIKE  ${schemamain}.click_counts INCLUDING DEFAULTS);" >> $SQL2
    echo -e "\n" >> $SQL2
    echo -e "ALTER TABLE ${schemamain}.click_counts_TEMP ADD COLUMN md5sum VARCHAR;" >> $SQL2
    echo -e "\n" >> $SQL2
    echo -e "--3) COPY ROWS OF DUPES TO TEMP TABLE" >> $SQL2
    echo -e "insert into ${schemamain}.click_counts_TEMP \n (\nSELECT *,\nmd5(" >> $SQL2
    addInsertTempMD5 $COLS1 >> $SQL2
    echo -e "from ${schemamain}.click_counts\n group by md5sum," >> $SQL2
    $PASTE -sd, "$COLS1" >> $SQL2
    echo -e "having count(*) > 1 \n);" >> $SQL2
    echo -e "\n" >> $SQL2
    echo -e "--4) DELETE DUPS FROM ORIGINAL TABLE" >> $SQL2
    echo -e "delete from ${schemamain}.click_counts \nWHERE (click_id, updated,\n md5(" >> $SQL2
    addDeleteMD5 $COLS1 >> $SQL2	
    echo -e ") in (select click_id, updated, md5sum from ${schemamain}.click_counts_TEMP);" >> $SQL2
    echo -e "\n" >> $SQL2
    echo -e "--5) COPY DE-DUPED ROWS BACK INTO ORIGINAL TABLE" >> $SQL2
    echo -e "insert into ${schemamain}.click_counts\nselect" >> $SQL2
    $PASTE -sd, "$COLS1" >> $SQL2
    echo -e "from ${schemamain}.click_counts_TEMP;\n" >> $SQL2
    echo -e "--6) RUN THE FIND DUPS QUERY AGAIN TO VERIFY THAT ALL DUPS HAVE BEEN CLEARED" >> $SQL2
    echo -e "--7) CLEANUP TEMP TABLES ONCE EVERYTHING LOOKS GOOD" >> $SQL2
    echo -e "drop table ${schemamain}.click_counts_TEMP;" >> $SQL2
    echo -e "\n" >> $SQL2

    queryCOLS2 "$CLPWD"
    echo -e "/*####CLICKOR_TALLIES####*/" >> $SQL2 
    echo -e "--1) FIND OUT HOW MANY DUPS" >> $SQL2
    echo -e "select count(*), min(updated), max(updated)\nfrom ( \nselect" >> $SQL2
    addFindDupsMD5 $COLS2 >> $SQL2
    echo -e "from  \n${schemamain}.customer_counts \ngroup by md5sum, customer_id, updated having count(*) > 1);" >> $SQL2
    echo -e "\n" >> $SQL2
    echo -e "--2) CREATE THE TEMP TABLE" >> $SQL2
    echo -e "CREATE TABLE IF NOT EXISTS \n ${schemamain}.customer_counts_TEMP \n (LIKE  ${schemamain}.customer_counts INCLUDING DEFAULTS);" >> $SQL2
    echo -e "\n" >> $SQL2
    echo -e "ALTER TABLE ${schemamain}.customer_counts_TEMP ADD COLUMN md5sum VARCHAR;" >> $SQL2
    echo -e "\n" >> $SQL2
    echo -e "--3) COPY ROWS OF DUPES TO TEMP TABLE" >> $SQL2
    echo -e "insert into ${schemamain}.customer_counts_TEMP \n (\nSELECT *,\nmd5(" >> $SQL2
    addInsertTempMD5 $COLS2 >> $SQL2
    echo -e "from ${schemamain}.customer_counts\n group by md5sum," >> $SQL2
    $PASTE -sd, "$COLS2" >> $SQL2
    echo -e "having count(*) > 1 \n);" >> $SQL2
    echo -e "\n" >> $SQL2
    echo -e "--4) DELETE DUPS FROM ORIGINAL TABLE" >> $SQL2
    echo -e "delete from ${schemamain}.customer_counts \nWHERE (customer_id, updated,\n md5(" >> $SQL2
    addDeleteMD5 $COLS2 >> $SQL2	
    echo -e ") in (select customer_id, updated, md5sum from ${schemamain}.customer_counts_TEMP);" >> $SQL2
    echo -e "\n" >> $SQL2
    echo -e "--5) COPY DE-DUPED ROWS BACK INTO ORIGINAL TABLE" >> $SQL2
    echo -e "insert into ${schemamain}.customer_counts\nselect" >> $SQL2
    $PASTE -sd, "$COLS2" >> $SQL2
    echo -e "from ${schemamain}.customer_counts_TEMP;\n" >> $SQL2
    echo -e "--6) RUN THE FIND DUPS QUERY AGAIN TO VERIFY THAT ALL DUPS HAVE BEEN CLEARED" >> $SQL2
    echo -e "--7) CLEANUP TEMP TABLES ONCE EVERYTHING LOOKS GOOD" >> $SQL2
    echo -e "drop table ${schemamain}.customer_counts_TEMP;" >> $SQL2
    echo -e "\n" >> $SQL2

    queryCOLS3 "$CLPWD"
    echo -e "/*####CLICK_LISTS####*/" >> $SQL2 
    echo -e "--1) FIND OUT HOW MANY DUPS" >> $SQL2
    echo -e "select count(*), min(updated), max(updated)\nfrom ( \nselect" >> $SQL2
    addFindDupsMD5 $COLS3 >> $SQL2
    echo -e "from  \n${schemamain}.click_arrays \ngroup by md5sum, click_id, updated having count(*) > 1);" >> $SQL2
    echo -e "\n" >> $SQL2
    echo -e "--2) CREATE THE TEMP TABLE" >> $SQL2
    echo -e "CREATE TABLE IF NOT EXISTS \n ${schemamain}.click_arrays_TEMP \n (LIKE  ${schemamain}.click_arrays INCLUDING DEFAULTS);" >> $SQL2
    echo -e "\n" >> $SQL2
    echo -e "ALTER TABLE ${schemamain}.click_arrays_TEMP ADD COLUMN md5sum VARCHAR;" >> $SQL2
    echo -e "\n" >> $SQL2
    echo -e "--3) COPY ROWS OF DUPES TO TEMP TABLE" >> $SQL2
    echo -e "insert into ${schemamain}.click_arrays_TEMP \n (\nSELECT *,\nmd5(" >> $SQL2
    addInsertTempMD5 $COLS3 >> $SQL2
    echo -e "from ${schemamain}.click_arrays\n group by md5sum," >> $SQL2
    $PASTE -sd, "$COLS3" >> $SQL2
    echo -e "having count(*) > 1 \n);" >> $SQL2
    echo -e "\n" >> $SQL2
    echo -e "--4) DELETE DUPS FROM ORIGINAL TABLE" >> $SQL2
    echo -e "delete from ${schemamain}.click_arrays \nWHERE (click_id, updated,\n md5(" >> $SQL2
    addDeleteMD5 $COLS3 >> $SQL2	
    echo -e ") in (select click_id, updated, md5sum from ${schemamain}.click_arrays_TEMP);" >> $SQL2
    echo -e "\n" >> $SQL2
    echo -e "--5) COPY DE-DUPED ROWS BACK INTO ORIGINAL TABLE" >> $SQL2
    echo -e "insert into ${schemamain}.click_arrays\nselect" >> $SQL2
    $PASTE -sd, "$COLS3" >> $SQL2
    echo -e "from ${schemamain}.click_arrays_TEMP;\n" >> $SQL2
    echo -e "--6) RUN THE FIND DUPS QUERY AGAIN TO VERIFY THAT ALL DUPS HAVE BEEN CLEARED" >> $SQL2
    echo -e "--7) CLEANUP TEMP TABLES ONCE EVERYTHING LOOKS GOOD" >> $SQL2
    echo -e "drop table ${schemamain}.click_arrays_TEMP;" >> $SQL2
    echo -e "\n" >> $SQL2

    queryCOLS4 "$CLPWD"
    echo -e "/*####CLICKOR_LISTS####*/" >> $SQL2 
    echo -e "--1) FIND OUT HOW MANY DUPS" >> $SQL2
    echo -e "select count(*), min(updated), max(updated)\nfrom ( \nselect" >> $SQL2
    addFindDupsMD5 $COLS4 >> $SQL2
    echo -e "from  \n${schemamain}.customer_arrays \ngroup by md5sum, customer_id, updated having count(*) > 1);" >> $SQL2
    echo -e "\n" >> $SQL2
    echo -e "--2) CREATE THE TEMP TABLE" >> $SQL2
    echo -e "CREATE TABLE IF NOT EXISTS \n ${schemamain}.customer_arrays_TEMP \n (LIKE  ${schemamain}.customer_arrays INCLUDING DEFAULTS);" >> $SQL2
    echo -e "\n" >> $SQL2
    echo -e "ALTER TABLE ${schemamain}.customer_arrays_TEMP ADD COLUMN md5sum VARCHAR;" >> $SQL2
    echo -e "\n" >> $SQL2
    echo -e "--3) COPY ROWS OF DUPES TO TEMP TABLE" >> $SQL2
    echo -e "insert into ${schemamain}.customer_arrays_TEMP \n (\nSELECT *,\nmd5(" >> $SQL2
    addInsertTempMD5 $COLS4 >> $SQL2
    echo -e "from ${schemamain}.customer_arrays\n group by md5sum," >> $SQL2
    $PASTE -sd, "$COLS4" >> $SQL2
    echo -e "having count(*) > 1 \n);" >> $SQL2
    echo -e "\n" >> $SQL2
    echo -e "--4) DELETE DUPS FROM ORIGINAL TABLE" >> $SQL2
    echo -e "delete from ${schemamain}.customer_arrays \nWHERE (customer_id, updated,\n md5(" >> $SQL2
    addDeleteMD5 $COLS4 >> $SQL2	
    echo -e ") in (select customer_id, updated, md5sum from ${schemamain}.customer_arrays_TEMP);" >> $SQL2
    echo -e "\n" >> $SQL2
    echo -e "--5) COPY DE-DUPED ROWS BACK INTO ORIGINAL TABLE" >> $SQL2
    echo -e "insert into ${schemamain}.customer_arrays\nselect" >> $SQL2
    $PASTE -sd, "$COLS4" >> $SQL2
    echo -e "from ${schemamain}.customer_arrays_TEMP;\n" >> $SQL2
    echo -e "--6) RUN THE FIND DUPS QUERY AGAIN TO VERIFY THAT ALL DUPS HAVE BEEN CLEARED" >> $SQL2
    echo -e "--7) CLEANUP TEMP TABLES ONCE EVERYTHING LOOKS GOOD" >> $SQL2
    echo -e "drop table ${schemamain}.customer_arrays_TEMP;" >> $SQL2
    echo -e "\n" >> $SQL2
    
}



# ASK FOR THE PW FOR THE CLUSTER ONCE TO BE USED BY THE QUERIES
getPW ()
 {
  echo -en "Password for ${YELLOW}${cluster}:"
  read -s clusterpw
  export CLPWD="${clusterpw}"
}



# QUERY REDSHIFT DB TO GRAB COLUMNS FOR ABC - TALLIES AND LISTS tables
queryCOLS1()
{
 PGPASSWORD="$1" "$PSQL" -h "${cluster}" -U masteruser -d "$database" -p 5439 << EOF
        \a
        \t
        \o $COLS1
        SELECT column_name
        FROM information_schema.columns
        WHERE table_schema = '$schemamain'
        AND table_name   = 'click_counts'
        order by ordinal_position;
EOF
}


queryCOLS2()
{
 PGPASSWORD="$1" "$PSQL" -h "${cluster}" -U masteruser -d "$database" -p 5439 << EOF
        \a
        \t
        \o $COLS2
        SELECT column_name
        FROM information_schema.columns
        WHERE table_schema = '$schemamain'
        AND table_name   = 'customer_counts'
        order by ordinal_position;
EOF
}


queryCOLS3()
{
 PGPASSWORD="$1" "$PSQL" -h "${cluster}" -U masteruser -d "$database" -p 5439 << EOF
        \a
        \t
        \o $COLS3
        SELECT column_name
        FROM information_schema.columns
        WHERE table_schema = '$schemamain'
        AND table_name   = 'click_arrays'
        order by ordinal_position;
EOF
}


queryCOLS4()
{
 PGPASSWORD="$1" "$PSQL" -h "${cluster}" -U masteruser -d "$database" -p 5439 << EOF
        \a
        \t
        \o $COLS4
        SELECT column_name
        FROM information_schema.columns
        WHERE table_schema = '$schemamain'
        AND table_name   = 'customer_arrays'
        order by ordinal_position;
EOF
}


# MD5
addFindDupsMD5()
{
     file="$1"  
     linecount=$(wc -l <"$file" | awk '{ print $1 }')
     counter=1
     while IFS='' read -r column; do
	 case "$column" in
         click_id)
          echo -e "$column,";;
	   customer_id)
	      echo -e "$column,";;
	      updated)
	      echo -e "$column, md5(";;
		    *)
	      echo -e "isnull($column::text,'[null!]') || '[|]' ||";;
	 esac
	 if [ "$counter" -eq "$linecount" ]; then
	     echo -e "isnull($column::text,'[null!]')) as md5sum"
	 fi
     ((counter++))
     done <"$file"
}


addInsertTempMD5()
{
     file="$1"  
     linecount=$(wc -l <"$file" | awk '{ print $1 }')
     counter=1
     while IFS='' read -r column; do
	 case "$column" in
             click_id)
              echo "$column || '[|]' ||";;
           customer_id)
              echo "$column || '[|]' ||";;
              updated)
              echo "$column::text || '[|]' ||";;
                    *)
              echo "isnull($column::text,'[null!]') || '[|]' ||";;
         esac
         if [ "$counter" -eq "$linecount" ]; then
             echo "isnull($column::text,'[null!]')) as md5sum"
         fi
     ((counter++))
     done <"$file"
}


addDeleteMD5()
{
     file="$1"  
     linecount=$(wc -l <"$file" | awk '{ print $1 }')
     counter=1
     while IFS='' read -r column; do
	 case "$column" in
             click_id)
              echo "$column || '[|]' ||";;
           customer_id)
              echo "$column || '[|]' ||";;
              updated)
              echo "$column::text || '[|]' ||";;
                    *)
              echo "isnull($column::text,'[null!]') || '[|]' ||";;
         esac
         if [ "$counter" -eq "$linecount" ]; then
             echo "isnull($column::text,'[null!]'))"
         fi
     ((counter++))
     done <"$file"
}

#
### EXECUTE THE MAIN FUNCTION
#
buildSQL

#set +x
