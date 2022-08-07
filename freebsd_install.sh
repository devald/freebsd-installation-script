#!/usr/bin/env sh

DISK1=$1
DISK2=$2

# Destroy the partitioning scheme
gpart destroy -F $DISK1
gpart destroy -F $DISK2
# Create the new partitioning scheme
gpart create -s GPT $DISK1
gpart create -s GPT $DISK2
# Add the freebsd-boot partition to the partitioning scheme
gpart add -a 4k -s 512K -t freebsd-boot -l gptboot0 $DISK1
gpart add -a 4k -s 512K -t freebsd-boot -l gptboot1 $DISK2
# Add the freebsd-swap partition to the partitioning scheme
gpart add -a 1m -s 2G -t freebsd-swap -l swap0 $DISK1
gpart add -a 1m -s 2G -t freebsd-swap -l swap1 $DISK2
# Add the freebsd-zfs partition to the partitioning scheme
gpart add -a 1m -t freebsd-zfs -l zfs0 $DISK1
gpart add -a 1m -t freebsd-zfs -l zfs1 $DISK2
# Write bootstrap code into the freebsd-boot partition
gpart bootcode -b /boot/pmbr -p /boot/gptzfsboot -i 1 $DISK1
gpart bootcode -b /boot/pmbr -p /boot/gptzfsboot -i 1 $DISK2

# Load geom_mirror.ko kernel module
kldload geom_mirror
# Mirror swap partitions
gmirror label -b load swap gpt/swap0 gpt/swap1

# Load zfs.ko kernel module
kldload zfs
# Create the zpool
zpool create -o altroot=/mnt -o ashift=12 -o autoexpand=on -O compress=lz4 -O atime=off -m none -f zroot mirror gpt/zfs0 gpt/zfs1
zfs create -o mountpoint=none zroot/ROOT
zfs create -o mountpoint=/ zroot/ROOT/default
zfs create -o mountpoint=/tmp -o exec=on -o setuid=off zroot/tmp
zfs create -o mountpoint=/usr -o canmount=off zroot/usr
zfs create zroot/usr/home
zfs create -o setuid=off zroot/usr/ports
zfs create zroot/usr/src
zfs create -o mountpoint=/var -o canmount=off zroot/var
zfs create -o exec=off -o setuid=off zroot/var/audit
zfs create -o exec=off -o setuid=off zroot/var/crash
zfs create -o exec=off -o setuid=off zroot/var/log
zfs create -o atime=on zroot/var/mail
zfs create -o setuid=off zroot/var/tmp
zfs set mountpoint=/zroot zroot
zpool set bootfs=zroot/ROOT/default zroot
zfs set canmount=noauto zroot/ROOT/default
# Mount all ZFS datasets and install FreeBSD
zfs mount -a
tar -xf /usr/freebsd-dist/base.txz -C /mnt
tar -xf /usr/freebsd-dist/kernel.txz -C /mnt
zpool set cachefile=/mnt/boot/zfs/zpool.cache zroot
# Create fstab
cat << EOF > /mnt/etc/fstab
# Device                Mountpoint      FStype  Options         Dump    Pass#
/dev/mirror/swap        none            swap    sw              0       0
EOF
# Create sysctl.conf
cat << EOF > /mnt/etc/sysctl.conf
kern.elf32.aslr.enable=1
kern.elf32.aslr.honor_sbrk=0
kern.elf32.aslr.pie_enable=1
kern.elf64.aslr.enable=1
kern.elf64.aslr.honor_sbrk=0
kern.elf64.aslr.pie_enable=1
kern.randompid=1
security.bsd.see_jail_proc=0
security.bsd.see_other_gids=0
security.bsd.see_other_uids=0
security.bsd.unprivileged_proc_debug=0
security.bsd.unprivileged_read_msgbuf=0
EOF
# Create rc.conf
cat << EOF > /mnt/etc/rc.conf
clear_tmp_enable="YES"
dumpdev="AUTO"
hostname="freebsd"
ifconfig_bge0="DHCP"
moused_ums0_enable="NO"
sendmail_enable="NONE"
sshd_enable="YES"
syslogd_flags="-ss"
zfs_enable="YES"
EOF
# Create loader.conf
cat << EOF > /mnt/boot/loader.conf
boot_multicons="YES"
boot_serial="YES"
console="comconsole,vidconsole"
geom_mirror_load="YES"
kern.geom.label.disk_ident.enable="0"
kern.geom.label.gptid.enable="0"
security.bsd.allow_destructive_dtrace=0
zfs_load="YES"
EOF
# Set timezone
chroot /mnt tzsetup Europe/Berlin
# Unmount all ZFS datasets
zfs unmount -a
# Export zpool
zpool export zroot

echo "Installation finished. Ready to reboot."
