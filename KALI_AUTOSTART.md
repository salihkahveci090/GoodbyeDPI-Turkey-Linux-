# Kali Linux: systemd ile otomatik başlatma

Bu rehber, Kali/Debian tabanlı sistemlerde GoodbyeDPI Linux portunu systemd ile açılışta başlatmak için ayrı bir yöntem sunar. `service_install_dnsredir_turkey.sh` betiğinden farklı olarak **`/etc/resolv.conf` veya NetworkManager DNS ayarlarını değiştirmez**.

## Kurulum

Depo kök dizinindeyken:

```bash
sudo bash scripts/install-systemd-kali.sh
```

Kurulum derleme bağımlılıklarını yükler, ikili dosyayı `/usr/local/bin/goodbyedpi` konumuna kurar, systemd birimini oluşturur ve servisi hemen başlatıp açılışta etkinleştirir.

## Kontrol

```bash
systemctl --no-pager --full status goodbyedpi-kali.service
systemctl is-active goodbyedpi-kali.service
systemctl is-enabled goodbyedpi-kali.service
curl -4 --http1.1 -sS -o /dev/null --connect-timeout 5 --max-time 12 \
  -w 'HTTP=%{http_code} TLS_verify=%{ssl_verify_result} IP=%{remote_ip}\n' \
  https://discord.com/
```

Beklenen servis durumu `active (running)` ve `enabled`; Discord HTTP testi normalde `HTTP=200` döndürür. Ağ/ISS koşullarına göre sonuç değişebilir.

## Loglar ve durdurma

```bash
journalctl -u goodbyedpi-kali.service -b --no-pager
sudo systemctl stop goodbyedpi-kali.service
sudo systemctl start goodbyedpi-kali.service
```

Kaldırmak için depo kökünden:

```bash
sudo bash scripts/uninstall-systemd-kali.sh
```

Bu kaldırıcı `/usr/local/bin/goodbyedpi` ikilisini özellikle silmez.

## Önemli davranış ve kapsam

- nftables, yerel/özel hedefleri hariç tutarak **makineden çıkan tüm TCP 80 ve 443 trafiğini** NFQUEUE 0'a gönderir; yalnızca Discord'a özgü değildir. Başka web sitelerinde sorun yaşanırsa servisi durdurup kuralları yeniden değerlendirin.
- IPv4 UDP/53 DNS sorguları `77.88.8.8:1253` adresine yönlendirilir. Bu yöntem sistem çapında DNS davranışını etkiler; kurumsal/ağ içi DNS kullanan makinelerde uygun olmayabilir.
- Kurulum `chattr +i` kullanmaz ve `/etc/resolv.conf` dosyasını düzenlemez.
- Bu, topluluk tarafından sürdürülen bir Linux portu içindir; resmi Windows GoodbyeDPI ile aynı uygulama/altyapı değildir. Ağınızdaki kullanım koşullarını ve geçerli mevzuatı gözetin.

## Bilinen sınırlama

Bu varyantta otomatik servis başlatma Kali üzerinde doğrulanmıştır; her dağıtım, ISS ve ağ topolojisinde başarı garanti edilmez. Yayınlamadan önce kendi ortamınızda test edin.
