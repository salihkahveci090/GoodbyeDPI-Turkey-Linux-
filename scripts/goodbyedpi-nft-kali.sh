#!/bin/sh
# nftables rules used by the Kali/Debian systemd unit.
# Does not edit /etc/resolv.conf or NetworkManager DNS settings.
set -eu

NFT=/usr/sbin/nft
if [ ! -x "$NFT" ]; then
    echo "nft not found at $NFT; install nftables first." >&2
    exit 1
fi

# Replace only our own table. This keeps repeated service starts idempotent.
"$NFT" delete table inet goodbyedpi 2>/dev/null || true
"$NFT" add table inet goodbyedpi
"$NFT" add chain inet goodbyedpi output_dpi \
  '{ type filter hook output priority mangle; policy accept; }'
"$NFT" add rule inet goodbyedpi output_dpi meta mark 0x00000001 accept
"$NFT" add rule inet goodbyedpi output_dpi ip daddr \
  '{ 127.0.0.0/8, 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16, 169.254.0.0/16 }' accept
"$NFT" add rule inet goodbyedpi output_dpi ip6 daddr \
  '{ ::1, fc00::/7, fe80::/10 }' accept
"$NFT" add rule inet goodbyedpi output_dpi tcp dport \
  '{ 80, 443 }' queue num 0 bypass

"$NFT" add chain inet goodbyedpi nat_out \
  '{ type nat hook output priority -100; policy accept; }'
"$NFT" add rule inet goodbyedpi nat_out \
  ip daddr != 127.0.0.0/8 udp dport 53 dnat ip to 77.88.8.8:1253
