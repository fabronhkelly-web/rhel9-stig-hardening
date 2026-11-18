#!/bin/bash
# Step 1.10 - manual STIG remediation (CAT I quick wins + guide items). Run as root.
set -euo pipefail
# DoD notice-and-consent banner, exact text from Red Hat's STIG content
./stig-fix-rule.sh banner_etc_issue

# SSH hardening (incl. CAT I: no empty passwords)
cat > /etc/ssh/sshd_config.d/00-stig.conf <<'C'
Banner /etc/issue
PermitRootLogin no
PermitEmptyPasswords no
ClientAliveInterval 600
ClientAliveCountMax 1
C
chmod 600 /etc/ssh/sshd_config.d/00-stig.conf
sshd -t && systemctl reload sshd

# Password complexity
for kv in "minlen = 15" "dcredit = -1" "ucredit = -1" "lcredit = -1" "ocredit = -1" "difok = 8"; do
  k=${kv%% *}; sed -i -E "/^#? *$k *=/d" /etc/security/pwquality.conf; echo "$kv" >> /etc/security/pwquality.conf
done

# Mount options (validate fstab before replacing it)
cp -a /etc/fstab /root/fstab.before-stig
awk '$2=="/tmp"||$2=="/var/tmp"||$2=="/home"||$2=="/var/log"||$2=="/var/log/audit"{$4="defaults,nodev,nosuid,noexec"} $2=="/boot"{$4="defaults,nodev,nosuid"} {print}' OFS='\t' /etc/fstab > /root/fstab.new
findmnt --verify --tab-file /root/fstab.new && cp /root/fstab.new /etc/fstab && systemctl daemon-reload
for m in /tmp /var/tmp /home /var/log /var/log/audit /boot; do mount -o remount $m; done

# STIG audit rules (1 -> 52 rules)
cp /usr/share/audit/sample-rules/30-stig.rules /etc/audit/rules.d/ && augenrules --load

# CAT I quick wins
authselect enable-feature without-nullok                       # no empty passwords in PAM
rm -f /etc/systemd/system/ctrl-alt-del.target && systemctl mask ctrl-alt-del.target
mkdir -p /etc/systemd/system.conf.d
printf '[Manager]\nCtrlAltDelBurstAction=none\n' > /etc/systemd/system.conf.d/00-stig-ctrlaltdel.conf
systemctl daemon-reexec
grep -q '^localpkg_gpgcheck' /etc/dnf/dnf.conf || echo 'localpkg_gpgcheck=1' >> /etc/dnf/dnf.conf
