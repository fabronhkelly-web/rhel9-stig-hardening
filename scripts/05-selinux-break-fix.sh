#!/bin/bash
# Step 1.8 - SELinux break-and-fix. SELinux stays Enforcing the whole time.
dnf -y install httpd setroubleshoot-server policycoreutils-python-utils
mkdir -p /web && echo "<h1>rhel01 lab web server</h1>" > /web/index.html
cat > /etc/httpd/conf.d/lab.conf <<'C'
DocumentRoot "/web"
<Directory "/web">
    Require all granted
</Directory>
C
systemctl enable --now httpd

# BREAK 1: 403 Forbidden. /web is labeled root_t, httpd_t may not read it.
curl -s -o /dev/null -w "HTTP %{http_code}\n" http://localhost/
ls -Zd /web
ausearch -m avc -ts recent | tail -4         # avc: denied { getattr } ... tcontext=...root_t
sealert -a /var/log/audit/audit.log | grep -m1 "SELinux is preventing"
# FIX 1: persistent label rule (not chcon, which a relabel would undo)
semanage fcontext -a -t httpd_sys_content_t "/web(/.*)?"
restorecon -Rv /web
curl -s -w "HTTP %{http_code}\n" http://localhost/

# BREAK 2: port 8081 is labeled transproxy_port_t -> name_bind denied
sed -i 's/^Listen 80$/Listen 8081/' /etc/httpd/conf/httpd.conf
systemctl restart httpd || ausearch -m avc -c httpd -ts recent | grep name_bind
# FIX 2
semanage port -a -t http_port_t -p tcp 8081
systemctl restart httpd && curl -s -w "HTTP %{http_code}\n" http://localhost:8081/
# restore port 80
sed -i 's/^Listen 8081$/Listen 80/' /etc/httpd/conf/httpd.conf
semanage port -d -t http_port_t -p tcp 8081
systemctl restart httpd
