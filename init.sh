#!/bin/sh
#set -e
set -x

rm -f /etc/ceph/*

pkill -9 ceph-mon
pkill -9 ceph-osd
pkill -9 ceph-mds

mkdir -p /var/lib/ceph
mkdir -p /var/lib/ceph/osd
mkdir -p /var/lib/ceph/osd/ceph-0

# create a loopback disk for osd
# dd if=/dev/zero of=/osd.disk bs=128M count=10 conv=notrunc
# mkfs -t xfs -f /osd.disk
# mount -t xfs -o loop /osd.disk /var/lib/ceph/osd/ceph-0

MASTER=`hostname -s`

ip=$(ip -4 -o a | grep eth0 | awk '{print $4}' | cut -d'/' -f1)
echo "$ip $MASTER" >> /etc/hosts

#create ceph cluster
ceph-deploy --overwrite-conf new ${MASTER}  
ceph-deploy --overwrite-conf mon create-initial ${MASTER}
ceph-deploy --overwrite-conf mon create ${MASTER}

ceph-deploy  gatherkeys ${MASTER}  

echo "osd crush chooseleaf type = 0" >> /etc/ceph/ceph.conf
echo "osd journal size = 100" >> /etc/ceph/ceph.conf
echo "osd pool default size = 1" >> /etc/ceph/ceph.conf
echo "osd pool default pgp num = 8" >> /etc/ceph/ceph.conf
echo "osd pool default pg num = 8" >> /etc/ceph/ceph.conf

/sbin/service ceph -c /etc/ceph/ceph.conf stop mon.${MASTER}
/sbin/service ceph -c /etc/ceph/ceph.conf start mon.${MASTER}

# ceph osd pool set rbd size 1

ceph osd create
ceph-osd -i 0 --mkfs --mkkey
ceph auth add osd.0 osd 'allow *' mon 'allow rwx' -i /var/lib/ceph/osd/ceph-0/keyring
ceph osd crush add 0 1 root=default host=${MASTER}
ceph-osd -i 0 -k /var/lib/ceph/osd/ceph-0/keyring

#see if we are ready to go  
ceph osd tree  

# create ceph fs
ceph osd pool create cephfs_data 4
ceph osd pool create cephfs_metadata 4
ceph fs new cephfs cephfs_metadata cephfs_data
ceph-deploy --overwrite-conf mds create ${MASTER}

#create pool for kubernets test
ceph osd pool create kube 4
rbd create foo --size 10 --pool kube

ps -ef |grep ceph
ceph osd dump
#sleep 30

# add new client with a pre defined keyring
cat > /etc/ceph/ceph.client.kube.keyring <<EOF
[client.kube]
        key = AQAMgXhVwBCeDhAA9nlPaFyfUSatGD4drFWDvQ==
        caps mds = "allow rwx"
        caps mon = "allow rwx"
        caps osd = "allow rwx"
EOF
ceph auth import -i /etc/ceph/ceph.client.kube.keyring

bash
