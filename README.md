# GoodbyeDPI Turkey - Linux

> **[cagritaskn/GoodbyeDPI-Turkey](https://github.com/cagritaskn/GoodbyeDPI-Turkey)** projesinden fork edilmiş Linux portu (CachyOS, Arch Linux, ve diğer dağıtımlar).
> Linux port forked from GoodbyeDPI-Turkey for Arch/CachyOS and other Linux distributions.

Discord, YouTube ve diğer ISP tarafından engellenen sitelere **VPN'siz** erişim sağlar.

---

## Nasıl Çalışır / How It Works

| Windows (Orijinal) | Linux (Bu Proje) |
|---|---|
| WinDivert (kernel driver) | **NFQUEUE** (libnetfilter_queue) |
| WinDivert filter string | **nftables** kuralları |
| Windows Service | **systemd** servisi |
| DNS redirect (userspace) | **nftables DNAT** (port 53 → Yandex:1253) |
| Fake packet injection | **raw socket** (SOCK_RAW + IP_HDRINCL) |

**Paket akışı:**
1. DNS sorguları → nftables DNAT → Yandex DNS `77.88.8.8:1253` (ISP'nin DNS engelini aşar)
2. HTTPS trafiği → NFQUEUE → `goodbyedpi` daemon
3. Daemon → İlk TLS paketini böler + sahte paket gönderir → DPI karışır → bağlantı geçer

---

## Gereksinimler / Requirements

- **Linux** (CachyOS, Arch Linux, Manjaro, veya systemd kullanan herhangi bir dağıtım)
- `libnetfilter_queue` paketi
- `nftables`
- `gcc`, `make`
- Root/sudo yetkisi

**Arch/CachyOS için bağımlılık kurulumu:**
```bash
sudo pacman -S libnetfilter_queue nftables gcc make
```

---

## Kurulum / Installation

### Yöntem 1: Release'den Binary İndir (Derleme gerekmez)

1. [Releases](https://github.com/salihkahveci090/GoodbyeDPI-Turkey-Linux-/releases) sayfasından `goodbyedpi-linux-x86_64` dosyasını indirin
2. Repoyu clone'layın ve binary'yi yerleştirin:

```bash
git clone https://github.com/salihkahveci090/GoodbyeDPI-Turkey-Linux-
cd GoodbyeDPI-Turkey-Linux-
mkdir -p bin
mv ~/Downloads/goodbyedpi-linux-x86_64 bin/goodbyedpi
chmod +x bin/goodbyedpi
sudo bash service_install_dnsredir_turkey.sh
```

### Yöntem 2: Kaynak Koddan Derle

```bash
sudo pacman -S libnetfilter_queue gcc make
git clone https://github.com/salihkahveci090/GoodbyeDPI-Turkey-Linux-
cd GoodbyeDPI-Turkey-Linux-
make
sudo bash service_install_dnsredir_turkey.sh
```

### Hangi Script'i Kullanmalıyım?

| Script | Açıklama | ISP |
|--------|----------|-----|
| `service_install_dnsredir_turkey.sh` | **Ana** - Fragment(5) + TTL(5) + DNS Yandex | Tüm ISP'ler ✓ |
| `turkey_dnsredir.sh` | Servissiz, tek seferlik (terminal kapatılınca durur) | Tüm ISP'ler |
| `service_install_dnsredir_turkey_alternative_superonline.sh` | Sadece TTL=3, DNS manuel | SuperOnline |
| `service_install_dnsredir_turkey_alternative2_superonline.sh` | Sadece Fragment=5, DNS manuel | SuperOnline |
| `service_install_dnsredir_turkey_alternative3_superonline.sh` | TTL=3 + DNS Yandex | SuperOnline |
| `service_install_dnsredir_turkey_alternative4_superonline.sh` | Fragment=5 + DNS Yandex | SuperOnline |
| `service_install_dnsredir_turkey_alternative5_superonline.sh` | Fragment=9 + TTL(5) + DNS Yandex | SuperOnline |
| `service_install_dnsredir_turkey_alternative6_superonline.sh` | Sadece Fragment=9, DNS manuel | SuperOnline |
| `service_remove.sh` | **Kaldır** - Tüm kuralları ve servisi sil | — |

> **DNS manuel** yazılanlar için: Ağ ayarlarından DNS'i `77.88.8.8` veya `1.1.1.1` olarak ayarlayın.

---

## Servis Komutları

```bash
# Durum kontrolü
sudo systemctl status goodbyedpi

# Yeniden başlat
sudo systemctl restart goodbyedpi

# Durdur (geçici)
sudo systemctl stop goodbyedpi

# Logları izle
journalctl -u goodbyedpi -f

# nftables kurallarını görüntüle
sudo nft list table inet goodbyedpi

# Kaldır
sudo bash service_remove.sh
```

---

## Bağlantı Testi

```bash
# Discord DNS çözümleme (162.159.x.x olmalı, 195.175.x.x İSP yönlendirmesi)
dig discord.com +short

# Discord HTTPS testi (HTTP 200 beklenir)
curl -o /dev/null -w "%{http_code}\n" https://discord.com

# Aktif kurallar
sudo nft list table inet goodbyedpi
```

---

## Teknik Detaylar

### Kaynak Dosyalar

```
src/
├── main.c/h        - Ana program, argüman parsing
├── packet.c/h      - Ham IP/TCP/UDP paket parse + checksum
├── conntrack.c/h   - Bağlantı takibi (uthash, sadece 1. paket işlenir)
├── fakepackets.c/h - Sahte TLS ClientHello (orijinal byte dizileri)
├── fragment.c/h    - TCP payload fragmantasyonu
├── nfqueue.c/h     - NFQUEUE event loop (WinDivert karşılığı)
└── utils/uthash.h  - Header-only hash table
```

### Binary Parametreleri

```
--fragment-size N    TCP parçalama boyutu (varsayılan: 5)
--no-fragment        Parçalamayı devre dışı bırak (sadece sahte paket)
--set-ttl N          Sahte paket TTL değeri (varsayılan: 5)
--no-fake            Sahte paket göndermeyi devre dışı bırak
--dns-addr ADDR      DNS DNAT hedef adresi
--dns-port PORT      DNS DNAT hedef portu (varsayılan: 1253)
--dnsv6-addr ADDR    IPv6 DNS adresi
--dnsv6-port PORT    IPv6 DNS portu
--queue-num N        NFQUEUE numarası (varsayılan: 0)
```

### Manuel Derleme

```bash
cd goodbyedpi-linux
make              # derle
make install      # bin/ klasörüne kopyala
make debug        # debug modda derle
make clean        # temizle
```

---

## Windows'tan Fark

| Özellik | Windows | Linux |
|---|---|---|
| DNS redirect | userspace (dnsredir.c) | nftables DNAT |
| Paket yakalama | WinDivert | NFQUEUE |
| Servis | Windows Service Manager | systemd |
| TTL tracking | ttltrack.c | Basitleştirildi |
| auto-ttl | Var | Yok (gelecekte eklenecek) |
| IPv6 fake packets | Var | Kısmi |

---

## Sorun Giderme

**Servis başlamıyor:**
```bash
journalctl -u goodbyedpi -n 30
cat /tmp/goodbyedpi-nft.log
```

**Discord hâlâ açılmıyor:**
1. DNS kontrolü: `dig discord.com +short` → `162.159.x.x` olmalı
2. SuperOnline kullanıyorsanız alternatif scriptleri deneyin
3. QUIC/HTTP3 kapatın: Tarayıcıda `chrome://flags/#enable-quic` → Disabled

**nftables kuralları yüklenmedi:**
```bash
sudo nft -f /home/$USER/goodbyedpi-linux/nftables/goodbyedpi.nft
sudo systemctl restart goodbyedpi
```

---

## Kredi / Credits

- [ValdikSS/GoodbyeDPI](https://github.com/ValdikSS/GoodbyeDPI) - Orijinal Windows versiyonu
- [cagritaskn/GoodbyeDPI-Turkey](https://github.com/cagritaskn/GoodbyeDPI-Turkey) - **Bu projenin fork aldığı kaynak** (Windows versiyonu, Türkiye özelleştirmeleri)
- Sahte TLS ClientHello byte dizileri cagritaskn/GoodbyeDPI-Turkey kaynak kodundan alınmıştır.

---

## Lisans / License

MIT License — Özgürce kullanabilir, değiştirebilir ve dağıtabilirsiniz.

## Kali Linux: systemd ile otomatik başlatma

Kali/Debian tabanlı sistemlerde systemd ile açılışta otomatik başlatma için [`KALI_AUTOSTART.md`](KALI_AUTOSTART.md) rehberini izleyin. Kurulum betiği `/etc/resolv.conf` dosyasını değiştirmez veya `chattr +i` kullanmaz. Dikkat: kurallar yalnız Discord'u değil, makineden çıkan TCP 80/443 trafiğini ve IPv4 UDP/53 DNS sorgularını etkiler.
