#!/bin/bash
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
  pkill -u "$user" 2>/dev/null
  userdel -f "$user" >/dev/null 2>&1
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
