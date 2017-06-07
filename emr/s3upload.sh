#!/bin/bash

SOURCE=$1
if [ -z $SOURCE ]; then exit 1; fi

S3_BUCKET=s3://tma_test_frankfurt

aws s3 cp --acl private --sse --storage-class REDUCED_REDUNDANCY $SOURCEDIR $S3_BUCKET

# --recursive --exclude "*" --include "*.gz"

