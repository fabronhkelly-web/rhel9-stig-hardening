#!/bin/bash
# Step 1.7 - least functionality (CM-7): only ssh and http
firewall-cmd --permanent --remove-service=cockpit
firewall-cmd --permanent --remove-service=dhcpv6-client
firewall-cmd --permanent --add-service=http
firewall-cmd --reload
firewall-cmd --list-services                # -> http ssh
