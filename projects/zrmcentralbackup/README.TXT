# getzrmlogs.sh works with the prodhosts.txt file
# called by crontab as such: **note the use of '{}' to loop in the prodhosts.txt file

#Gets copy of log files on all asdback servers 
0 1-23 * * * xargs -I{} sh /home/mysql/dev/getzrmlogs.sh {} </home/mysql/dev/prodhosts.txt  >> /home/mysql/dev/getzrmlogs.log 2>&1

