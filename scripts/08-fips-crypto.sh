#!/bin/bash
# CAT I: FIPS mode + FIPS:STIG crypto policy. Requires reboot.
# Note: in FIPS mode sshd skips Ed25519 keys -> use ECDSA/RSA keys.
set -euo pipefail
fips-mode-setup --enable
./stig-fix-rule.sh fips_custom_stig_sub_policy     # creates the STIG.pmod policy module...
./stig-fix-rule.sh configure_crypto_policy         # ...that this rule depends on
update-crypto-policies --show                      # -> FIPS:STIG
echo "reboot, then: fips-mode-setup --check ; cat /proc/sys/crypto/fips_enabled"
