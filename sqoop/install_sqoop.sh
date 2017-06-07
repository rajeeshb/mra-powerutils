#!/bin/bash
# Install sqoop and postgresql connector. Store in s3 and load 
# as bootstrap step. 

set -e

## local variables
#bucket_location=s3://tma-etl-scripts/nextgen
bucket_location=$1

if [ -z "$bucket_location" ]; then
  echo bucket location not specified
  exit 1
fi

sqoop_version=1.4.6
sqoop_tgz=sqoop-$sqoop_version.bin__hadoop-2.0.4-alpha.tar.gz
sqoop_dir=sqoop-$sqoop_version.bin__hadoop-2.0.4-alpha
postgresql_jar=postgresql-9.4-1201.jdbc41.jar

## download from s3
aws s3 cp $bucket_location/$sqoop_tgz .
aws s3 cp $bucket_location/$postgresql_jar .

## unpack sqoop
tar -zpxvf $sqoop_tgz

## copy postgresql jar to $sqoop_dir/lib/
cp $postgresql_jar $sqoop_dir/lib/

## create symlink
ln -s $(pwd)/$sqoop_dir $HADOOP_HOME/sqoop

