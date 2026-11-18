#!/bin/bash
# CAT I: GRUB2 password + non-default superuser (RHEL-09-212010 / 212020).
# The SCAP content has NO automated fix for the superuser name, so it's done by hand.
set -euo pipefail
grub2-setpassword                                   # interactive; stored as PBKDF2 in /boot/grub2/user.cfg (0600)
cp -a /etc/grub.d/01_users /root/01_users.bak
sed -i 's/superusers="root"/superusers="bootadmin"/; s/password_pbkdf2 root /password_pbkdf2 bootadmin /' /etc/grub.d/01_users
grub2-mkconfig -o /boot/grub2/grub.cfg
grep -E "superusers|password_pbkdf2" /boot/grub2/grub.cfg
echo "Take a snapshot, then reboot to prove it still boots."
