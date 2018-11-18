#!/bin/bash
check=$(lsblk -ln | awk '{ print $1 }' | head -n1);
if [ "$check" = "xvda" ]; then
   mkfs.xfs -f /dev/xvdb
   mkfs.xfs -f /dev/xvdc
   mkfs.xfs -f /dev/xvdd
   mkdir /data
   mkdir /journal
   mkdir /log
   mount /dev/xvdb /data
   mount /dev/xvdc /journal
   mount /dev/xvdd /log
   echo "/dev/xvdb      /data   xfs    defaults,nofail        0       2" >> /etc/fstab
   echo "/dev/xvdc      /journal   xfs    defaults,nofail        0       2" >> /etc/fstab
   echo "/dev/xvdd      /log   xfs    defaults,nofail        0       2" >> /etc/fstab;
elif [ "$check" = "nvme0n1" ]; then
   mkfs.xfs /dev/nvme1n1
   mkfs.xfs /dev/nvme2n1
   mkdir /app
   mkdir /backup
   mount /dev/nvme1n1 /app
   mount /dev/nvme2n1 /backup
   echo "/dev/nvme1n1      /app   xfs    defaults,nofail        0       2" >> /etc/fstab
   echo "/dev/nvme2n1      /backup   xfs    defaults,nofail        0       2" >> /etc/fstab;
else
   echo "Either device does not exist";
fi >> /tmp/fix.log 2>&1
df -T >> /tmp/fix.log 2>&1
echo DONE >> /tmp/fix.log 2>&1