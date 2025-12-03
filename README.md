# [Ubuntu Otomatik Kurulum Scriptleri](https://www.egemenkeydal.com/projects/ubuntu-auto-setup)

Geliştirici: Egemen KEYDAL

[English](README_EN.md) | Türkçe

Ubuntu sunucularınız için tam otomatik kurulum scriptleri. Her script, ilgili yazılımı hata kontrolü ve otomatik düzeltme özellikleriyle kurar.

## 📋 İçindekiler

- [Özellikler](#özellikler)
- [Kullanılabilir Scriptler](#kullanılabilir-scriptler)
- [Kurulum](#kurulum)
- [Kullanım](#kullanım)
- [Detaylı Bilgiler](#detaylı-bilgiler)
- [Güvenlik Notları](#güvenlik-notları)
- [Sorun Giderme](#sorun-giderme)
- [Katkıda Bulunma](#katkıda-bulunma)
- [Lisans](#lisans)

## ✨ Özellikler

Her script şu özellikleri içerir:

- ✅ **Tam Otomatik Kurulum**: Tek komutla her şeyi kurar
- 🔧 **Akıllı Hata Düzeltme**: Hataları otomatik algılar ve düzeltir
- 🛡️ **Güvenlik Odaklı**: Güvenli varsayılan ayarlarla gelir
- 🔍 **Çakışma Kontrolü**: Port ve servis çakışmalarını algılar
- 📝 **Detaylı Loglama**: Her adımı açıklar ve loglar
- 🔄 **Yeniden Kurulum Desteği**: Mevcut kurulumları güvenle yönetir
- 🧪 **Test Dosyaları**: Kurulumu test etmek için örnek dosyalar oluşturur
- 📚 **Kapsamlı Dokümantasyon**: Her script sonunda kullanım talimatları

## 🚀 Kullanılabilir Scriptler

| Script | Açıklama | Varsayılan Port |
|--------|----------|-----------------|
| **setup-nginx.sh** | Nginx web sunucusu | 80, 443 |
| **setup-apache.sh** | Apache web sunucusu | 80, 443 |
| **setup-mysql.sh** | MySQL veritabanı sunucusu | 3306 |
| **setup-mariadb.sh** | MariaDB veritabanı sunucusu | 3306 |
| **setup-redis.sh** | Redis cache sunucusu | 6379 |
| **setup-php.sh** | PHP (7.4, 8.1, 8.2, 8.3) | - |
| **setup-nodejs.sh** | Node.js runtime (18.x, 20.x, 21.x) | - |
| **setup-python.sh** | Python (2, 3.10, 3.11) | - |
| **setup-ssl.sh** | Let's Encrypt SSL/TLS sertifikaları | 443 |

## 📦 Kurulum

### Önkoşullar

- Ubuntu 20.04, 22.04 veya 24.04
- Root erişimi (sudo)
- İnternet bağlantısı

### Scriptleri Çalıştırılabilir Yapma

```bash
chmod +x setup-*.sh
```

## 🎯 Kullanım

Her script'i root yetkileriyle çalıştırın:

```bash
sudo bash setup-nginx.sh
```

### Örnek Kullanım Senaryoları

#### 1. Web Sunucusu Kurulumu (Nginx + PHP + MySQL)

```bash
# Adım 1: Nginx kurun
sudo bash setup-nginx.sh

# Adım 2: PHP kurun
sudo bash setup-php.sh
# Seçenek: 1 (PHP 8.2 - Önerilen)

# Adım 3: MySQL kurun
sudo bash setup-mysql.sh

# Adım 4: SSL sertifikası ekleyin
sudo bash setup-ssl.sh
```

#### 2. Node.js Uygulama Sunucusu

```bash
# Node.js kurun
sudo bash setup-nodejs.sh
# Seçenek: 1 (LTS - Önerilen)

# Nginx reverse proxy olarak kurun
sudo bash setup-nginx.sh

# SSL ekleyin
sudo bash setup-ssl.sh
```

#### 3. Tam Yığın Geliştirme Ortamı

```bash
# Tüm araçları kurun
sudo bash setup-nginx.sh
sudo bash setup-apache.sh      # Farklı port kullanacak
sudo bash setup-mysql.sh
sudo bash setup-redis.sh
sudo bash setup-php.sh
sudo bash setup-nodejs.sh
sudo bash setup-python.sh
```

## 📖 Detaylı Bilgiler

### Nginx (setup-nginx.sh)

**Neler Kurulur:**
- Nginx web sunucusu
- Varsayılan site yapılandırması
- Test HTML sayfası
- Firewall kuralları (UFW kullanılıyorsa)

**Önemli Dosyalar:**
- Yapılandırma: `/etc/nginx/nginx.conf`
- Site yapılandırmaları: `/etc/nginx/sites-available/`
- Web root: `/var/www/html`
- Loglar: `/var/log/nginx/`

**Kullanım:**
```bash
# Nginx'i yeniden başlat
sudo systemctl restart nginx

# Yapılandırmayı test et
sudo nginx -t

# Durumu kontrol et
sudo systemctl status nginx
```

### Apache (setup-apache.sh)

**Neler Kurulur:**
- Apache2 web sunucusu
- Yaygın modüller (rewrite, ssl, headers, expires)
- Güvenlik modülleri (mod_security2, mod_evasive)
- Test sayfaları

**Önemli Dosyalar:**
- Yapılandırma: `/etc/apache2/apache2.conf`
- Site yapılandırmaları: `/etc/apache2/sites-available/`
- Web root: `/var/www/html`
- Loglar: `/var/log/apache2/`

**Kullanım:**
```bash
# Site'ı etkinleştir
sudo a2ensite mysite.conf

# Modül etkinleştir
sudo a2enmod rewrite

# Yapılandırmayı test et
sudo apache2ctl configtest

# Yeniden başlat
sudo systemctl restart apache2
```

### MySQL (setup-mysql.sh)

**Neler Kurulur:**
- MySQL Server ve Client
- Güvenli root şifresi (otomatik oluşturulur)
- Optimize edilmiş yapılandırma
- Root için client yapılandırması

**Önemli Bilgiler:**
- Root şifresi: `/root/.mysql_credentials` dosyasında
- Client yapılandırması: `/root/.my.cnf`
- Yapılandırma: `/etc/mysql/mysql.conf.d/mysqld.cnf`
- Data dizini: `/var/lib/mysql`

**Güvenlik:**
- Anonymous kullanıcılar kaldırıldı
- Uzaktan root erişimi devre dışı
- Test veritabanı kaldırıldı
- Localhost'a bağlı (127.0.0.1)

**Kullanım:**
```bash
# MySQL'e bağlan
mysql -u root -p

# Veritabanı oluştur
mysql -e "CREATE DATABASE myapp;"

# Kullanıcı oluştur
mysql -e "CREATE USER 'myuser'@'localhost' IDENTIFIED BY 'password';"
mysql -e "GRANT ALL PRIVILEGES ON myapp.* TO 'myuser'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"
```

### MariaDB (setup-mariadb.sh)

MySQL'e benzer ancak MariaDB spesifik özelliklerle. Aynı kullanım ve yapılandırma.

**Not:** MySQL ve MariaDB aynı anda kurulamaz. Script çakışmaları otomatik algılar.

### Redis (setup-redis.sh)

**Neler Kurulur:**
- Redis Server
- Systemd entegrasyonu
- Optimize edilmiş memory policy
- Güvenlik yapılandırması

**Önemli Dosyalar:**
- Yapılandırma: `/etc/redis/redis.conf`
- Log: `/var/log/redis/redis-server.log`
- Data: `/var/lib/redis`

**Kullanım:**
```bash
# Redis CLI'ya bağlan
redis-cli

# Temel komutlar
redis-cli ping
redis-cli set mykey "Hello"
redis-cli get mykey
redis-cli info
```

### PHP (setup-php.sh)

**Neler Kurulur:**
- Seçilen PHP versiyonu(ları)
- Yaygın eklentiler (mysql, curl, gd, mbstring, xml, zip, vb.)
- PHP-FPM (Nginx için) veya mod_php (Apache için)
- Composer (isteğe bağlı)
- Test PHP dosyaları

**Desteklenen Versiyonlar:**
- PHP 8.3 (En son)
- PHP 8.2 (Kararlı)
- PHP 8.1
- PHP 7.4 (Eski)

**Kullanım:**
```bash
# PHP versiyonunu kontrol et
php -v

# Yüklü modülleri listele
php -m

# PHP versiyonu değiştir
sudo update-alternatives --config php

# PHP-FPM'i yeniden başlat
sudo systemctl restart php8.2-fpm
```

### Node.js (setup-nodejs.sh)

**Neler Kurulur:**
- Node.js runtime
- npm paket yöneticisi
- Yarn (isteğe bağlı)
- PM2 process manager (isteğe bağlı)
- nodemon (isteğe bağlı)
- Build araçları

**Desteklenen Versiyonlar:**
- Node.js 18.x LTS
- Node.js 20.x LTS
- Node.js 21.x (Güncel)

**Kullanım:**
```bash
# Proje oluştur
mkdir myapp && cd myapp
npm init -y

# Paket kur
npm install express

# PM2 ile çalıştır
pm2 start app.js
pm2 save
pm2 startup
```

### Python (setup-python.sh)

**Neler Kurulur:**
- Python 3.x (sistem varsayılanı)
- pip paket yöneticisi
- virtualenv
- Geliştirme araçları (isteğe bağlı)
- Örnek virtual environment

**Desteklenen Versiyonlar:**
- Python 3.11
- Python 3.10
- Python 3 (sistem varsayılanı)
- Python 2 (eski - isteğe bağlı)

**Kullanım:**
```bash
# Virtual environment oluştur
python3 -m venv myenv
source myenv/bin/activate

# Paket kur
pip install flask

# Devre dışı bırak
deactivate
```

### SSL/Let's Encrypt (setup-ssl.sh)

**Neler Kurulur:**
- Certbot
- Web sunucusu eklentisi (Nginx veya Apache)
- Otomatik yenileme sistemi
- Firewall kuralları

**Kullanım:**

Nginx için:
```bash
# SSL sertifikası al
sudo certbot --nginx -d yourdomain.com -d www.yourdomain.com
```

Apache için:
```bash
# SSL sertifikası al
sudo certbot --apache -d yourdomain.com -d www.yourdomain.com
```

Standalone (web sunucusu olmadan):
```bash
# Web sunucusunu durdur
sudo systemctl stop nginx

# Sertifika al
sudo certbot certonly --standalone -d yourdomain.com

# Web sunucusunu başlat
sudo systemctl start nginx
```

**Yönetim:**
```bash
# Sertifikaları listele
sudo certbot certificates

# Yenilemeyi test et
sudo certbot renew --dry-run

# Manuel yenile
sudo certbot renew
```

## 🔒 Güvenlik Notları

### Genel Güvenlik

1. **Güçlü Şifreler**: Otomatik oluşturulan şifreleri `/root/` dizininde bulabilirsiniz
2. **Firewall**: UFW kullanılıyorsa scriptler otomatik kurallar ekler
3. **Güncellemeler**: Düzenli olarak `apt-get update && apt-get upgrade` çalıştırın
4. **SSH**: Root SSH erişimini devre dışı bırakmayı düşünün
5. **Fail2ban**: Brute-force saldırıları önlemek için kurmayı düşünün

### Veritabanı Güvenliği

- Root şifreleri otomatik oluşturulur ve güvenli dosyalarda saklanır
- Veritabanları varsayılan olarak localhost'a bağlıdır
- Uzaktan erişim devre dışıdır
- Şifre dosyalarını güvenli bir yere kopyalayın ve silin:

```bash
# Şifreyi kopyalayın
cat /root/.mysql_credentials

# Güvenli bir yere kaydedin, sonra silin
rm /root/.mysql_credentials
```

### Web Sunucusu Güvenliği

- Gereksiz modüller devre dışı bırakılmıştır
- Sunucu imzaları gizlenmiştir
- Güvenli varsayılan yapılandırmalar
- Düzenli olarak güncelleme yapın

### SSL/TLS Güvenliği

- Let's Encrypt sertifikaları otomatik yenilenir
- Modern TLS protokolleri kullanılır
- Sertifikaları 443 numaralı port için yapılandırın

## 🔧 Sorun Giderme

### Genel Sorunlar

**Problem**: "Permission denied" hatası
```bash
# Çözüm: sudo ile çalıştırın
sudo bash setup-nginx.sh
```

**Problem**: "Port already in use" hatası
```bash
# Çözüm: Hangi servisin portu kullandığını kontrol edin
sudo lsof -i :80
sudo ss -tlnp | grep :80

# Servisi durdurun
sudo systemctl stop apache2
```

**Problem**: Paket kurulum hataları
```bash
# Çözüm: Paket yöneticisini düzeltin
sudo dpkg --configure -a
sudo apt-get install -f
sudo apt-get update
```

### Servis Başlamıyor

```bash
# Durumu kontrol edin
sudo systemctl status nginx

# Logları kontrol edin
sudo journalctl -xe

# Yapılandırmayı test edin
sudo nginx -t
sudo apache2ctl configtest
```

### Veritabanı Bağlantı Sorunları

```bash
# Servisin çalıştığını kontrol edin
sudo systemctl status mysql

# Logları kontrol edin
sudo tail -f /var/log/mysql/error.log

# Socket dosyasını kontrol edin
ls -la /var/run/mysqld/mysqld.sock
```

### PHP Çalışmıyor

```bash
# PHP versiyonunu kontrol edin
php -v

# PHP-FPM durumunu kontrol edin
sudo systemctl status php8.2-fpm

# PHP modüllerini kontrol edin (Apache)
sudo apache2ctl -M | grep php

# Nginx PHP yapılandırmasını kontrol edin
sudo nginx -t
```

## 📝 Log Dosyaları

Sorun yaşarsanız bu log dosyalarını kontrol edin:

- **Nginx**: `/var/log/nginx/error.log`
- **Apache**: `/var/log/apache2/error.log`
- **MySQL**: `/var/log/mysql/error.log`
- **MariaDB**: `/var/log/mysql/error.log`
- **Redis**: `/var/log/redis/redis-server.log`
- **PHP-FPM**: `/var/log/php8.2-fpm.log`
- **System**: `sudo journalctl -xe`

## 🤝 Katkıda Bulunma

Katkılar memnuniyetle karşılanır! Lütfen:

1. Repository'yi fork edin
2. Feature branch oluşturun (`git checkout -b feature/amazing-feature`)
3. Değişikliklerinizi commit edin (`git commit -m 'Add amazing feature'`)
4. Branch'inizi push edin (`git push origin feature/amazing-feature`)
5. Pull Request açın

### Katkı Kuralları

- Her script tek başına çalışabilmeli
- Kapsamlı hata kontrolü ekleyin
- Kodunuzu yorumlayın
- README'yi güncelleyin
- Ubuntu 20.04, 22.04 ve 24.04'te test edin

## 📄 Lisans

Bu proje MIT Lisansı altında lisanslanmıştır - detaylar için [LICENSE](LICENSE) dosyasına bakın.

## 🙏 Teşekkürler

- Ubuntu topluluğu
- Tüm açık kaynak proje katkıda bulunanları
- Bu scriptleri kullanan ve geri bildirimde bulunan herkese

## 🔗 Faydalı Bağlantılar

- [Ubuntu Dokümantasyonu](https://help.ubuntu.com/)
- [Nginx Dokümantasyonu](https://nginx.org/en/docs/)
- [Apache Dokümantasyonu](https://httpd.apache.org/docs/)
- [MySQL Dokümantasyonu](https://dev.mysql.com/doc/)
- [PHP Dokümantasyonu](https://www.php.net/docs.php)
- [Node.js Dokümantasyonu](https://nodejs.org/docs/)
- [Python Dokümantasyonu](https://docs.python.org/)
- [Let's Encrypt](https://letsencrypt.org/docs/)

---

⭐ Bu projeyi faydalı bulduysanız yıldız vermeyi unutmayın!
