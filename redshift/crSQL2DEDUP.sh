#!/usr/local/bin/bash

set -e
set -x

#
## USAGE FOR GETOPTS/PARAMS NEEDED FOR THIS PROGRAM:
#
usage () {
    echo "Usage: $0 -c cluster -d database -p profile -t ABC|XYZ"
    echo "Example: $0 -c cluster -d random -p main -t ABC"
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
SQL2="${tmpdir}/runDEDUP-customer_lists_and_tallies.sql"
# COLUMN OUTPUT FROM DB QUERIES
COLS1="${tmpdir}/visit_tallies.out"
COLS2="${tmpdir}/customer_tallies.out"
COLS3="${tmpdir}/visit_lists.out"
COLS4="${tmpdir}/customer_lists.out"



# CREATE THE DIRECTORY FOR THE FILE OUTPUTS
mkdir -p "${tmpdir}"

# OUTPUT THE INFORMATIVE DETAILS
echo "Redshift cluster:${cluster}"
echo "Customer:${database}"
echo "Schema:${schemamain}"
echo "Database to Dedup ${table}"

#
# QUERY REDSHIFT DB TO GRAB COLUMNS FOR ABC - TALLIES AND LISTS tables
# if we decide to pass in the password:
# PGPASSWORD=$SOURCE_PW "$PSQL" -h "${cluster}" -U masteruser -d "$database" -p 5439 << EOF
# 
"$PSQL" -h "${cluster}" -U masteruser -d "$database" -p 5439 << EOF
        \a
        \t
        \o $COLS1
        SELECT column_name
        FROM information_schema.columns
        WHERE table_schema = '$schemamain'
        AND table_name   = 'visit_tallies'
        order by ordinal_position;
EOF
"$PSQL" -h "${cluster}" -U masteruser -d "$database" -p 5439 << EOF
        \a
        \t
        \o $COLS2
        SELECT column_name
        FROM information_schema.columns
        WHERE table_schema = '$schemamain'
        AND table_name   = 'customer_tallies'
        order by ordinal_position;
EOF
"$PSQL" -h "${cluster}" -U masteruser -d "$database" -p 5439 << EOF
        \a
        \t
        \o $COLS3
        SELECT column_name
        FROM information_schema.columns
        WHERE table_schema = '$schemamain'
        AND table_name   = 'visit_lists'
        order by ordinal_position;
EOF
"$PSQL" -h "${cluster}" -U masteruser -d "$database" -p 5439 << EOF
        \a
        \t
        \o $COLS4
        SELECT column_name
        FROM information_schema.columns
        WHERE table_schema = '$schemamain'
        AND table_name   = 'customer_lists'
        order by ordinal_position;
EOF

#
# MAIN FUNCTIONS FOR THIS PROGRAM:
# crSEQUEL   - If type => ABC then it creates the dedup sql needed for these tables: (ACTIONS, CUSTOMERS, CUSTOMER_REPLACES, CUSTOMER_BATCHES)
#            - If type => XYZ then it creates the dedup sql needed for these tables: (actions__all_actions)
#
# crSEQUEL2 - function to create the dedup sql for: (VISIT_TALLIES, CUSTOMER_TALLIES, VISIT_LISTS, CUSTOMER_LISTS)
#

crSEQUEL()
{
 case "${type}" in 
 ABC)
    echo -e "/*###ACTIONS###*/" >> $SQL
    echo -e "--1) FIND OUT HOW MANY DUPS" >> $SQL
    echo -e "select count(*), min(updated), max(updated) \n from ( \n select updated \n from  \n ${schemamain}.clicks \n group by visit_id, updated \n having count(*) > 1 \n);" >> $SQL
    echo -e "\n" >> $SQL
    echo -e "--2) CREATE THE TEMP TABLE" >> $SQL
    echo -e "CREATE TABLE IF NOT EXISTS \n ${schemamain}.clicks_TEMP \n (LIKE  ${schemamain}.clicks INCLUDING DEFAULTS)\n;" >> $SQL
    echo -e "\n" >> $SQL
    echo -e "--3) COPY ROWS OF DUPES TO TEMP TABLE" >> $SQL
    echo -e "insert into ${schemamain}.clicks_TEMP \n (\n SELECT DISTINCT * from ${schemamain}.clicks where visit_id in\n (\n select visit_id from ${schemamain}.clicks group by visit_id, updated having count(*) > 1\n)\n);" >> $SQL
    echo -e "\n" >> $SQL
    echo -e "--4) DELETE DUPS FROM ORIGINAL TABLE" >> $SQL
    echo -e "delete from ${schemamain}.clicks\n WHERE visit_id in\n (\n select visit_id from ${schemamain}.clicks_TEMP\n);\n" >> $SQL
    echo -e "\n" >> $SQL
    echo -e "--5) COPY DE-DUPED ROWS BACK INTO ORIGINAL TABLE" >> $SQL
    echo -e "insert into ${schemamain}.clicks select * from ${schemamain}.clicks_TEMP;\n" >> $SQL
    echo -e "\n" >> $SQL
    echo -e "--6) RUN THE FIND DUPS QUERY AGAIN TO VERIFY THAT ALL DUPS HAVE BEEN CLEARED" >> $SQL

    echo -e "/*###CUSTOMERS###*/" >> $SQL
    echo -e "--1) FIND OUT HOW MANY DUPS" >> $SQL
    echo -e "select count(*), min(updated), max(updated) \n from ( \n select updated \n from  \n ${schemamain}.customers \n group by customer_id, updated \n having count(*) > 1 \n);" >> $SQL
    echo -e "\n" >> $SQL
    echo -e "--2) CREATE THE TEMP TABLE" >> $SQL
    echo -e "CREATE TABLE IF NOT EXISTS \n ${schemamain}.customers_TEMP \n (LIKE  ${schemamain}.customers INCLUDING DEFAULTS)\n;" >> $SQL
    echo -e "\n" >> $SQL
    echo -e "--3) COPY ROWS OF DUPES TO TEMP TABLE" >> $SQL
    echo -e "insert into ${schemamain}.customers_TEMP \n (\n SELECT DISTINCT * from ${schemamain}.customers where customer_id in\n (\n select customer_id from ${schemamain}.customers group by customer_id, updated having count(*) > 1\n)\n);" >> $SQL
    echo -e "\n" >> $SQL
    echo -e "--4) DELETE DUPS FROM ORIGINAL TABLE" >> $SQL
    echo -e "delete from ${schemamain}.customers\n WHERE customer_id in\n (\n select customer_id from ${schemamain}.customers_TEMP\n);\n" >> $SQL
    echo -e "\n" >> $SQL
    echo -e "--5) COPY DE-DUPED ROWS BACK INTO ORIGINAL TABLE" >> $SQL
    echo -e "insert into ${schemamain}.customers select * from ${schemamain}.customers_TEMP;\n" >> $SQL
    echo -e "\n" >> $SQL
    echo -e "--6) RUN THE FIND DUPS QUERY AGAIN TO VERIFY THAT ALL DUPS HAVE BEEN CLEARED" >> $SQL

    echo -e "/*###CUSTOMER_REPLACES###*/" >> $SQL
    echo -e "--1) FIND OUT HOW MANY DUPS" >> $SQL
    echo -e "select count(*), min(updated), max(updated) \n from ( \n select updated \n from  \n ${schemamain}.customer_replaces \n group by customer_replaces_id, updated \n having count(*) > 1 \n);" >> $SQL
    echo -e "\n" >> $SQL
    echo -e "--2) CREATE THE TEMP TABLE" >> $SQL
    echo -e "CREATE TABLE IF NOT EXISTS \n ${schemamain}.customer_replaces_TEMP \n (LIKE  ${schemamain}.customer_replaces INCLUDING DEFAULTS)\n;" >> $SQL
    echo -e "\n" >> $SQL
    echo -e "--3) COPY ROWS OF DUPES TO TEMP TABLE" >> $SQL
    echo -e "insert into ${schemamain}.customer_replaces_TEMP \n (\n SELECT DISTINCT * from ${schemamain}.customer_replaces where customer_replaces_id in\n (\n select customer_replaces_id from ${schemamain}.customer_replaces group by customer_replaces_id, updated having count(*) > 1\n)\n);" >> $SQL
    echo -e "\n" >> $SQL
    echo -e "--4) DELETE DUPS FROM ORIGINAL TABLE" >> $SQL
    echo -e "delete from ${schemamain}.customer_replaces\n WHERE customer_replaces_id in\n (\n select customer_replaces_id from ${schemamain}.customer_replaces_TEMP\n);\n" >> $SQL
    echo -e "\n" >> $SQL
    echo -e "--5) COPY DE-DUPED ROWS BACK INTO ORIGINAL TABLE" >> $SQL
    echo -e "insert into ${schemamain}.customer_replaces select * from ${schemamain}.customer_replaces_TEMP;\n" >> $SQL
    echo -e "\n" >> $SQL
    echo -e "--6) RUN THE FIND DUPS QUERY AGAIN TO VERIFY THAT ALL DUPS HAVE BEEN CLEARED" >> $SQL

    echo -e "/*###CUSTOMER_BATCHES###*/" >> $SQL
    echo -e "--1) FIND OUT HOW MANY DUPS" >> $SQL
    echo -e "select count(*), min(batch_time), max(batch_time) \n from ( \n select batch_time \n from  \n ${schemamain}.customer_batches \n group by customer_id, batch_time \n having count(*) > 1 \n);" >> $SQL
    echo -e "\n" >> $SQL
    echo -e "--2) CREATE THE TEMP TABLE" >> $SQL
    echo -e "CREATE TABLE IF NOT EXISTS \n ${schemamain}.customer_batches_TEMP \n (LIKE  ${schemamain}.customer_batches INCLUDING DEFAULTS)\n;" >> $SQL
    echo -e "\n" >> $SQL
    echo -e "insert into ${schemamain}.customer_batches_TEMP \n (\n SELECT DISTINCT * from ${schemamain}.customer_batches where customer_id in\n (\n select customer_id from ${schemamain}.customer_batches group by customer_id, batch_time having count(*) > 1\n)\n);" >> $SQL
    echo -e "\n" >> $SQL
    echo -e "--4) DELETE DUPS FROM ORIGINAL TABLE" >> $SQL
    echo -e "delete from ${schemamain}.customer_batches\n WHERE customer_id in\n (\n select customer_id from ${schemamain}.customer_batches_TEMP\n);\n" >> $SQL
    echo -e "\n" >> $SQL
    echo -e "--5) COPY DE-DUPED ROWS BACK INTO ORIGINAL TABLE" >> $SQL
    echo -e "insert into ${schemamain}.customer_batches select * from ${schemamain}.customer_batches_TEMP;\n" >> $SQL
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

    echo -e "Creating a separate sql script for list and tallies..."
    crSEQUEL2
    ;;
 XYZ)
    echo -e "/*### XYZ - EVENT TABLES TO DEDUP ###*/" >> $SQL
    echo -e "select count(*), min(eventtime), max(eventtime) \n from ( \n select eventtime \n from  \n ${schemamain}.actions__all_actions\n group by eventid, eventtime \n having count(*) > 1 \n);" >> $SQL
    echo -e "\n" >> $SQL
    echo -e "CREATE TABLE IF NOT EXISTS \n ${schemamain}.actions__all_actions_TEMP\n \n (LIKE  ${schemamain}.actions__all_actions\n INCLUDING DEFAULTS)\n;" >> $SQL
    echo -e "\n" >> $SQL
    echo -e "insert into ${schemamain}.actions__all_actions_TEMP \n (\n SELECT DISTINCT * from ${schemamain}.actions__all_actions where eventid in\n (\n select eventid from ${schemamain}.actions__all_actions group by eventid, eventtime having count(*) > 1\n)\n);" >> $SQL
    echo -e "\n" >> $SQL
    echo -e "delete from ${schemamain}.actions__all_actions\n WHERE eventid in\n (\n select eventid from ${schemamain}.actions__all_actions_TEMP\n);\n" >> $SQL
    echo -e "\n" >> $SQL
    echo -e "insert into ${schemamain}.actions__all_actions select * from ${schemamain}.actions__all_actions_TEMP;\n" >> $SQL
    echo -e "\n" >> $SQL
    echo -e "/*### CLEANUP TEMP TABLES ONCE EVERYTHING LOOKS GOOD ###*/" >> $SQL
    echo -e "drop table ${schemamain}.actions__all_actions_TEMP;" >> $SQL
    
    ;;
 *)
    echo -e "No sql. Check script for error" >> $SQL
    ;;
 esac
}


crSEQUEL2()
{
    echo -e "/*####VISIT_TALLIES####*/" >> $SQL2 
    echo -e "--1) FIND OUT HOW MANY DUPS" >> $SQL2
    echo -e "select count(*), min(updated), max(updated)\nfrom ( \nselect" >> $SQL2
    addFindDupsMD5 $COLS1 >> $SQL2
    echo -e "from  \n${schemamain}.visit_tallies \ngroup by md5sum, visit_id, updated having count(*) > 1);" >> $SQL2
    echo -e "\n" >> $SQL2
    echo -e "--2) CREATE THE TEMP TABLE" >> $SQL2
    echo -e "CREATE TABLE IF NOT EXISTS \n ${schemamain}.visit_tallies_TEMP \n (LIKE  ${schemamain}.visit_tallies INCLUDING DEFAULTS);" >> $SQL2
    echo -e "\n" >> $SQL2
    echo -e "ALTER TABLE ${schemamain}.visit_tallies_TEMP ADD COLUMN md5sum VARCHAR;" >> $SQL2
    echo -e "\n" >> $SQL2
    echo -e "--3) COPY ROWS OF DUPES TO TEMP TABLE" >> $SQL2
    echo -e "insert into ${schemamain}.visit_tallies_TEMP \n (\nSELECT *,\nmd5(" >> $SQL2
    addInsertTempMD5 $COLS1 >> $SQL2
    echo -e "from ${schemamain}.visit_tallies\n group by md5sum," >> $SQL2
    $PASTE -sd, "$COLS1" >> $SQL2
    echo -e "having count(*) > 1 \n);" >> $SQL2
    echo -e "\n" >> $SQL2
    echo -e "--4) DELETE DUPS FROM ORIGINAL TABLE" >> $SQL2
    echo -e "delete from ${schemamain}.visit_tallies \nWHERE (visit_id, updated,\n md5(" >> $SQL2
    addDeleteMD5 $COLS1 >> $SQL2	
    echo -e ") in (select visit_id, updated, md5sum from ${schemamain}.visit_tallies_TEMP);" >> $SQL2
    echo -e "\n" >> $SQL2
    echo -e "--5) COPY DE-DUPED ROWS BACK INTO ORIGINAL TABLE" >> $SQL2
    echo -e "insert into ${schemamain}.visit_tallies\nselect" >> $SQL2
    $PASTE -sd, "$COLS1" >> $SQL2
    echo -e "from ${schemamain}.visit_tallies_TEMP;\n" >> $SQL2
    echo -e "--6) RUN THE FIND DUPS QUERY AGAIN TO VERIFY THAT ALL DUPS HAVE BEEN CLEARED" >> $SQL2
    echo -e "--7) CLEANUP TEMP TABLES ONCE EVERYTHING LOOKS GOOD" >> $SQL2
    echo -e "drop table ${schemamain}.visit_tallies_TEMP;" >> $SQL2
    echo -e "\n" >> $SQL2

    echo -e "/*####CUSTOMER_TALLIES####*/" >> $SQL2 
    echo -e "--1) FIND OUT HOW MANY DUPS" >> $SQL2
    echo -e "select count(*), min(updated), max(updated)\nfrom ( \nselect" >> $SQL2
    addFindDupsMD5 $COLS2 >> $SQL2
    echo -e "from  \n${schemamain}.customer_tallies \ngroup by md5sum, customer_id, updated having count(*) > 1);" >> $SQL2
    echo -e "\n" >> $SQL2
    echo -e "--2) CREATE THE TEMP TABLE" >> $SQL2
    echo -e "CREATE TABLE IF NOT EXISTS \n ${schemamain}.customer_tallies_TEMP \n (LIKE  ${schemamain}.customer_tallies INCLUDING DEFAULTS);" >> $SQL2
    echo -e "\n" >> $SQL2
    echo -e "ALTER TABLE ${schemamain}.customer_tallies_TEMP ADD COLUMN md5sum VARCHAR;" >> $SQL2
    echo -e "\n" >> $SQL2
    echo -e "--3) COPY ROWS OF DUPES TO TEMP TABLE" >> $SQL2
    echo -e "insert into ${schemamain}.customer_tallies_TEMP \n (\nSELECT *,\nmd5(" >> $SQL2
    addInsertTempMD5 $COLS2 >> $SQL2
    echo -e "from ${schemamain}.customer_tallies\n group by md5sum," >> $SQL2
    $PASTE -sd, "$COLS2" >> $SQL2
    echo -e "having count(*) > 1 \n);" >> $SQL2
    echo -e "\n" >> $SQL2
    echo -e "--4) DELETE DUPS FROM ORIGINAL TABLE" >> $SQL2
    echo -e "delete from ${schemamain}.customer_tallies \nWHERE (customer_id, updated,\n md5(" >> $SQL2
    addDeleteMD5 $COLS2 >> $SQL2	
    echo -e ") in (select customer_id, updated, md5sum from ${schemamain}.customer_tallies_TEMP);" >> $SQL2
    echo -e "\n" >> $SQL2
    echo -e "--5) COPY DE-DUPED ROWS BACK INTO ORIGINAL TABLE" >> $SQL2
    echo -e "insert into ${schemamain}.customer_tallies\nselect" >> $SQL2
    $PASTE -sd, "$COLS2" >> $SQL2
    echo -e "from ${schemamain}.customer_tallies_TEMP;\n" >> $SQL2
    echo -e "--6) RUN THE FIND DUPS QUERY AGAIN TO VERIFY THAT ALL DUPS HAVE BEEN CLEARED" >> $SQL2
    echo -e "--7) CLEANUP TEMP TABLES ONCE EVERYTHING LOOKS GOOD" >> $SQL2
    echo -e "drop table ${schemamain}.customer_tallies_TEMP;" >> $SQL2
    echo -e "\n" >> $SQL2

    echo -e "/*####VISIT_LISTS####*/" >> $SQL2 
    echo -e "--1) FIND OUT HOW MANY DUPS" >> $SQL2
    echo -e "select count(*), min(updated), max(updated)\nfrom ( \nselect" >> $SQL2
    addFindDupsMD5 $COLS3 >> $SQL2
    echo -e "from  \n${schemamain}.visit_lists \ngroup by md5sum, visit_id, updated having count(*) > 1);" >> $SQL2
    echo -e "\n" >> $SQL2
    echo -e "--2) CREATE THE TEMP TABLE" >> $SQL2
    echo -e "CREATE TABLE IF NOT EXISTS \n ${schemamain}.visit_lists_TEMP \n (LIKE  ${schemamain}.visit_lists INCLUDING DEFAULTS);" >> $SQL2
    echo -e "\n" >> $SQL2
    echo -e "ALTER TABLE ${schemamain}.visit_lists_TEMP ADD COLUMN md5sum VARCHAR;" >> $SQL2
    echo -e "\n" >> $SQL2
    echo -e "--3) COPY ROWS OF DUPES TO TEMP TABLE" >> $SQL2
    echo -e "insert into ${schemamain}.visit_lists_TEMP \n (\nSELECT *,\nmd5(" >> $SQL2
    addInsertTempMD5 $COLS3 >> $SQL2
    echo -e "from ${schemamain}.visit_lists\n group by md5sum," >> $SQL2
    $PASTE -sd, "$COLS3" >> $SQL2
    echo -e "having count(*) > 1 \n);" >> $SQL2
    echo -e "\n" >> $SQL2
    echo -e "--4) DELETE DUPS FROM ORIGINAL TABLE" >> $SQL2
    echo -e "delete from ${schemamain}.visit_lists \nWHERE (visit_id, updated,\n md5(" >> $SQL2
    addDeleteMD5 $COLS3 >> $SQL2	
    echo -e ") in (select visit_id, updated, md5sum from ${schemamain}.visit_lists_TEMP);" >> $SQL2
    echo -e "\n" >> $SQL2
    echo -e "--5) COPY DE-DUPED ROWS BACK INTO ORIGINAL TABLE" >> $SQL2
    echo -e "insert into ${schemamain}.visit_lists\nselect" >> $SQL2
    $PASTE -sd, "$COLS3" >> $SQL2
    echo -e "from ${schemamain}.visit_lists_TEMP;\n" >> $SQL2
    echo -e "--6) RUN THE FIND DUPS QUERY AGAIN TO VERIFY THAT ALL DUPS HAVE BEEN CLEARED" >> $SQL2
    echo -e "--7) CLEANUP TEMP TABLES ONCE EVERYTHING LOOKS GOOD" >> $SQL2
    echo -e "drop table ${schemamain}.visit_lists_TEMP;" >> $SQL2
    echo -e "\n" >> $SQL2

    echo -e "/*####CUSTOMER_LISTS####*/" >> $SQL2 
    echo -e "--1) FIND OUT HOW MANY DUPS" >> $SQL2
    echo -e "select count(*), min(updated), max(updated)\nfrom ( \nselect" >> $SQL2
    addFindDupsMD5 $COLS4 >> $SQL2
    echo -e "from  \n${schemamain}.customer_lists \ngroup by md5sum, customer_id, updated having count(*) > 1);" >> $SQL2
    echo -e "\n" >> $SQL2
    echo -e "--2) CREATE THE TEMP TABLE" >> $SQL2
    echo -e "CREATE TABLE IF NOT EXISTS \n ${schemamain}.customer_lists_TEMP \n (LIKE  ${schemamain}.customer_lists INCLUDING DEFAULTS);" >> $SQL2
    echo -e "\n" >> $SQL2
    echo -e "ALTER TABLE ${schemamain}.customer_lists_TEMP ADD COLUMN md5sum VARCHAR;" >> $SQL2
    echo -e "\n" >> $SQL2
    echo -e "--3) COPY ROWS OF DUPES TO TEMP TABLE" >> $SQL2
    echo -e "insert into ${schemamain}.customer_lists_TEMP \n (\nSELECT *,\nmd5(" >> $SQL2
    addInsertTempMD5 $COLS4 >> $SQL2
    echo -e "from ${schemamain}.customer_lists\n group by md5sum," >> $SQL2
    $PASTE -sd, "$COLS4" >> $SQL2
    echo -e "having count(*) > 1 \n);" >> $SQL2
    echo -e "\n" >> $SQL2
    echo -e "--4) DELETE DUPS FROM ORIGINAL TABLE" >> $SQL2
    echo -e "delete from ${schemamain}.customer_lists \nWHERE (customer_id, updated,\n md5(" >> $SQL2
    addDeleteMD5 $COLS4 >> $SQL2	
    echo -e ") in (select customer_id, updated, md5sum from ${schemamain}.customer_lists_TEMP);" >> $SQL2
    echo -e "\n" >> $SQL2
    echo -e "--5) COPY DE-DUPED ROWS BACK INTO ORIGINAL TABLE" >> $SQL2
    echo -e "insert into ${schemamain}.customer_lists\nselect" >> $SQL2
    $PASTE -sd, "$COLS4" >> $SQL2
    echo -e "from ${schemamain}.customer_lists_TEMP;\n" >> $SQL2
    echo -e "--6) RUN THE FIND DUPS QUERY AGAIN TO VERIFY THAT ALL DUPS HAVE BEEN CLEARED" >> $SQL2
    echo -e "--7) CLEANUP TEMP TABLES ONCE EVERYTHING LOOKS GOOD" >> $SQL2
    echo -e "drop table ${schemamain}.customer_lists_TEMP;" >> $SQL2
    echo -e "\n" >> $SQL2
    
}

#
# PURPOSE:
# For every column other than the primary_key and timestamp column, we need to create a md5sum hash
# Each of the functions vary slightly to create the proper formatting for different queries 
#
addFindDupsMD5()
{
     file="$1"  
     linecount=$(wc -l <"$file" | awk '{ print $1 }')
     counter=1
     while IFS='' read -r column; do
	 case "$column" in
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
crSEQUEL

set +x
