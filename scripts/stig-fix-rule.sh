#!/bin/bash
# Apply the fix for ONE STIG rule from Red Hat's SCAP content.
# Why: `oscap xccdf generate fix --rule X` (oscap 1.3.14) ignored --rule and produced all 481 fixes.
# Usage: ./stig-fix-rule.sh banner_etc_issue
set -euo pipefail
ALL=/root/stig-all-fixes.sh
[ -s $ALL ] || oscap xccdf generate fix --fix-type bash --profile xccdf_org.ssgproject.content_profile_stig \
  /usr/share/xml/scap/ssg/content/ssg-rhel9-ds.xml > $ALL
r="xccdf_org.ssgproject.content_rule_$1"
awk -v r="$r" '$0 ~ "# BEGIN fix .* for \x27" r "\x27"{p=1} p{print} $0 ~ "# END fix for \x27" r "\x27"{p=0}' $ALL > /root/fix-$1.sh
[ "$(grep -c 'BEGIN fix' /root/fix-$1.sh)" -eq 1 ] || { echo "no single fix block for $1"; exit 1; }
less /root/fix-$1.sh 2>/dev/null || cat /root/fix-$1.sh      # read it before running it
read -rp "Apply $1? [y/N] " a; [ "$a" = y ] && bash /root/fix-$1.sh
