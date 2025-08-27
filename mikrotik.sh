#!/bin/bash
PASSWORD=$1
SERVICE=$2

VALID=("Mikrotik" "mikrotik" "Mikrotik CHR")


if [[ ! " ${VALID[@]} " =~ " ${SERVICE} " ]]; then
    echo "None Mikrotik"
    exit 1
fi


interface=$(ls /sys/class/net | head -n 1)
DISK=$(lsblk -d -n -o NAME | grep -E '^(sda|vda)$')

wget https://download.mikrotik.com/routeros/7.19.4/chr-7.19.4.img.zip -O chr.img.zip  && \
gunzip -c chr.img.zip > chr.img  && \
apt-get update && \
DEBIAN_FRONTEND=noninteractive apt install -y qemu-utils pv && \
qemu-img convert chr.img -O qcow2 chr.qcow2 && \
qemu-img resize chr.qcow2 1073741824 && \
modprobe nbd && \
qemu-nbd -c /dev/nbd0 chr.qcow2 && \
sleep 2 && \
partprobe /dev/nbd0 && \
sleep 5 && \
mount /dev/nbd0p2 /mnt && \
ADDRESS=`ip addr show $interface | grep global | cut -d' ' -f 6 | head -n 1` && \
GATEWAY=`ip route list | grep default | cut -d' ' -f 3` && \
echo "/ip address add address=$ADDRESS interface=[/interface ethernet find where name=ether1]
/ip route add gateway=$GATEWAY
/ip service disable telnet
/user set 0 name=admin password=$PASSWORD
/ip dns set servers=1.1.1.1,1.0.0.1
/system package update install
 " > /mnt/rw/autorun.scr && \
umount /mnt && \
echo -e 'd\n2\nn\np\n2\n65537\n\nw\n' | fdisk /dev/nbd0 && \
e2fsck -f -y /dev/nbd0p2 || true && \
resize2fs /dev/nbd0p2 && \
sleep 1 && \
mount -t tmpfs tmpfs /mnt && \
pv /dev/nbd0 | gzip > /mnt/chr-extended.gz && \
sleep 1 && \
killall qemu-nbd && \
sleep 1 && \
echo u > /proc/sysrq-trigger && \
sleep 1 && \
zcat /mnt/chr-extended.gz | pv > /dev/$DISK && \
sleep 5 || true && \
echo s > /proc/sysrq-trigger && \
echo b > /proc/sysrq-trigger
