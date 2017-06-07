#!/bin/bash

set -e

if [[ $# != 2 ]]; then
   echo "Usage:   ./crDimDateRecs.sh <STARTDATE> <daysout>" 2>&1
   echo "Example: ./crDimDateRecs.sh 2016-03-09 365" 2>&1
   exit 1
fi

#DATE=2016-03-09
DATE="$1"

SQL="addonDimDate.sql"

for (( c=0; c<=$2; c++ ))
do
  #%D - date; same as %m/%d/%y
  #%V - ISO week number, with Monday as first day of week (01..53)
  #%m - month (01..12)
  #%b - locale's abbreviated month name (e.g., Jan)
  #%G - year of ISO week number (see %V); normally useful only with %V
  #%u - day of week (1..7); 1 is Monday
  #%A - locale's full weekday name (e.g., Sunday)

  #Get day loop, use this to create a unique date key
  DT_NONISO=$(date -d "$DATE + $c day" +%Y%m%d)

  #Date as YYYY-MM-DD
  DT_FMT=$(date -d "$DATE + $c day" +%Y-%m-%d)
  
  #Create ISO date
  DT_ISO=$(date -d "$DATE + $c day" +%G%m%d)
  
  #This will give us quarter.  
  GET_QTR=$(($(($((10#$(date -d "$DATE + $c day" +%m))) - 1)) / 3 + 1))
  
  #Get ISO data
  #ISO_DATE=$(date -d "$DATE + $c day" +$DT_ISO,%D,%V,%m,%b,$GET_QTR,%G,%u,%A)
  #ISO_DATE=$(date -d "$DATE + $c day" +$DT_NONISO,$DT_FMT,%V,%m,%b,$GET_QTR,%G,%u,%A)
  ISO_DATE2=$(date -d "$DATE + $c day" +$DT_NONISO,"'$DT_FMT'",%V,%m,"'%B'",$GET_QTR,%G,%u,"'%A'")

  #echo $DT_NONISO:$ISO_DATE #concatenated to see DT_NONISO side-by-side for troubleshooting

  #Outputs our ISO DATE string
  #echo $ISO_DATE
  #echo $ISO_DATE2
  echo "INSERT INTO dim_date (date_key, calendar_date, week_number, month_number, month_name, quarter_number, calendar_year, iso_dayofweek, dayofweek_name_en) VALUES ($ISO_DATE2);" | tee >> $SQL
done

# Sample rec to emulate
# (20151228, '2015-12-28', 53, 12, 'December', 4, 2015, 1, 'Monday');
