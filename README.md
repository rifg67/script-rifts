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

### INSTALL SCRIPT UBUNTU
<pre><code>apt install -y screen && wget -q https://raw.githubusercontent.com/rifg67/script-rifts/main/setup.sh && chmod +x setup.sh && ./setup.sh
</code></pre>

---

### INSTALL SCRIPT DEBIAN
<pre><code>apt update && apt install -y screen bsdextrautils util-linux coreutils wget curl && wget -q https://raw.githubusercontent.com/rifg67/script-rifts/main/setup.sh && chmod +x setup.sh && ./setup.sh

</code></pre>

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


---

# 📦 Catatan Patch & Cara Install (Local/SFTP Mode)

## File yang diubah dari versi asli

Cuma 12 file ini yang beda dari repo asli — kalau mau `git add` manual, cukup ini aja:

```
install/api-px.sh
install/ins-xray.sh
install/limit.sh
install/pointing.sh
install/set-br.sh
install/ssh-vpn.sh
install/vpn.sh
menu/menu.zip
setup.sh
slowdns/installsl.sh
sshws/insshws.sh
sshws/ohp.sh
```

### Ringkasan tiap file

| File | Perubahan |
|---|---|
| `setup.sh` | Deobfuscated ke plain text, tambah shebang `#!/bin/bash`, fix bug `echo "PeyxDev"` → `echo "$name"`, semua sub-script dijalanin lokal (bukan `wget` dari GitHub) |
| `install/ssh-vpn.sh` | Semua `wget`/`curl` ke GitHub diganti local-file copy dari `BASEDIR` |
| `install/ins-xray.sh` | Sama seperti di atas |
| `install/limit.sh` | Sama seperti di atas |
| `install/set-br.sh` | Sama seperti di atas |
| `install/vpn.sh` | Sama seperti di atas |
| `install/api-px.sh` | `server.js` di-copy lokal, bukan `curl` dari GitHub |
| `install/pointing.sh` | Script `wild` di-copy lokal |
| `slowdns/installsl.sh` | Binary `dnstt-server`/`dnstt-client` di-copy lokal |
| `sshws/insshws.sh` | `ws.service` & `ws-ovpn.service` dikasih port beda (700 & 2086) biar gak rebutan bind, + auto-sync port itu ke `haproxy.cfg` tiap kali install |
| `sshws/ohp.sh` | Binary `ohpserver` di-copy lokal |
| `menu/menu.zip` | Hapus baris `<b> Peyx Tunneling Script</b>` dari 8 file (`add-tro`, `add-ssh`, `add-vme`, `add-vle`, `trial-vle`, `trial-ssh`, `trial-vme`, `trial-tro`), zip di-repack pakai password sama (`rifts112008`) |

**Yang SENGAJA tidak diubah** (tetap connect ke GitHub sesuai permintaan):
- `install/autocpu.sh` / `autocpeu.sh` — cek versi & lisensi/IP (cron tiap 5 menit)
- Sistem backup (rclone/git push) — tetap upload ke GitHub

⚠️ **Penting:** `install/autocpu.sh` bisa narik ulang `menu/update.sh` dari GitHub kalau ngedeteksi versi VPS beda dari versi di repo GitHub `rifg67/script-rifts`. Kalau itu kejadian, dia akan re-download `menu.zip` versi GitHub (bukan versi lokal yang udah dipatch) dan nimpa `/usr/local/sbin/`. Supaya patch ini permanen, **push file-file di atas (terutama `menu/menu.zip`) ke repo GitHub `rifg67/script-rifts` juga**, jangan cuma disimpan lokal di VPS.

---

## Cara Install

### 1. Siapin VPS
Fresh install disaranin: Ubuntu 20.04/22.04 atau Debian 10/11.

### 2. Upload semua file via SFTP
Pake Termius (atau FileZilla/WinSCP/`scp`) — upload **seluruh isi folder ini** ke satu folder khusus di VPS, contoh `/root/script-rifts/`.

⚠️ **Jangan upload langsung ke `/root/` mentah-mentah** — taro di subfolder. Ada bagian script yang `rm /root/*.sh` di akhir proses, kalau source asli lo nyampur di `/root/` langsung bisa ikut kehapus.

Kalau pake Termius:
- Buka session VPS → buka tab/panel **SFTP**
- Bikin folder `/root/script-rifts/` di sisi VPS
- Drag semua file & folder (`install/`, `sshws/`, `slowdns/`, `menu/`, `setup.sh`, `tools.sh`, dst) ke situ
- Kalau ditanya transfer mode, pilih **Binary** (biar gak kena konversi line-ending CRLF yang bisa bikin script error)

### 3. Login SSH, masuk folder, kasih permission
```bash
ssh root@IP_VPS
cd /root/script-rifts
find . -name "*.sh" -exec chmod +x {} \;
```

### 4. Jalankan setup — WAJIB pakai `bash`, jangan `./setup.sh` atau `sh setup.sh`
```bash
bash setup.sh
```

### 5. Ikutin prompt
- Masukin nama lo
- Pilih domain (custom atau random)
- Tunggu proses install (SSH, Xray, WebSocket, backup, OHP, SlowDNS, dll) — semua diambil dari file lokal, gak nembak GitHub berkali-kali lagi

### 6. Verifikasi service jalan normal
```bash
systemctl status ws ws-ovpn nginx haproxy xray --no-pager
ss -tlnp | grep -E ":700|:2086|:1010"
```
Semua harus `active (running)` dan port-nya kedengeran di `ss`.

### 7. (Opsional tapi disaranin) Push patch ke GitHub repo lo
```bash
cd /root/script-rifts
git add install/api-px.sh install/ins-xray.sh install/limit.sh install/pointing.sh install/set-br.sh install/ssh-vpn.sh install/vpn.sh menu/menu.zip setup.sh slowdns/installsl.sh sshws/insshws.sh sshws/ohp.sh
git commit -m "fix 429 rate-limit, sshws port collision, remove vendor branding"
git push origin main
```
Ini penting biar auto-updater (`autocpu.sh`) narik versi yang udah bersih, bukan versi lama dari GitHub.

---

## Kalau ada error

Kirim output persis dari:
```bash
journalctl -u <nama-service> -n 30 --no-pager
```
Biar gampang dilacak dari log-nya langsung.
