#!/usr/local/bin/bash

set -e
#set -x

# COLORIZE OUTPUT
# Use with echo -e: "-e" escapes the backlash
RED="\033[0;31m"
YELLOW="\033[0;33m"
GREEN="\033[0;32m"
BLUE="\033[0;34m"
NC="\033[0m"

#
## USAGE FOR GETOPTS/PARAMS NEEDED FOR THIS PROGRAM:
#
usage () {
    echo -e "${BLUE}Usage:${GREEN}$0 -c cluster -d database -p profile -t ABC|XYZ"
    echo -e "${BLUE}Example:${GREEN}$0 -c applicationname-us-east-1-3.myappdomain.com -d random -p main -t ABC"
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
SQL2="${tmpdir}/runDEDUP-eventor_arrays_and_checks.sql"
# COLUMN OUTPUT FROM DB QUERIES
COLS1="${tmpdir}/event_checks.out"
COLS2="${tmpdir}/eventor_checks.out"
COLS3="${tmpdir}/event_arrays.out"
COLS4="${tmpdir}/eventor_arrays.out"


# CREATE THE DIRECTORY FOR THE FILE OUTPUTS
echo -e "${BLUE}Making a temp directory for SQL:${GREEN}${tmpdir}"
tput init #resets the color terminal back
mkdir -p "${tmpdir}"

# OUTPUT THE INFORMATIVE DETAILS
echo -e "${BLUE}Redshift cluster:${GREEN}${cluster}"
echo -e "${BLUE}Customer:${GREEN}${database}"
echo -e "${BLUE}Schema:${GREEN}${schemamain}"
tput init #resets the color terminal back

#
# MAIN FUNCTIONS FOR THIS PROGRAM:
# buildSQL:       -Main buildSQL function that creates ALL sql scripts to dedup. It calls buildSQL2 for TALLIS & LISTS tables.
#                      -If type => ABC then it creates the dedup sql needed for these tables: (CLICKS, CUSTOMERS, EVENTOR_REPLACES, EVENTOR_BATCHES)
#                      -If type => XYZ then it creates the dedup sql needed for these tables: (events__all_events)
# buildSQL2:      -Create the dedup sql for: (EVENT_CHECKS, EVENTOR_TALLIES, EVENT_LISTS, EVENTOR_LISTS)
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
    echo -e "select count(*), min(updated), max(updated) \n from ( \n select event_id, updated \n from  \n ${schemamain}.clicks \n group by event_id, updated \n having count(*) > 1 \n);" >> $SQL
    echo -e "\n" >> $SQL
    echo -e "--2) CREATE THE TEMP TABLE" >> $SQL
    echo -e "CREATE TABLE IF NOT EXISTS \n ${schemamain}.clicks_TEMP \n (LIKE  ${schemamain}.clicks INCLUDING DEFAULTS)\n;" >> $SQL
    echo -e "\n" >> $SQL
    echo -e "--3) COPY ROWS OF DUPES TO TEMP TABLE" >> $SQL
    echo -e "insert into ${schemamain}.clicks_TEMP \n (\n SELECT DISTINCT * from ${schemamain}.clicks where event_id in\n (\n select event_id from ${schemamain}.clicks group by event_id, updated having count(*) > 1\n)\n);" >> $SQL
    echo -e "\n" >> $SQL
    echo -e "--4) DELETE DUPS FROM ORIGINAL TABLE" >> $SQL
    echo -e "delete from ${schemamain}.clicks\n WHERE (event_id,updated) in\n (\n select event_id,updated from ${schemamain}.clicks_TEMP\n);\n" >> $SQL
    echo -e "\n" >> $SQL
    echo -e "--5) COPY DE-DUPED ROWS BACK INTO ORIGINAL TABLE" >> $SQL
    echo -e "insert into ${schemamain}.clicks select DISTINCT * from ${schemamain}.clicks_TEMP;\n" >> $SQL
    echo -e "\n" >> $SQL
    echo -e "--6) RUN THE FIND DUPS QUERY AGAIN TO VERIFY THAT ALL DUPS HAVE BEEN CLEARED" >> $SQL

    echo -e "/*###CUSTOMERS###*/" >> $SQL
    echo -e "--1) FIND OUT HOW MANY DUPS" >> $SQL
    echo -e "select count(*), min(updated), max(updated) \n from ( \n select eventor_id, updated \n from  \n ${schemamain}.eventors \n group by eventor_id, updated \n having count(*) > 1 \n);" >> $SQL
    echo -e "\n" >> $SQL
    echo -e "--2) CREATE THE TEMP TABLE" >> $SQL
    echo -e "CREATE TABLE IF NOT EXISTS \n ${schemamain}.eventors_TEMP \n (LIKE  ${schemamain}.eventors INCLUDING DEFAULTS)\n;" >> $SQL
    echo -e "\n" >> $SQL
    echo -e "--3) COPY ROWS OF DUPES TO TEMP TABLE" >> $SQL
    echo -e "insert into ${schemamain}.eventors_TEMP \n (\n SELECT DISTINCT * from ${schemamain}.eventors where eventor_id in\n (\n select eventor_id from ${schemamain}.eventors group by eventor_id, updated having count(*) > 1\n)\n);" >> $SQL
    echo -e "\n" >> $SQL
    echo -e "--4) DELETE DUPS FROM ORIGINAL TABLE" >> $SQL
    echo -e "delete from ${schemamain}.eventors\n WHERE (eventor_id,updated) in\n (\n select eventor_id,updated from ${schemamain}.eventors_TEMP\n);\n" >> $SQL
    echo -e "\n" >> $SQL
    echo -e "--5) COPY DE-DUPED ROWS BACK INTO ORIGINAL TABLE" >> $SQL
    echo -e "insert into ${schemamain}.eventors select DISTINCT * from ${schemamain}.eventors_TEMP;\n" >> $SQL
    echo -e "\n" >> $SQL
    echo -e "--6) RUN THE FIND DUPS QUERY AGAIN TO VERIFY THAT ALL DUPS HAVE BEEN CLEARED" >> $SQL

    echo -e "/*###EVENTOR_REPLACES###*/" >> $SQL
    echo -e "--1) FIND OUT HOW MANY DUPS" >> $SQL
    echo -e "select count(*), min(updated), max(updated) \n from ( \n select eventor_replaces_id, updated \n from  \n ${schemamain}.eventor_replaces \n group by eventor_replaces_id, updated \n having count(*) > 1 \n);" >> $SQL
    echo -e "\n" >> $SQL
    echo -e "--2) CREATE THE TEMP TABLE" >> $SQL
    echo -e "CREATE TABLE IF NOT EXISTS \n ${schemamain}.eventor_replaces_TEMP \n (LIKE  ${schemamain}.eventor_replaces INCLUDING DEFAULTS)\n;" >> $SQL
    echo -e "\n" >> $SQL
    echo -e "--3) COPY ROWS OF DUPES TO TEMP TABLE" >> $SQL
    echo -e "insert into ${schemamain}.eventor_replaces_TEMP \n (\n SELECT DISTINCT * from ${schemamain}.eventor_replaces where eventor_replaces_id in\n (\n select eventor_replaces_id from ${schemamain}.eventor_replaces group by eventor_replaces_id, updated having count(*) > 1\n)\n);" >> $SQL
    echo -e "\n" >> $SQL
    echo -e "--4) DELETE DUPS FROM ORIGINAL TABLE" >> $SQL
    echo -e "delete from ${schemamain}.eventor_replaces\n WHERE (eventor_replaces_id,updated) in\n (\n select eventor_replaces_id,updated from ${schemamain}.eventor_replaces_TEMP\n);\n" >> $SQL
    echo -e "\n" >> $SQL
    echo -e "--5) COPY DE-DUPED ROWS BACK INTO ORIGINAL TABLE" >> $SQL
    echo -e "insert into ${schemamain}.eventor_replaces select DISTINCT * from ${schemamain}.eventor_replaces_TEMP;\n" >> $SQL
    echo -e "\n" >> $SQL
    echo -e "--6) RUN THE FIND DUPS QUERY AGAIN TO VERIFY THAT ALL DUPS HAVE BEEN CLEARED" >> $SQL

    echo -e "/*###EVENTOR_BATCHES###*/" >> $SQL
    echo -e "--1) FIND OUT HOW MANY DUPS" >> $SQL
    echo -e "select count(*), min(batch_time), max(batch_time) \n from ( \n select eventor_id, batch_time \n from  \n ${schemamain}.eventor_batches \n group by eventor_id, batch_time \n having count(*) > 1 \n);" >> $SQL
    echo -e "\n" >> $SQL
    echo -e "--2) CREATE THE TEMP TABLE" >> $SQL
    echo -e "CREATE TABLE IF NOT EXISTS \n ${schemamain}.eventor_batches_TEMP \n (LIKE  ${schemamain}.eventor_batches INCLUDING DEFAULTS)\n;" >> $SQL
    echo -e "\n" >> $SQL
    echo -e "--3) COPY ROWS OF DUPES TO TEMP TABLE" >> $SQL
    echo -e "insert into ${schemamain}.eventor_batches_TEMP \n (\n SELECT DISTINCT * from ${schemamain}.eventor_batches where eventor_id in\n (\n select eventor_id from ${schemamain}.eventor_batches group by eventor_id, batch_time having count(*) > 1\n)\n);" >> $SQL
    echo -e "\n" >> $SQL
    echo -e "--4) DELETE DUPS FROM ORIGINAL TABLE" >> $SQL
    echo -e "delete from ${schemamain}.eventor_batches\n WHERE (eventor_id,batch_time) in\n (\n select eventor_id,batch_time from ${schemamain}.eventor_batches_TEMP\n);\n" >> $SQL
    echo -e "\n" >> $SQL
    echo -e "--5) COPY DE-DUPED ROWS BACK INTO ORIGINAL TABLE" >> $SQL
    echo -e "insert into ${schemamain}.eventor_batches select DISTINCT * from ${schemamain}.eventor_batches_TEMP;\n" >> $SQL
    echo -e "\n" >> $SQL
    echo -e "--6) RUN THE FIND DUPS QUERY AGAIN TO VERIFY THAT ALL DUPS HAVE BEEN CLEARED" >> $SQL

    echo -e "/*### FINAL CHECK AGAINST CUSTOMERS VIEW ###*/" >> $SQL	
    echo -e "select count(*), min(updated), max(updated)\n from (\n select updated\n from\n ${schemamain}.eventors_view\n group by \"eventor - id\", updated\n having count(*) > 1\n);" >> $SQL
    echo -e "\n" >> $SQL

    echo -e "/*### CLEANUP TEMP TABLES ONCE EVERYTHING LOOKS GOOD ###*/" >> $SQL
    echo -e "drop table ${schemamain}.clicks_TEMP;" >> $SQL
    echo -e "drop table ${schemamain}.eventors_TEMP;" >> $SQL
    echo -e "drop table ${schemamain}.eventor_replaces_TEMP;" >> $SQL
    echo -e "drop table ${schemamain}.eventor_batches_TEMP;" >> $SQL

    echo -e "Creating a separate sql script for list and checks..."
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
    echo -e "/*####EVENT_CHECKS####*/" >> $SQL2 
    echo -e "--1) FIND OUT HOW MANY DUPS" >> $SQL2
    echo -e "select count(*), min(updated), max(updated)\nfrom ( \nselect" >> $SQL2
    addFindDupsMD5 $COLS1 >> $SQL2
    echo -e "from  \n${schemamain}.event_checks \ngroup by md5sum, event_id, updated having count(*) > 1);" >> $SQL2
    echo -e "\n" >> $SQL2
    echo -e "--2) CREATE THE TEMP TABLE" >> $SQL2
    echo -e "CREATE TABLE IF NOT EXISTS \n ${schemamain}.event_checks_TEMP \n (LIKE  ${schemamain}.event_checks INCLUDING DEFAULTS);" >> $SQL2
    echo -e "\n" >> $SQL2
    echo -e "ALTER TABLE ${schemamain}.event_checks_TEMP ADD COLUMN md5sum VARCHAR;" >> $SQL2
    echo -e "\n" >> $SQL2
    echo -e "--3) COPY ROWS OF DUPES TO TEMP TABLE" >> $SQL2
    echo -e "insert into ${schemamain}.event_checks_TEMP \n (\nSELECT *,\nmd5(" >> $SQL2
    addInsertTempMD5 $COLS1 >> $SQL2
    echo -e "from ${schemamain}.event_checks\n group by md5sum," >> $SQL2
    $PASTE -sd, "$COLS1" >> $SQL2
    echo -e "having count(*) > 1 \n);" >> $SQL2
    echo -e "\n" >> $SQL2
    echo -e "--4) DELETE DUPS FROM ORIGINAL TABLE" >> $SQL2
    echo -e "delete from ${schemamain}.event_checks \nWHERE (event_id, updated,\n md5(" >> $SQL2
    addDeleteMD5 $COLS1 >> $SQL2	
    echo -e ") in (select event_id, updated, md5sum from ${schemamain}.event_checks_TEMP);" >> $SQL2
    echo -e "\n" >> $SQL2
    echo -e "--5) COPY DE-DUPED ROWS BACK INTO ORIGINAL TABLE" >> $SQL2
    echo -e "insert into ${schemamain}.event_checks\nselect" >> $SQL2
    $PASTE -sd, "$COLS1" >> $SQL2
    echo -e "from ${schemamain}.event_checks_TEMP;\n" >> $SQL2
    echo -e "--6) RUN THE FIND DUPS QUERY AGAIN TO VERIFY THAT ALL DUPS HAVE BEEN CLEARED" >> $SQL2
    echo -e "--7) CLEANUP TEMP TABLES ONCE EVERYTHING LOOKS GOOD" >> $SQL2
    echo -e "drop table ${schemamain}.event_checks_TEMP;" >> $SQL2
    echo -e "\n" >> $SQL2

    queryCOLS2 "$CLPWD"
    echo -e "/*####EVENTOR_TALLIES####*/" >> $SQL2 
    echo -e "--1) FIND OUT HOW MANY DUPS" >> $SQL2
    echo -e "select count(*), min(updated), max(updated)\nfrom ( \nselect" >> $SQL2
    addFindDupsMD5 $COLS2 >> $SQL2
    echo -e "from  \n${schemamain}.eventor_checks \ngroup by md5sum, eventor_id, updated having count(*) > 1);" >> $SQL2
    echo -e "\n" >> $SQL2
    echo -e "--2) CREATE THE TEMP TABLE" >> $SQL2
    echo -e "CREATE TABLE IF NOT EXISTS \n ${schemamain}.eventor_checks_TEMP \n (LIKE  ${schemamain}.eventor_checks INCLUDING DEFAULTS);" >> $SQL2
    echo -e "\n" >> $SQL2
    echo -e "ALTER TABLE ${schemamain}.eventor_checks_TEMP ADD COLUMN md5sum VARCHAR;" >> $SQL2
    echo -e "\n" >> $SQL2
    echo -e "--3) COPY ROWS OF DUPES TO TEMP TABLE" >> $SQL2
    echo -e "insert into ${schemamain}.eventor_checks_TEMP \n (\nSELECT *,\nmd5(" >> $SQL2
    addInsertTempMD5 $COLS2 >> $SQL2
    echo -e "from ${schemamain}.eventor_checks\n group by md5sum," >> $SQL2
    $PASTE -sd, "$COLS2" >> $SQL2
    echo -e "having count(*) > 1 \n);" >> $SQL2
    echo -e "\n" >> $SQL2
    echo -e "--4) DELETE DUPS FROM ORIGINAL TABLE" >> $SQL2
    echo -e "delete from ${schemamain}.eventor_checks \nWHERE (eventor_id, updated,\n md5(" >> $SQL2
    addDeleteMD5 $COLS2 >> $SQL2	
    echo -e ") in (select eventor_id, updated, md5sum from ${schemamain}.eventor_checks_TEMP);" >> $SQL2
    echo -e "\n" >> $SQL2
    echo -e "--5) COPY DE-DUPED ROWS BACK INTO ORIGINAL TABLE" >> $SQL2
    echo -e "insert into ${schemamain}.eventor_checks\nselect" >> $SQL2
    $PASTE -sd, "$COLS2" >> $SQL2
    echo -e "from ${schemamain}.eventor_checks_TEMP;\n" >> $SQL2
    echo -e "--6) RUN THE FIND DUPS QUERY AGAIN TO VERIFY THAT ALL DUPS HAVE BEEN CLEARED" >> $SQL2
    echo -e "--7) CLEANUP TEMP TABLES ONCE EVERYTHING LOOKS GOOD" >> $SQL2
    echo -e "drop table ${schemamain}.eventor_checks_TEMP;" >> $SQL2
    echo -e "\n" >> $SQL2

    queryCOLS3 "$CLPWD"
    echo -e "/*####EVENT_LISTS####*/" >> $SQL2 
    echo -e "--1) FIND OUT HOW MANY DUPS" >> $SQL2
    echo -e "select count(*), min(updated), max(updated)\nfrom ( \nselect" >> $SQL2
    addFindDupsMD5 $COLS3 >> $SQL2
    echo -e "from  \n${schemamain}.event_arrays \ngroup by md5sum, event_id, updated having count(*) > 1);" >> $SQL2
    echo -e "\n" >> $SQL2
    echo -e "--2) CREATE THE TEMP TABLE" >> $SQL2
    echo -e "CREATE TABLE IF NOT EXISTS \n ${schemamain}.event_arrays_TEMP \n (LIKE  ${schemamain}.event_arrays INCLUDING DEFAULTS);" >> $SQL2
    echo -e "\n" >> $SQL2
    echo -e "ALTER TABLE ${schemamain}.event_arrays_TEMP ADD COLUMN md5sum VARCHAR;" >> $SQL2
    echo -e "\n" >> $SQL2
    echo -e "--3) COPY ROWS OF DUPES TO TEMP TABLE" >> $SQL2
    echo -e "insert into ${schemamain}.event_arrays_TEMP \n (\nSELECT *,\nmd5(" >> $SQL2
    addInsertTempMD5 $COLS3 >> $SQL2
    echo -e "from ${schemamain}.event_arrays\n group by md5sum," >> $SQL2
    $PASTE -sd, "$COLS3" >> $SQL2
    echo -e "having count(*) > 1 \n);" >> $SQL2
    echo -e "\n" >> $SQL2
    echo -e "--4) DELETE DUPS FROM ORIGINAL TABLE" >> $SQL2
    echo -e "delete from ${schemamain}.event_arrays \nWHERE (event_id, updated,\n md5(" >> $SQL2
    addDeleteMD5 $COLS3 >> $SQL2	
    echo -e ") in (select event_id, updated, md5sum from ${schemamain}.event_arrays_TEMP);" >> $SQL2
    echo -e "\n" >> $SQL2
    echo -e "--5) COPY DE-DUPED ROWS BACK INTO ORIGINAL TABLE" >> $SQL2
    echo -e "insert into ${schemamain}.event_arrays\nselect" >> $SQL2
    $PASTE -sd, "$COLS3" >> $SQL2
    echo -e "from ${schemamain}.event_arrays_TEMP;\n" >> $SQL2
    echo -e "--6) RUN THE FIND DUPS QUERY AGAIN TO VERIFY THAT ALL DUPS HAVE BEEN CLEARED" >> $SQL2
    echo -e "--7) CLEANUP TEMP TABLES ONCE EVERYTHING LOOKS GOOD" >> $SQL2
    echo -e "drop table ${schemamain}.event_arrays_TEMP;" >> $SQL2
    echo -e "\n" >> $SQL2

    queryCOLS4 "$CLPWD"
    echo -e "/*####EVENTOR_LISTS####*/" >> $SQL2 
    echo -e "--1) FIND OUT HOW MANY DUPS" >> $SQL2
    echo -e "select count(*), min(updated), max(updated)\nfrom ( \nselect" >> $SQL2
    addFindDupsMD5 $COLS4 >> $SQL2
    echo -e "from  \n${schemamain}.eventor_arrays \ngroup by md5sum, eventor_id, updated having count(*) > 1);" >> $SQL2
    echo -e "\n" >> $SQL2
    echo -e "--2) CREATE THE TEMP TABLE" >> $SQL2
    echo -e "CREATE TABLE IF NOT EXISTS \n ${schemamain}.eventor_arrays_TEMP \n (LIKE  ${schemamain}.eventor_arrays INCLUDING DEFAULTS);" >> $SQL2
    echo -e "\n" >> $SQL2
    echo -e "ALTER TABLE ${schemamain}.eventor_arrays_TEMP ADD COLUMN md5sum VARCHAR;" >> $SQL2
    echo -e "\n" >> $SQL2
    echo -e "--3) COPY ROWS OF DUPES TO TEMP TABLE" >> $SQL2
    echo -e "insert into ${schemamain}.eventor_arrays_TEMP \n (\nSELECT *,\nmd5(" >> $SQL2
    addInsertTempMD5 $COLS4 >> $SQL2
    echo -e "from ${schemamain}.eventor_arrays\n group by md5sum," >> $SQL2
    $PASTE -sd, "$COLS4" >> $SQL2
    echo -e "having count(*) > 1 \n);" >> $SQL2
    echo -e "\n" >> $SQL2
    echo -e "--4) DELETE DUPS FROM ORIGINAL TABLE" >> $SQL2
    echo -e "delete from ${schemamain}.eventor_arrays \nWHERE (eventor_id, updated,\n md5(" >> $SQL2
    addDeleteMD5 $COLS4 >> $SQL2	
    echo -e ") in (select eventor_id, updated, md5sum from ${schemamain}.eventor_arrays_TEMP);" >> $SQL2
    echo -e "\n" >> $SQL2
    echo -e "--5) COPY DE-DUPED ROWS BACK INTO ORIGINAL TABLE" >> $SQL2
    echo -e "insert into ${schemamain}.eventor_arrays\nselect" >> $SQL2
    $PASTE -sd, "$COLS4" >> $SQL2
    echo -e "from ${schemamain}.eventor_arrays_TEMP;\n" >> $SQL2
    echo -e "--6) RUN THE FIND DUPS QUERY AGAIN TO VERIFY THAT ALL DUPS HAVE BEEN CLEARED" >> $SQL2
    echo -e "--7) CLEANUP TEMP TABLES ONCE EVERYTHING LOOKS GOOD" >> $SQL2
    echo -e "drop table ${schemamain}.eventor_arrays_TEMP;" >> $SQL2
    echo -e "\n" >> $SQL2
    
}



# ASK FOR THE PW FOR THE CLUSTER ONCE TO BE USED BY THE QUERIES
getPW ()
 {
  echo -en "Password for ${GREEN}${cluster}:\n"
  read -s clusterpw
  export CLPWD="${clusterpw}"
  tput init #resets the color terminal back
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
        AND table_name   = 'event_checks'
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
        AND table_name   = 'eventor_checks'
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
        AND table_name   = 'event_arrays'
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
        AND table_name   = 'eventor_arrays'
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
         event_id)
          echo -e "$column,";;
	   eventor_id)
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
             event_id)
              echo "$column || '[|]' ||";;
           eventor_id)
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
             event_id)
              echo "$column || '[|]' ||";;
           eventor_id)
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
