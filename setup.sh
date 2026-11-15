#!/bin/bash
# setup.sh -- wrapper publik. Isi asli ada di setup.enc (terenkripsi).
# File ini AMAN di-publish; tanpa password yang benar, isi script tidak bisa dibaca atau dijalankan.
set -euo pipefail

REPO_RAW="https://raw.githubusercontent.com/rifg67/script-rifts/main"
ENC_URL="${1:-$REPO_RAW/setup.enc}"
TMP_ENC=$(mktemp)
TMP_PLAIN=$(mktemp)
chmod 600 "$TMP_PLAIN"
trap 'rm -f "$TMP_ENC" "$TMP_PLAIN"' EXIT

echo "Mengambil paket terenkripsi..."
if ! curl -fsSL "$ENC_URL" -o "$TMP_ENC"; then
  echo "Gagal mengunduh $ENC_URL" >&2
  exit 1
fi

read -rsp "Password: " PW; echo

# Decrypt ke file sementara DULU, jangan langsung pipe ke bash.
# Kalau password salah, openssl baru ketahuan gagal di akhir proses (saat
# cek padding blok terakhir) -- kalau hasilnya di-pipe langsung ke bash,
# sampah yang sempat keluar duluan bisa kebaca/dicoba-eksekusi bash
# sebelum status gagalnya diketahui. Makanya harus ditampung dulu & dicek
# status exit openssl secara eksplisit sebelum ada satu baris pun dieksekusi.
if ! openssl enc -d -aes-256-cbc -pbkdf2 -iter 200000 -k "$PW" \
      -in "$TMP_ENC" -out "$TMP_PLAIN" 2>/dev/null; then
  unset PW
  echo "Password salah, atau paket korup/rusak." >&2
  exit 1
fi
unset PW

bash "$TMP_PLAIN"
