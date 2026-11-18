# RHEL 9 Build and DISA STIG Hardening (home lab)

Hands-on build of a Red Hat Enterprise Linux 9.9 server to DoD standards: STIG-compliant
partitioning, least-privilege access, SELinux troubleshooting, OpenSCAP scanning against the
DISA STIG, manual remediation, FIPS mode, and POA&M-style documentation of what remains.

Companion repo (automation): [rhel9-ansible-project](https://github.com/fabronhkelly-web/rhel9-ansible-project)
applies Red Hat's STIG Ansible content to a second server (52.3% to 95.2%).

## Results (OpenSCAP, DISA STIG profile for RHEL 9)
| Stage | Score | Failed rules | CAT I failed |
|---|---|---|---|
| Fresh install | 47.4% | 264 | 10 |
| Manual fixes: banner, SSH, pwquality, mount options, audit rules, PAM, Ctrl-Alt-Del, GPG | 51.3% | 207 | 5 |
| + FIPS mode and `FIPS:STIG` crypto policy | 51.7% | 200 | 2 |
| + GRUB2 password and non-default superuser | **52.1%** | **199** | **0** |

All 10 CAT I findings closed by hand. Reports: [`reports/rhel01-stig-before.html`](reports/rhel01-stig-before.html),
[`reports/rhel01-stig-after.html`](reports/rhel01-stig-after.html) (download and open in a browser).
Remaining findings and justifications: [`docs/POAM.csv`](docs/POAM.csv).

## Lab
| Item | Value |
|---|---|
| Hypervisor | VMware Workstation Pro 26H1, NAT network 192.168.31.0/24 |
| VM | `rhel01.lab.example.com`, 2 vCPU, 4 GB, UEFI, NVMe 40 GB + 10 GB; sound and USB removed |
| OS | RHEL 9.9 Server (no GUI), Red Hat Developer subscription; ISO SHA-256 verified before use |

STIG disk layout (LVM): separate `/home`, `/tmp`, `/var`, `/var/log`, `/var/log/audit`, `/var/tmp`, with free space held in the VG.

## What I did ([`scripts/`](scripts))
| Step | Script | Highlights |
|---|---|---|
| Verify build | `01-verify-build.sh` | Partition layout, SELinux Enforcing, `multi-user.target` |
| Users and access | `02-users-sudo-lockout.sh` | `webop` limited to restarting httpd; denied `sudo cat /etc/shadow` **logged** in `/var/log/secure`; 60/1/7 password aging; faillock 3 tries, admin-only unlock (tested) |
| Storage | `03-lvm-extend.sh` | New VG on second disk mounted by UUID with `nodev,nosuid`; `/var/log` grown 3 to 4 GB **online** with `lvextend -r` |
| Firewall | `04-firewall.sh` | Only `ssh` and `http` (CM-7) |
| SELinux | `05-selinux-break-fix.sh` | 403 from `root_t` content fixed with `semanage fcontext` + `restorecon`; port 8081 `name_bind` denial (`transproxy_port_t`) fixed with `semanage port`; never disabled SELinux |
| Scan | `06-stig-scan.sh` | OpenSCAP DISA STIG profile, summary by CAT level |
| Remediate | `07-stig-manual-remediation.sh` | DoD banner, SSH, pwquality, mount options, 52 audit rules, PAM `without-nullok`, Ctrl-Alt-Del, `localpkg_gpgcheck` |
| FIPS | `08-fips-crypto.sh` | `fips-mode-setup --enable`, `FIPS:STIG` policy |
| Boot loader | `09-grub-password.sh` | GRUB password (PBKDF2) + superuser `bootadmin`; no SCAP fix exists for the rename, so done by hand and reboot-tested |
| Clone | `10-clone-new-identity.sh` | Golden image to rhel02: new machine-id, SSH host keys, hostname/IP, re-registration |

## Troubleshooting I ran into
- **Registration HTTP 401:** the Red Hat account used Google SSO (no Red Hat password). Fixed with an **activation key + org ID**, which is also the scalable way to register servers.
- **Generated remediation applied too much:** `oscap xccdf generate fix --rule X` (oscap 1.3.14) ignored `--rule` and produced all 481 fixes. I caught it from the script size, **reverted to a snapshot**, and wrote [`stig-fix-rule.sh`](scripts/stig-fix-rule.sh) to extract exactly one rule's fix and show it before running.
- **Rule dependencies:** `configure_crypto_policy` failed until `fips_custom_stig_sub_policy` created the `STIG.pmod` module.
- **FIPS side effects:** sshd skips Ed25519 host keys in FIPS mode, so automation keys are ECDSA.
- **Soft lockup warnings after a live snapshot:** caused by the hypervisor pausing the guest, not a kernel fault. Now I snapshot powered-off.
- **Cloning safely:** `subscription-manager clean`, not `unregister` (the clone shares the source's identity), plus a new machine-id and SSH host keys.

## Remaining findings
Documented with STIG IDs, justification and planned fix in [`docs/POAM.csv`](docs/POAM.csv): smart card/CAC (no PKI in lab),
remote log forwarding (no SIEM), AIDE, fapolicyd, account inactivity, and others. Most are closed by the Ansible STIG
playbook in the companion repo.

## Disclaimer
Personal home lab using `lab.example.com` (reserved for documentation). No real systems, hostnames or data.
The DoD banner text comes from Red Hat's public `scap-security-guide` content.
