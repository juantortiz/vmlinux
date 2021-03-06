#!/bin/bash

mkfs.ext4 /dev/sdb1
pvcreate /dev/sdb2
vgcreate new /dev/sdb2
lvcreate -n nswap -L 4G /dev/new
lvcreate -n nroot -l 100%FREE /dev/new
mkswap /dev/new/nswap
mkfs.xfs /dev/new/nroot
sleep 10
lsblk -f

mkdir temporal
mount /dev/new/nroot /root/temporal
mkdir dump
xfsdump -0uf /root/dump/root.dump /dev/cl/root
xfsrestore -f /root/dump/root.dump /root/temporal

#vi (/etc/fstab) and -> (root/temporal/etc/fstab)
cp /etc/fstab /etc/fstab.bck
$UUID_SDB1=lsblk -f | grep sdb1 | awk '{print $3}'

echo "/dev/new/nroot     /                       xfs     defaults        0 0" > /etc/fstab
echo "UUID=5c42a381-8901-4558-8cf8-c2716ea67241 /boot                   ext4    defaults        1 1" >> /etc/fstab
echo "/dev/new/nswap     swap                    swap    defaults        0 0" >> /etc/fstab

cp /etc/fstab /root/temporal/etc/fstab
#/dev/new/nroot     /                       xfs     defaults        0 0
#UUID=c14be769-fc1d-4058-838b-b310876d5eac /boot                   ext4    defaults        1 1
#/dev/new/nswap     swap                    swap    defaults        0 0

vi /etc/default/grub
GRUB_CMDLINE_LINUX="crashkernel=auto resume=/dev/new/nswap rd.lvm.lv=new/nroot rd.lvm.lv=new/nswap rhgb quiet"

umount /root/temporal
mount /dev/new/nroot /
mount -o rw,remount /
grub2-mkconfig | grep nroot

reboot