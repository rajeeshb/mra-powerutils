#!/bin/bash
CUSTOMER_ID=6160
S3_BUCKET=s3://tma-test-frankfurt
S3_INPUT_BASE=$S3_BUCKET/input
S3_OUTPUT_BASE=$S3_BUCKET/output
S3_SCRIPTS_BASE=$S3_BUCKET/scripts
INSTANCE_TYPE=m3.2xlarge
INSTANCE_COUNT=2

aws emr create-cluster \
  --ami-version 3.5.0 \
  --instance-groups   InstanceGroupType=MASTER,InstanceCount=1,InstanceType=$INSTANCE_TYPE   InstanceGroupType=CORE,InstanceCount=$INSTANCE_COUNT,InstanceType=$INSTANCE_TYPE \
  --log-uri s3://tma-test-frankfurt/log \
  --service-role EMR_DefaultRole \
  --ec2-attributes   InstanceProfile=EMR_EC2_DefaultRole,SubnetId=subnet-6dfd1c16 \
  --bootstrap-actions Path=s3://eu-central-1.elasticmapreduce/bootstrap-actions/configure-hadoop,Name=EnableConsistentViewinEMRFS,Args=[-e,fs.s3.enableServerSideEncryption=true] \
  --steps Name=Pigprogram,Jar=s3://eu-central-1.elasticmapreduce/libs/script-runner/script-runner.jar,ActionOnFailure=CONTINUE,Args=[s3://eu-central-1.elasticmapreduce/libs/pig/pig-script,--run-pig-script,--pig-versions,latest,--args,-f,$S3_SCRIPTS_BASE/ETL_OnboardHistory_02_populate_dim_tables_first_run.pig,-p,INPUT=$S3_INPUT_BASE/test_cust,-p,OUTPUT=$S3_OUTPUT_BASE/test_cust_$CUSTOMER_ID,-p,cust_nbr=$CUSTOMER_ID]

