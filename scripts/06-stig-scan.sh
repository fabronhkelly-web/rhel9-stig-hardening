#!/bin/bash
# Steps 1.9 / 1.10 - scan against the DISA STIG for RHEL 9 and summarize. Usage: ./06-stig-scan.sh before
set -u
n=${1:-scan}; mkdir -p /root/scans
dnf -y -q install openscap-scanner scap-security-guide
oscap xccdf eval --profile xccdf_org.ssgproject.content_profile_stig \
  --results /root/scans/$n-results.xml --report /root/scans/$n-report.html \
  /usr/share/xml/scap/ssg/content/ssg-rhel9-ds.xml > /root/scans/$n.txt 2>&1
python3 - "$n" <<'P'
import sys,xml.etree.ElementTree as ET,collections
X='{http://checklists.nist.gov/xccdf/1.2}';n=sys.argv[1]
t=ET.parse(f'/root/scans/{n}-results.xml')
rr=list(t.iter(X+'rule-result'));res=collections.Counter(r.find(X+'result').text for r in rr)
sev=collections.Counter(r.get('severity') for r in rr if r.find(X+'result').text=='fail')
sc=[s.text for s in t.iter(X+'score')][0]
print(f"{n}: score={float(sc):.1f}%  pass={res['pass']} fail={res['fail']}  CAT I={sev['high']} CAT II={sev['medium']} CAT III={sev['low']}")
print("CAT I failing:",[r.get('idref').split('rule_')[1] for r in rr if r.find(X+'result').text=='fail' and r.get('severity')=='high'])
P
