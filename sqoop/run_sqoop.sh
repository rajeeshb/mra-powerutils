#!/bin/bash

set -e

if [[ $# != 6 ]]; then
   echo "Usage: ./runSqoopOnboard.sh <action> <customerid> <dirname> <output> <custrepohost> <pw>" 2>&1
   echo "Usage: ./runSqoopOnboard.sh APPEND 77777 20150721 s3://jp17etl-output01 jp17custrep01.cjhhxujoeooy.eu-central-1.rds.amazonaws.com password123" 2>&1
   exit 1
fi
 

# Setup VARS
HADOOP_BASE="/home/hadoop"
SQOOP_BIN="$HADOOP_HOME/sqoop/bin"
ACTION="$1"
DBOWNER="tma_dmc_$2"
S3DIR_NAME="$3"
S3DIR_OUT="$4"
S3DIR_BASE="$S3DIR_OUT/cust_$2"
JDBC_CUSTREP="jdbc:postgresql://$5:5432"
TMAPW="$6"
#########################################
# Differences between onboard and append#
#  '/table/current/'       - onboard    #
#  '/table/append/dirname/'- append     #
#########################################

FACT_EMAIL_OPENED_SQOOP_TABLE=fact_email_opened

if [[ $ACTION == "onboard" ]]; then
	S3DIR_VAR="current"
elif [[ $ACTION == "append" ]]; then
	S3DIR_VAR="append/$S3DIR_NAME"
	FACT_EMAIL_OPENED_SQOOP_TABLE=fact_email_opened_staging
else
	echo "Incorrect action"
	exit 1
fi

# DIM
S3DIR_DIM_BROWSER="dim_browser/$S3DIR_VAR/part{*} --table dim_browser --fields-terminated-by "\\\001" -- --schema tma_dev_wip_$2"
S3DIR_DIM_DEVICE="dim_device/$S3DIR_VAR/part{*} --table dim_device --fields-terminated-by "\\\001" -- --schema tma_dev_wip_$2"
S3DIR_DIM_EMAILCLIENT="dim_email_client/$S3DIR_VAR/part{*} --table dim_email_client --fields-terminated-by "\\\001" -- --schema tma_dev_wip_$2"
S3DIR_DIM_EMAILDOMAIN="dim_email_domain/$S3DIR_VAR/part{*} --table dim_email_domain --fields-terminated-by "\\\001" -- --schema tma_dev_wip_$2"
S3DIR_DIM_GEOG="dim_geography/$S3DIR_VAR/part{*} --table dim_geography --fields-terminated-by "\\\001" -- --schema tma_dev_wip_$2"
S3DIR_DIM_GROUP="dim_group/$S3DIR_VAR/part{*} --table dim_group --fields-terminated-by "\\\001" -- --schema tma_dev_wip_$2"
S3DIR_DIM_LINK="dim_link/$S3DIR_VAR/part{*} --table dim_link --fields-terminated-by "\\\001" -- --schema tma_dev_wip_$2"
S3DIR_DIM_MEMBER="dim_member/$S3DIR_VAR/part{*} --table dim_member --fields-terminated-by "\\\001" -- --schema tma_dev_wip_$2"
S3DIR_DIM_MESSAGE="dim_message/$S3DIR_VAR/part{*} --table dim_message --fields-terminated-by "\\\001" -- --schema tma_dev_wip_$2"
S3DIR_DIM_OS="dim_operating_system/$S3DIR_VAR/part{*} --table dim_operating_system --fields-terminated-by "\\\001" -- --schema tma_dev_wip_$2"



# FACT
S3DIR_FCT_EML_BNC="fact_email_bounces/$S3DIR_NAME/part{*} --table fact_email_bounces --fields-terminated-by "\\\001" -- --schema tma_dev_wip_$2"
S3DIR_FCT_EML_CLK="fact_email_clicked/$S3DIR_NAME/part{*} --table fact_email_clicked --fields-terminated-by "\\\001" -- --schema tma_dev_wip_$2"
S3DIR_FCT_EML_CNV="fact_email_conversions/$S3DIR_NAME/part{*} --table fact_email_conversions --fields-terminated-by "\\\001" -- --schema tma_dev_wip_$2"
S3DIR_FCT_EML_FWD="fact_email_forward/$S3DIR_NAME/part{*} --table fact_email_forward --fields-terminated-by "\\\001" -- --schema tma_dev_wip_$2"
S3DIR_FCT_EML_RDR="fact_email_render/$S3DIR_NAME/part{*} --table fact_email_render --fields-terminated-by "\\\001" -- --schema tma_dev_wip_$2"
S3DIR_FCT_EML_SND="fact_email_sends/$S3DIR_NAME/part{*} --table fact_email_sends --fields-terminated-by "\\\001" -- --schema tma_dev_wip_$2"
S3DIR_FCT_EML_SKP="fact_email_skipped/$S3DIR_NAME/part{*} --table fact_email_skipped --fields-terminated-by "\\\001" -- --schema tma_dev_wip_$2"
S3DIR_FCT_EML_SPM="fact_email_spam/$S3DIR_NAME/part{*} --table fact_email_spam --fields-terminated-by "\\\001" -- --schema tma_dev_wip_$2"
S3DIR_FCT_EML_UNS="fact_email_unsubs/$S3DIR_NAME/part{*} --table fact_email_unsubs --fields-terminated-by "\\\001" -- --schema tma_dev_wip_$2"
S3DIR_FCT_EML_OPN="fact_email_opened/current/part{*} --table $FACT_EMAIL_OPENED_SQOOP_TABLE --fields-terminated-by "\\\001" -- --schema tma_dev_wip_$2"

# (optional - commands have abs directory setup above)
cd $HADOOP_BASE

#Build command
$SQOOP_BIN/sqoop export --connect $JDBC_CUSTREP/$DBOWNER --username $DBOWNER --password $TMAPW --export-dir $S3DIR_BASE/$S3DIR_DIM_BROWSER
$SQOOP_BIN/sqoop export --connect $JDBC_CUSTREP/$DBOWNER --username $DBOWNER --password $TMAPW --export-dir $S3DIR_BASE/$S3DIR_DIM_DEVICE
$SQOOP_BIN/sqoop export --connect $JDBC_CUSTREP/$DBOWNER --username $DBOWNER --password $TMAPW --export-dir $S3DIR_BASE/$S3DIR_DIM_EMAILCLIENT
$SQOOP_BIN/sqoop export --connect $JDBC_CUSTREP/$DBOWNER --username $DBOWNER --password $TMAPW --export-dir $S3DIR_BASE/$S3DIR_DIM_EMAILDOMAIN
$SQOOP_BIN/sqoop export --connect $JDBC_CUSTREP/$DBOWNER --username $DBOWNER --password $TMAPW --export-dir $S3DIR_BASE/$S3DIR_DIM_GEOG
$SQOOP_BIN/sqoop export --connect $JDBC_CUSTREP/$DBOWNER --username $DBOWNER --password $TMAPW --export-dir $S3DIR_BASE/$S3DIR_DIM_GROUP
$SQOOP_BIN/sqoop export --connect $JDBC_CUSTREP/$DBOWNER --username $DBOWNER --password $TMAPW --export-dir $S3DIR_BASE/$S3DIR_DIM_LINK
$SQOOP_BIN/sqoop export --connect $JDBC_CUSTREP/$DBOWNER --username $DBOWNER --password $TMAPW --export-dir $S3DIR_BASE/$S3DIR_DIM_MEMBER
$SQOOP_BIN/sqoop export --connect $JDBC_CUSTREP/$DBOWNER --username $DBOWNER --password $TMAPW --export-dir $S3DIR_BASE/$S3DIR_DIM_MESSAGE
$SQOOP_BIN/sqoop export --connect $JDBC_CUSTREP/$DBOWNER --username $DBOWNER --password $TMAPW --export-dir $S3DIR_BASE/$S3DIR_DIM_OS

if [[ $ACTION == "onboard" ]]; then
    # Load static dims during onboard only
	S3DIR_DIM_BOUNCE_CATEGORY="dim_bounce_category/part{*} --table dim_bounce_category --fields-terminated-by "\\\001" -- --schema tma_dev_wip_$2"
	S3DIR_DIM_FEEDBACK="dim_feedback/part{*} --table dim_feedback --fields-terminated-by "\\\001" -- --schema tma_dev_wip_$2"
	S3DIR_DIM_SENDOUT_TYPE="dim_send_out_type/part{*} --table dim_send_out_type --fields-terminated-by "\\\001" -- --schema tma_dev_wip_$2"
	S3DIR_DIM_SKIP_CATEGORY="dim_skip_category/part{*} --table dim_skip_category --fields-terminated-by "\\\001" -- --schema tma_dev_wip_$2"

	$SQOOP_BIN/sqoop export --connect $JDBC_CUSTREP/$DBOWNER --username $DBOWNER --password $TMAPW --export-dir $S3DIR_BASE/$S3DIR_DIM_BOUNCE_CATEGORY
	$SQOOP_BIN/sqoop export --connect $JDBC_CUSTREP/$DBOWNER --username $DBOWNER --password $TMAPW --export-dir $S3DIR_BASE/$S3DIR_DIM_FEEDBACK
	$SQOOP_BIN/sqoop export --connect $JDBC_CUSTREP/$DBOWNER --username $DBOWNER --password $TMAPW --export-dir $S3DIR_BASE/$S3DIR_DIM_SENDOUT_TYPE
	$SQOOP_BIN/sqoop export --connect $JDBC_CUSTREP/$DBOWNER --username $DBOWNER --password $TMAPW --export-dir $S3DIR_BASE/$S3DIR_DIM_SKIP_CATEGORY
fi

#
#Build command
$SQOOP_BIN/sqoop export --connect $JDBC_CUSTREP/$DBOWNER --username $DBOWNER --password $TMAPW --num-mappers 10 --batch --export-dir $S3DIR_BASE/$S3DIR_FCT_EML_BNC
$SQOOP_BIN/sqoop export --connect $JDBC_CUSTREP/$DBOWNER --username $DBOWNER --password $TMAPW --num-mappers 10 --batch --export-dir $S3DIR_BASE/$S3DIR_FCT_EML_CLK
$SQOOP_BIN/sqoop export --connect $JDBC_CUSTREP/$DBOWNER --username $DBOWNER --password $TMAPW --num-mappers 10 --batch --export-dir $S3DIR_BASE/$S3DIR_FCT_EML_CNV
$SQOOP_BIN/sqoop export --connect $JDBC_CUSTREP/$DBOWNER --username $DBOWNER --password $TMAPW --num-mappers 10 --batch --export-dir $S3DIR_BASE/$S3DIR_FCT_EML_FWD
$SQOOP_BIN/sqoop export --connect $JDBC_CUSTREP/$DBOWNER --username $DBOWNER --password $TMAPW --num-mappers 10 --batch --export-dir $S3DIR_BASE/$S3DIR_FCT_EML_RDR
$SQOOP_BIN/sqoop export --connect $JDBC_CUSTREP/$DBOWNER --username $DBOWNER --password $TMAPW --num-mappers 10 --batch --export-dir $S3DIR_BASE/$S3DIR_FCT_EML_SND
$SQOOP_BIN/sqoop export --connect $JDBC_CUSTREP/$DBOWNER --username $DBOWNER --password $TMAPW --num-mappers 10 --batch --export-dir $S3DIR_BASE/$S3DIR_FCT_EML_SKP
$SQOOP_BIN/sqoop export --connect $JDBC_CUSTREP/$DBOWNER --username $DBOWNER --password $TMAPW --num-mappers 10 --batch --export-dir $S3DIR_BASE/$S3DIR_FCT_EML_SPM
$SQOOP_BIN/sqoop export --connect $JDBC_CUSTREP/$DBOWNER --username $DBOWNER --password $TMAPW --num-mappers 10 --batch --export-dir $S3DIR_BASE/$S3DIR_FCT_EML_UNS
$SQOOP_BIN/sqoop export --connect $JDBC_CUSTREP/$DBOWNER --username $DBOWNER --password $TMAPW --num-mappers 10 --batch --export-dir $S3DIR_BASE/$S3DIR_FCT_EML_OPN
