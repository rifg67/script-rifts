#!/bin/bash
# Update API di VPS yang SUDAH terpasang (tanpa ganti AUTH_KEY)
RAW="https://raw.githubusercontent.com/rifg67/script-rifts/main/api"
D=/usr/bin/api-xwan
[ -d "$D" ] || { echo "api-xwan belum terpasang, jalankan api.sh dulu"; exit 1; }
cp "$D/api.js" "$D/api.js.bak" 2>/dev/null
curl -fsSL "$RAW/api.js" -o "$D/api.js.new" && curl -fsSL "$RAW/delete_account.sh" -o "$D/delete_account.sh" || { echo "Gagal download"; exit 1; }
if node --check "$D/api.js.new" 2>/dev/null; then
  mv "$D/api.js.new" "$D/api.js"; chmod +x "$D"/delete_account.sh
  # api.js dari repo belum berisi /status, pasang lagi (aman diulang)
  curl -fsSL "$RAW/pasang-status.sh" | bash
  systemctl restart apisellvpn.service && echo "✅ API diperbarui"
else
  rm -f "$D/api.js.new"; echo "❌ api.js baru error, batal (api.js lama tetap dipakai)"
fi
