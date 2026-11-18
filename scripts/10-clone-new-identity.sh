#!/bin/bash
# Step 1.12 - give a cloned RHEL VM its own identity ("sysprep" for RHEL). Run as root on the CLONE.
# Usage: ./10-clone-new-identity.sh rhel02.lab.example.com 192.168.31.12/24 <ORG_ID> <ACTIVATION_KEY>
set -euo pipefail
NAME=$1; IP=$2; ORG=$3; KEY=$4
subscription-manager clean          # local only. Do NOT 'unregister': the clone shares the source's identity
subscription-manager register --org "$ORG" --activationkey "$KEY" --name "$NAME"
rm -f /etc/machine-id && systemd-machine-id-setup
rm -f /etc/ssh/ssh_host_* && ssh-keygen -A && restorecon -R /etc/ssh && systemctl restart sshd
hostnamectl set-hostname "$NAME"
nmcli con mod ens160 ipv4.addresses "$IP" && nmcli con up ens160
