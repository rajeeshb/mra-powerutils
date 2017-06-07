#!/usr/local/bin/bash

# Setup colors and color reset
_tput='/usr/bin/tput'
black=$(${_tput} setaf 0)
red=$(${_tput} setaf 1)
green=$(${_tput} setaf 2)
yellow=$(${_tput} setaf 3)
blue=$(${_tput} setaf 4)
magenta=$(${_tput} setaf 5)
cyan=$(${_tput} setaf 6)
white=$(${_tput} setaf 7)
cr=$(${_tput} sgr 0)

# A shortcut to using knife ssh interactive
# Usage: ksshi "role:*component* AND ec2_region:us-east-1"
ksshi ()
{
   local _knife="$(which knife)";
   local regex1='^chef_environ';
   local regex2='^prod*|^qa*|^env1*|^env2* AND';
   local search_default="chef_environment:production AND ${1}";
   local search_env="chef_environment:${1}";
   local att='';
   if [[ ${1} =~ ${regex1} ]]; then
   	att="${1}";
   else
      if [[ ${1} =~ ${regex2} ]]; then
          att="${search_env}";
      else
          att="${search_default}";
      fi;
   fi;
   cd /path_to_your_chef_keys/.chef;
   echo "${green}$(basename ${_knife}) ssh \"${att}\" interactive -x myname -a ec2.local_ipv4${cr}";
   ${_knife} ssh "${att}" interactive -x myname -a ec2.local_ipv4
}
