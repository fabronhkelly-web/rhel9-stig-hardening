#!/bin/bash
# Step 1.6 - new volume group on a second disk, mount by UUID, grow /var/log online
set -euo pipefail
DISK=${1:-/dev/nvme0n2}
pvcreate "$DISK"
vgcreate datavg "$DISK"
lvcreate -y -n datalv -L 6G datavg
mkfs.xfs /dev/datavg/datalv
mkdir -p /data
UUID=$(blkid -s UUID -o value /dev/datavg/datalv)
echo "UUID=$UUID  /data  xfs  defaults,nodev,nosuid  0 0" >> /etc/fstab
systemctl daemon-reload && mount -a && df -hT /data

lvextend -r -L +1G /dev/rhel/var_log        # -r grows XFS too, no downtime (XFS can grow, not shrink)
df -h /var/log
