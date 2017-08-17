#!/usr/local/bin/bash

set -e 
#set -x

if [[ $# != 1 ]]; then
   echo "Usage: $0 <version> " 2>&1
   echo "Example: $0 1.0.48" 2>&1
   exit 1
fi

version="$1"

#MAIN
mkdir -p /tmp/emr-deploy
cd /tmp/emr-deploy
wget http://lexus-repo.dev.ops.foo.com:8081/lexus/content/repositories/releases/com/foobar/data_lake/${version}/data_lake-${version}-jar-with-dependencies.jar 
mv data_lake-${version}-jar-with-dependencies.jar bisitor-stream-processor.jar
for r in eu-central-1 eu-west-1 us-east-1 ap-northeast-1 ap-southeast-2; do aws --profile foobar-prod --region $r s3 cp bisitor-stream-processor.jar s3://prod-bisitors-${r}.foobar.com/bin/;done
for r in eu-central-1 eu-west-1 us-east-1 ap-northeast-1 ap-southeast-2; do aws --profile foobar-prod --region $r s3 ls s3://prod-bisitors-${r}.foobar.com/bin/bisitor-stream-processor.jar;done

#set +x
