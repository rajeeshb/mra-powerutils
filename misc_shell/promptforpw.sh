#!/usr/local/bin/bash

#
# How to Prompt and Read Password
#
#echo -n Password: 
#read -s password
#echo
# Run Command
#echo $password

# Create a function for it
getPW ()
 {
  echo -n "Enter Password for cluster:"
  read -s clusterpw
  PGPASSWORD="${clusterpw}"
}

getPW

echo "Your cluster password is ${PGPASSWORD}"
