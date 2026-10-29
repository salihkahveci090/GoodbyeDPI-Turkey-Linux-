#!/bin/sh
# Build and install the Kali/Debian systemd variant.
set -eu

if [ "$(id -u)" -ne 0 ]; then
    echo "Run with sudo: sudo bash scripts/install-systemd-kali.sh" >&2
    exit 1
fi

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)

if [ ! -f "$REPO_DIR/Makefile" ]; then
    echo "Could not find the project Makefile in $REPO_DIR" >&2
    exit 1
fi

. /etc/os-release
case "${ID:-}" in
  kali|debian|ubuntu|linuxmint) ;;
  *)
    echo "This installer is intended for Kali/Debian-family systems; detected ID=${ID:-unknown}." >&2
    exit 1
    ;;
esac

# Avoid running two services against the same NFQUEUE number/table.
systemctl disable --now goodbyedpi.service 2>/dev/null || true
if command -v pgrep >/dev/null 2>&1 && pgrep -x goodbyedpi >/dev/null 2>&1; then
    echo "A manually started goodbyedpi process is still running. Stop it with Ctrl+C or pkill -TERM -x goodbyedpi, then rerun this installer." >&2
    exit 1
fi

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y build-essential make libnetfilter-queue-dev libnfnetlink-dev libmnl-dev nftables

make -C "$REPO_DIR" clean
make -C "$REPO_DIR"
install -D -m 755 "$REPO_DIR/goodbyedpi" /usr/local/bin/goodbyedpi
install -D -m 755 "$SCRIPT_DIR/goodbyedpi-nft-kali.sh" /usr/local/sbin/goodbyedpi-nft-kali.sh
install -D -m 644 "$REPO_DIR/systemd/goodbyedpi-kali.service" /etc/systemd/system/goodbyedpi-kali.service

systemctl daemon-reload
systemctl enable --now goodbyedpi-kali.service
systemctl --no-pager --full status goodbyedpi-kali.service
