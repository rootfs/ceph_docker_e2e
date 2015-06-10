#/bin/bash

docker build -t centos_ceph_pkg .

docker run --privileged --net=host -i -t  centos_ceph_pkg /bin/bash /init.sh

# test mount a ceph fs:
# mount -t ceph mon_ip:6789:/ /mnt -o name=kube,secret=AQAMgXhVwBCeDhAA9nlPaFyfUSatGD4drFWDvQ==
