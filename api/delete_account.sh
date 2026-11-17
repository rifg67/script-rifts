#!/bin/bash
# Service API jalan dengan PATH minim (tanpa /usr/sbin) -> userdel "command not found". Tambahkan manual.
export PATH="$PATH:/usr/local/sbin:/usr/sbin:/sbin"
# Pakai: bash delete_account.sh <vmess|vless|trojan|ssh> <username>
# Dipanggil oleh api.js (/deleteaccount). Penanda di config.json beda per protokol:
#   vmess "###"   vless "#&"   trojan "#!"   -> hapus hanya milik protokol yang diminta.
R="${ROOT_PREFIX:-}"   # kosong di VPS asli; dipakai untuk uji coba
type="$1"; user="$2"

if [[ ! "$user" =~ ^[A-Za-z0-9]{1,32}$ ]]; then echo "ERROR: username tidak valid"; exit 1; fi

case "$type" in
  vmess)  mark='###' ;;
  vless)  mark='#&'  ;;
  trojan) mark='#!'  ;;
  ssh)    mark='' ;;
  *) echo "ERROR: tipe tidak dikenal"; exit 1 ;;
esac

if [[ "$type" == "ssh" ]]; then
  if ! id "$user" &>/dev/null; then echo "ERROR: user $user tidak ditemukan"; exit 1; fi
  # --- putuskan SESI AKTIF dulu (userdel saja tidak memutus koneksi yang sudah tersambung) ---
  # 1) Dropbear (dipakai SSH WS/tunnel): prosesnya milik root, jadi cari PID dari log login (cara yang sama seperti menu "tendang")
  LOG=/var/log/auth.log; [ -e /var/log/secure ] && LOG=/var/log/secure
  for pid in $(grep -i "dropbear\[[0-9]*\]" "$LOG" 2>/dev/null | grep -i "auth succeeded for '${user}'" \
               | sed -E 's/.*dropbear\[([0-9]+)\].*/\1/' | sort -u); do
    ps -p "$pid" -o comm= 2>/dev/null | grep -q dropbear && kill -9 "$pid" 2>/dev/null
  done
  # 2) OpenSSH: proses "sshd: user [priv]" dan "sshd: user@..."
  pkill -KILL -f "^sshd: ${user}(@| \\[)" 2>/dev/null
  pkill -KILL -u "$user" 2>/dev/null
  sleep 1
  err=$(userdel -f "$user" 2>&1)
  if id "$user" &>/dev/null; then
    # coba sekali lagi setelah semua proses user dibunuh
    pkill -KILL -u "$user" 2>/dev/null; sleep 1
    err2=$(userdel -f "$user" 2>&1)
    if id "$user" &>/dev/null; then
      echo "ERROR: userdel gagal: ${err2:-${err:-tanpa pesan}}"; exit 1
    fi
  fi
  sed -i "/^${user}:/d" $R/etc/group 2>/dev/null
  sed -i "/^#ssh# ${user} /d" $R/etc/ssh/.ssh.db 2>/dev/null
  rm -f "$R/etc/ssh/${user}" "$R/etc/kyt/limit/ssh/ip/${user}" \
        "$R/detail/ssh/${user}.txt" "$R/var/www/html/ssh-${user}.txt"
  echo "OK"; exit 0
fi

CFG="$R/etc/xray/config.json"
if ! grep -qE "^${mark} ${user} " "$CFG"; then echo "ERROR: user $user ($type) tidak ditemukan"; exit 1; fi

cp "$CFG" "${CFG}.delbak"
# hapus dari baris penanda sampai baris klien "},{..." (semua kemunculan: ws + grpc)
sed -i "/^${mark} ${user} /,/^},{/d" "$CFG"
[ -f "$R/etc/${type}/.${type}.db" ] && sed -i "/^${mark} ${user} /d" "$R/etc/${type}/.${type}.db"
# hanya file milik user ini (JANGAN hapus folder limit IP semua user)
rm -f "$R/etc/${type}/${user}" "$R/etc/kyt/limit/${type}/ip/${user}" \
      "$R/detail/${type}/${user}.txt" "$R/var/www/html/${type}-${user}.txt"
[ -z "$R" ] && systemctl restart xray >/dev/null 2>&1
echo "OK"; exit 0
