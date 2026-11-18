#!/bin/bash
# Step 1.4 - verify a fresh RHEL 9 build (read-only checks)
hostnamectl
cat /etc/redhat-release
ip -br a; ip r
lsblk
sudo vgs; sudo lvs
df -hT
getenforce
systemctl get-default
