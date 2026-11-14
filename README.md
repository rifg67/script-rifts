---

### ⚡ **GitHub Stats**
<p align="center">
  <img src="https://github-readme-stats.vercel.app/api?username=PeyxDev&show_icons=true&theme=tokyonight&hide_border=true" alt="GitHub Stats"/>
</p>

<p align="center">
  <img src="https://github-readme-streak-stats.herokuapp.com?user=PeyxDev&theme=tokyonight&hide_border=true" alt="GitHub Streak"/>
</p>

<p align="center">
  <img src="https://github-readme-stats.vercel.app/api/top-langs/?username=PeyxDev&layout=compact&theme=tokyonight&hide_border=true" alt="Top Languages"/>
</p>

---

### 🔥 **Languages & Tools**
<p align="center">
  <img src="https://skillicons.dev/icons?i=python,js,html,css,nodejs,react,linux,vscode,github,git&theme=dark" />
</p>

---

<h3 align="center">✨ Thanks for Visiting! ✨</h3>
<p align="center">
  <img src="https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExZTFkOGJkNjMyNzYwNDQxNDg0ZTNiOGI5ZWM3ZmE4YWMxMGFlNGMwNyZlcD12MV9naWZzX3NlYXJjaCZjdD1n/gf7bMpF5rTPIs/giphy.gif" width="250px" alt="Thank You Anime"/>
</p>

---

### INSTALL SCRIPT (OTOMATIS, IPv4, JALAN DI LATAR BELAKANG)

Layar setup bawaan akan menanyakan **nama** dan **domain** seperti biasa. Sesudah diisi,
instalasi jalan sendiri di latar belakang tanpa enter lagi, dan **terminal boleh ditutup**.
Download memakai `wget -4` (IPv4) dan IPv6 dimatikan otomatis.

#### UBUNTU
```bash
export DEBIAN_FRONTEND=noninteractive
apt-get update -y && apt-get install -y screen wget curl
cd /root
U=https://raw.githubusercontent.com/rifg67/script-rifts/main
wget -4 -nv -O install.sh $U/install.sh
wget -4 -nv -O setup.sh $U/setup.sh
chmod +x install.sh setup.sh && ./install.sh
```
#### DEBIAN
```bash
export DEBIAN_FRONTEND=noninteractive
apt-get update -y && apt-get install -y screen bsdextrautils util-linux coreutils wget curl
cd /root
U=https://raw.githubusercontent.com/rifg67/script-rifts/main
wget -4 -nv -O install.sh $U/install.sh
wget -4 -nv -O setup.sh $U/setup.sh
chmod +x install.sh setup.sh && ./install.sh
```
Tambahan (boleh dilewati):
- `./install.sh -r` : VPS reboot otomatis setelah instalasi selesai (kalau tidak ditulis, Anda ditanya sekali sebelum mulai).
- `./install.sh -n NAMA -d DOMAIN` atau `-n NAMA -s SUBDOMAIN` : isi nama/domain lewat perintah, tanpa ditanya.

#### CEK PROGRES
```bash
./install.sh status     # status + 15 baris log terakhir
./install.sh log        # ikuti log langsung (Ctrl+C untuk keluar)
./install.sh attach     # buka layar instalasi (keluar: Ctrl+A lalu D)
```
Log lengkap ada di `/root/install-rifts.log`. Kalau sudah selesai, ketik `menu`.

---

### MATIKAN IPv6 (MANUAL)
`install.sh` dan `setup.sh` sudah melakukan ini otomatis. Kalau mau manual, atau untuk VPS yang sudah jalan:
```bash
printf '%s\n' 'net.ipv6.conf.all.disable_ipv6 = 1' 'net.ipv6.conf.default.disable_ipv6 = 1' 'net.ipv6.conf.lo.disable_ipv6 = 1' > /etc/sysctl.d/99-disable-ipv6.conf
sysctl --system
echo 'Acquire::ForceIPv4 "true";' > /etc/apt/apt.conf.d/99force-ipv4
```
Cek hasilnya: `cat /proc/sys/net/ipv6/conf/all/disable_ipv6` harus `1`, dan `ip -6 addr` tidak menampilkan alamat IPv6.
Jangan matikan IPv6 kalau VPS Anda hanya punya IPv6 (tanpa IPv4).

---

### TESTED ON OS 
- UBUNTU 20.04 22 24.04 24.10
- DEBIAN 10 11 12


### FITUR TAMBAHAN
- Lakukan Uji Coba dengan memilih Trial Pada Licensi Key
- Tambah Swap 2 GiB
- Pemasangan yang dinamis
- Register IP Dari VPS
- Pointing Domain 
- Xray Core
- Penambahan fail2ban
- Auto block sebagian ads indo by default
- Auto clear log per 10 menit
- Auto deler expired
- User Details Akun
- Lock Xray
- Lock SSH
- Limit IP SSH on
- Limit IP Xray On
- Limit Qouta Xray On

### PORT INFO
```
- TROJAN WS 443
- TROJAN GRPC 443
- SHADOWSOCKS WS 443
- SHADOWSOCKS GRPC 443
- VLESS WS 443
- VLESS GRPC 443
- VLESS NONTLS 80
- VMESS WS 443
- VMESS GRPC 443
- VMESS NONTLS 80
- SSH WS / TLS 443
- SSH NON TLS 80 8880 8080 2080 2082 
- SLOWDNS 5300
```

### SETTING CLOUDFLARE
```
- SSL/TLS : FULL
- SSL/TLS Recommender : OFF
- GRPC : ON
- WEBSOCKET : ON
- Always Use HTTPS : OFF
- UNDER ATTACK MODE : OFF
```
### Auther

### CONTACT PX-OFFICIAL <br>
<a href="https://t.me/frel01" target=”_blank”><img src="https://img.shields.io/static/v1?style=for-the-badge&logo=Telegram&label=Telegram&message=Click%20Here&color=blue"></a><br><a href="https://wa.me/6283151636921" target=”_blank”><img src="https://img.shields.io/static/v1?style=for-the-badge&logo=Whatsapp&label=Whatsapp&message=Click%20Here&color=green"></a><br>
