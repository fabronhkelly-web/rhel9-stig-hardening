#!/bin/bash
# Step 1.5 - groups, users, least-privilege sudo, password aging, account lockout (run as root)
set -euo pipefail
groupadd -f sysadmins
id jdoe  &>/dev/null || useradd -m -c "Jane Operator" -G sysadmins jdoe
id webop &>/dev/null || useradd -m -c "Web Operator" webop
# set passwords interactively: passwd jdoe ; passwd webop

cat > /etc/sudoers.d/10-sysadmins <<'S'
%sysadmins   ALL=(ALL)   ALL
webop        ALL=(root)  /usr/bin/systemctl restart httpd, /usr/bin/systemctl status httpd
S
chmod 440 /etc/sudoers.d/10-sysadmins
visudo -c                                   # a sudoers syntax error can lock every admin out

chage -M 60 -m 1 -W 7 jdoe                  # STIG password aging
authselect enable-feature with-faillock
sed -i -E 's/^#? *deny *=.*/deny = 3/; s/^#? *fail_interval *=.*/fail_interval = 900/; s/^#? *unlock_time *=.*/unlock_time = 0/' /etc/security/faillock.conf
grep -E '^(deny|fail_interval|unlock_time)' /etc/security/faillock.conf

# Test: as webop, `sudo cat /etc/shadow` is denied and logged in /var/log/secure
# Test: 3 bad SSH passwords for jdoe -> `faillock --user jdoe` shows the lock; `faillock --user jdoe --reset` unlocks
