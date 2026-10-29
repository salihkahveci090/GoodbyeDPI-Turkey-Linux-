#!/bin/sh
# Remove only the Kali/Debian systemd unit and its own nftables table.
set -eu
if [ "$(id -u)" -ne 0 ]; then
    echo "Run with sudo: sudo bash scripts/uninstall-systemd-kali.sh" >&2
    exit 1
fi
systemctl disable --now goodbyedpi-kali.service 2>/dev/null || true
/usr/sbin/nft delete table inet goodbyedpi 2>/dev/null || true
rm -f /etc/systemd/system/goodbyedpi-kali.service
rm -f /usr/local/sbin/goodbyedpi-nft-kali.sh
# Keep /usr/local/bin/goodbyedpi: another service/config may use it.
systemctl daemon-reload
printf '%s\n' 'Removed goodbyedpi-kali.service and its nftables table. Kept /usr/local/bin/goodbyedpi.'
