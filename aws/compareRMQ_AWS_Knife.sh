#!/usr/local/bin/bash

#set -x

#
# FUNCTION: Good example script showing how to compare lists of node ids from rmq
#           and comparing them to knife search and aws cli query 
#

# COLORIZE OUTPUT
# Use with echo -e: "-e" escapes the backlash
RED="\033[0;31m"
YELLOW="\033[0;33m"
GREEN="\033[0;32m"
BLUE="\033[0;34m"
NC="\033[0m"

# Usage for getopts
usage () {
    echo -e "${BLUE}Usage:${GREEN}$0 -r region -c <component>"
    echo -e "${BLUE}Available components:"
    echo -e "${GREEN}customer_action|customer_help|historic_customer_action|actionstream_action|action_workflow"
    echo -e "${BLUE}Example:${GREEN}$0 -r ${YELLOW}us-east-1 ${GREEN}-c ${YELLOW}customer_action"
}

while getopts ":r:c:" opt; do
  case $opt in
    r) region="$OPTARG";;
    c) component="$OPTARG"
       if [[ ${component} != @(customer_action|customer_help|historic_customer_action|actionstream_action|action_workflow) ]]; then 
         usage
         exit 1
       fi
       ;;
    *) usage
       exit 1
       ;;
  esac
done


#VARS
_rabbitjson=/tmp/rabbit.json
_rabbitout=/tmp/rabbit.out
_knifeoutput=/tmp/knifeoutput.out
_awsout=/tmp/aws.out

#Curl command to get queues
curlRabbit(){
      curl -s -u yourusername:password http://${region}.cluster.rabbitmq.myapplication.com:15672/api/queues/ > ${_rabbitjson}
      #Extract the version numbers and read them into a Bash array.
      readarray -t queuenames < <(jq -r '.[].name' ${_rabbitjson})

      #Using a case statement for specific components which use "dc_" and those that do not
      case "${component}" in
      customer_action)
             printf '%s\n' "${queuenames[@]}" | grep "^${component}" | sort | cut -d '_' -f3 > ${_rabbitout}
      ;;
      customer_help)
             printf '%s\n' "${queuenames[@]}" | grep "^${component}" | sort | cut -d '_' -f3 > ${_rabbitout}
      ;;
      action_workflow)
             printf '%s\n' "${queuenames[@]}" | grep "^${component}" | sort | cut -d '_' -f3 > ${_rabbitout}
      ;;
      historic_customer_action) # 1 host has 2queues (rebalancecomplete, rebalancerequest)
             printf '%s\n' "${queuenames[@]}" | grep "${component}" | cut -d '_' -f8 | sort -u > ${_rabbitout}
      ;;
      actionstream_action)
             printf '%s\n' "${queuenames[@]}" | grep "${component}" | sort | cut -d '_' -f8 > ${_rabbitout}
      ;;
      *)
             printf '%s\n' "${queuenames[@]}" | grep "${component}" | sort | cut -d '_' -f3 > ${_rabbitout}
      ;;
      esac
      
      #Clean up
      rm "${_rabbitjson}"
}

#Use AWS CLI to create a list of instance ids
awsCLI(){
  case "${component}" in
  customer_help)
        cmd=$(aws \
          --profile tealium-prod \
          --region "${region}" ec2 describe-instances \
          --filter 'Name=tag:ChefRole,Values='"dc_${component}" \
          --query 'Reservations[].Instances[].[InstanceId,Tags[?Key==`Name`].Value[]]' \
          --output text \
        | sed '$!N;s/\n/ /' \
        | cut -d ' ' -f1 \
        | sort > "${_awsout}" \
        )
  ;;
  historic_customer_action)
        cmd=$(aws \
          --profile tealium-prod \
          --region "${region}" ec2 describe-instances \
          --filter 'Name=tag:ChefRole,Values='"dc_${component}" \
          --query 'Reservations[].Instances[].[InstanceId,Tags[?Key==`Name`].Value[]]' \
          --output text \
        | sed '$!N;s/\n/ /' \
        | cut -d ' ' -f1 \
        | sort > "${_awsout}" \
        )
  ;;
  action_workflow)
        cmd=$(aws \
          --profile tealium-prod \
          --region "${region}" ec2 describe-instances \
          --filter 'Name=tag:ChefRole,Values='"dc_${component}" \
          --query 'Reservations[].Instances[].[InstanceId,Tags[?Key==`Name`].Value[]]' \
          --output text \
        | sed '$!N;s/\n/ /' \
        | cut -d ' ' -f1 \
        | sort > "${_awsout}" \
        )
  ;;
  *)
        cmd=$(aws \
          --profile tealium-prod \
          --region "${region}" ec2 describe-instances \
          --filter 'Name=tag:ChefRole,Values='"${component}" \
          --query 'Reservations[].Instances[].[InstanceId,Tags[?Key==`Name`].Value[]]' \
          --output text \
        | sed '$!N;s/\n/ /' \
        | cut -d ' ' -f1 \
        | sort > "${_awsout}" \
        )
  ;;
  esac
}


knifeCLI(){
  local _knife="$(which knife)";
  cd /Users/user/Documents/yourknifecookboookpath/.chef;
  case "${component}" in
  historic_customer_action)
    ${_knife} search "chef_environment:production AND role:dc_${component} AND ec2_region:${region}" \
  | grep "Node" \
  | cut -d ' ' -f5 \
  | sort > "${_knifeoutput}" 
  ;;
  action_workflow)
    ${_knife} search "chef_environment:production AND role:dc_${component} AND ec2_region:${region}" \
  | grep "Node" \
  | cut -d ' ' -f5 \
  | sort > "${_knifeoutput}" 
  ;;
  customer_help)
    ${_knife} search "chef_environment:production AND role:dc_${component} AND ec2_region:${region}" \
  | grep "Node" \
  | cut -d ' ' -f5 \
  | sort > "${_knifeoutput}" 
  ;;
  *)
    ${_knife} search "chef_environment:production AND role:${component} AND ec2_region:${region}" \
  | grep "Node" \
  | cut -d ' ' -f5 \
  | sort > "${_knifeoutput}" 
  ;;
  esac
}


#For side-by-side column list with diff
diffFiles(){
    local _diff="$(which diff)";  
    echo -e "${GREEN}========================DIFF BETWEEN RABBIT AND AWS================================${GREEN}"
    ${_diff} -y ${_rabbitout} ${_awsout}
    echo -e "${GREEN}========================DIFF BETWEEN RABBIT AND KNIFE SEARCH=======================${GREEN}"
    ${_diff} -y ${_rabbitout} ${_knifeoutput}
}


#EXECUTE MAIN
rm -f ${_rabbitout} ${_awsout} {_knifeoutput}
curlRabbit
awsCLI
knifeCLI
diffFiles

#set +x