#!/bin/bash
##################################################
# set password_hash to be same as profile/user
# change last profile to profile/user
# change last mycloud_profile to profile/user
# add profile/user to permissions
# remove activation code
# set status active
#
# password_hash = echo -n <user> | sha256sum

### REMEMBER ###
# change mongo
# change shasum
##################################################

# commands we're going to use
_tput=$(which tput)
green=$(${_tput} setaf 2)
cr=$(${_tput} sgr 0)

_mongo='/usr/bin/mongo --quiet --norc'  # linux
#_mongo='/usr/local/bin/mongo --quiet --norc' # darwin

# static variables
account='myapplication'
user_prefix='foobar'
user_min='001'
user_max='600'
domain='@foo.co'
db='foo'

debug_test()
{
  echo "user is       == ${user}"
  echo "account is    == ${account}"
  echo "profile is    == ${profile}"
  echo "pass hash is  == ${password_hash}"
  echo "user email is == ${email}"
}

create_hash()
{
  echo -n ${1} | /usr/bin/sha256sum | cut -d" " -f1    # linux
#  echo -n "${1}" | /usr/bin/shasum -a 256 | cut -d" " -f1    # darwin
}

# set the users password
set_password()
{
  ${_mongo} ${db} <<EOF
    db.users.update(
      {email: "${email}"},
        {\$set:
          {password_hash: "${password_hash}"}
        }
    )
EOF
}

# set user last account_profile
set_history()
{
  ${_mongo} ${db} <<EOF
    db.foo.update(
      {email: "${email}"},
        {\$set:
          {history: {
            last_mycloud_account: "${account}",
            last_mycloud_profile: "${profile}",
            last_account: "${account}",
            last_profile: "${profile}" }
          }
        }
    )
EOF
}

set_permissions()
{
  # set user permissions
  ${_mongo} ${db} <<EOF
    db.foo.update(
      {email: "${email}"},
        {\$set:
          {permissions: [
            "mydomain:accounts:myapplication:read",
            "mydomain:accounts:myapplication:extensions:javascript:edit",
            "mydomain:accounts:myapplication:profiles:${profile}:read",
            "mydomain:accounts:myapplication:profiles:${profile}:secure_labels:edit",
            "mydomain:accounts:myapplication:profiles:${profile}:edit",
            "mydomain:accounts:myapplication:profiles:${profile}:templates:*",
            "mydomain:accounts:myapplication:profiles:${profile}:publish_targets:qa:publish",
            "mydomain:accounts:myapplication:profiles:${profile}:publish_targets:prod:publish",
            "mydomain:accounts:myapplication:profiles:${profile}:copy",
            "mydomain:accounts:myapplication:profiles:${profile}:publish_targets:dev:publish"]}
        }
    )
EOF
}

unset_activation_code()
{
  # unset the activation code
  ${_mongo} ${db} <<EOF
    db.users.update(
      {email: "${email}"},
        {\$unset:
          {activation_code: ''}
        }
    )
EOF
}

set_user_status()
{
  # set the user status to active
  ${_mongo} ${db} <<EOF
    db.foo.update(
      {email: "${email}"},
        {\$set:
          {status: 'active'}
        }
    )
EOF
}

# main
main()
{
  for i in $(seq -w ${user_min} ${user_max}); do
    local user="${user_prefix}${i}"
    local profile="${user}"
    local email="${user}${domain}"
    password_hash=$(create_hash "${user}")

    echo "${green}${email}${cr}"
    #set_password
    #set_history
    set_permissions
    #unset_activation_code
    #set_user_status

    #debug_test
  done
}

# call main function
#main
