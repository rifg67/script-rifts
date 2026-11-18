#!/bin/bash
# update.sh -- wrapper publik. Isi asli ada di menu/update.enc (terenkripsi).
# File ini AMAN di-publish; tanpa password yang benar, isi script tidak bisa dibaca atau dijalankan.
set -euo pipefail

REPO_RAW="https://raw.githubusercontent.com/rifg67/script-rifts/main"
ENC_URL="${1:-$REPO_RAW/menu/update.enc}"
TMP_ENC=$(mktemp)
TMP_PLAIN=$(mktemp)
chmod 600 "$TMP_PLAIN"
trap 'rm -f "$TMP_ENC" "$TMP_PLAIN"' EXIT

echo "Mengambil paket terenkripsi..."
if ! curl -fsSL "$ENC_URL" -o "$TMP_ENC"; then
  echo "Gagal mengunduh $ENC_URL" >&2
  exit 1
fi

# Kalau dipanggil dari dalam setup.sh (yang sudah minta password di awal),
# password itu diwariskan lewat env var RIFTS_AES_PW -- jadi tidak perlu
# nanya ulang. Kalau dijalankan sendiri (misal update manual lewat menu),
# env var ini kosong, jadi tetap nanya seperti biasa.
if [[ -n "${RIFTS_AES_PW:-}" ]]; then
  PW="$RIFTS_AES_PW"
else
  read -rsp "Password: " PW; echo
fi

if ! openssl enc -d -aes-256-cbc -pbkdf2 -iter 200000 -k "$PW" \
      -in "$TMP_ENC" -out "$TMP_PLAIN" 2>/dev/null; then
  unset PW
  echo "Password salah, atau paket korup/rusak." >&2
  exit 1
fi
unset PW

bash "$TMP_PLAIN"
