#!/bin/bash
# fixdropbear.sh
# Naikkan batas koneksi "belum login" Dropbear (MAX_UNAUTH_PER_IP).
#
# Masalah: Dropbear bawaan cuma izinkan 5 koneksi belum-login per IP.
# Di VPS tunneling semua user masuk lewat haproxy/ws, jadi Dropbear melihat
# semuanya dari 127.0.0.1 dan ratusan user rebutan 5 slot itu. Akibatnya SSH
# putus-nyambung (koneksi login baru ditolak diam-diam saat slot penuh).
#
# Pakai : bash fixdropbear.sh
# Opsi  : PER_IP=200 GLOBAL=1000 bash fixdropbear.sh
# Aman dijalankan berulang (kalau sudah dipatch, langsung selesai).
# Kalau Dropbear gagal start setelah diganti, binary lama otomatis dikembalikan.

set -u

PER_IP="${PER_IP:-200}"
GLOBAL="${GLOBAL:-1000}"
MARK="/etc/dropbear/.unauth_patched"

die() { echo "[GAGAL] $*" >&2; exit 1; }

[ "$(id -u)" -eq 0 ] || die "jalankan sebagai root"

BIN=$(command -v dropbear || true)
[ -n "$BIN" ] || BIN=/usr/sbin/dropbear
[ -x "$BIN" ] || die "dropbear tidak ditemukan"

V=$("$BIN" -V 2>&1 | grep -oE '[0-9]{4}\.[0-9]+' | head -1)
[ -n "$V" ] || die "versi dropbear tidak terbaca"

mkdir -p /etc/dropbear
if [ -f "$MARK" ] && grep -qx "$V $PER_IP" "$MARK" 2>/dev/null; then
    echo "[OK] Dropbear $V sudah dipatch (PER_IP=$PER_IP). Tidak ada yang dikerjakan."
    exit 0
fi

echo "[1/5] Pasang paket build..."
export DEBIAN_FRONTEND=noninteractive
apt-get install -y -qq build-essential zlib1g-dev bzip2 wget >/dev/null 2>&1 \
    || die "apt-get install gagal (cek koneksi internet / apt)"

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

echo "[2/5] Download dropbear-$V..."
wget -q -O "$TMP/db.tar.bz2" "https://matt.ucc.asn.au/dropbear/releases/dropbear-$V.tar.bz2" \
    || die "download gagal"
tar xjf "$TMP/db.tar.bz2" -C "$TMP" || die "file download rusak"
cd "$TMP/dropbear-$V" || die "folder source tidak ada"

echo "[3/5] Compile (1-2 menit)..."
printf '#define MAX_UNAUTH_PER_IP %s\n#define MAX_UNAUTH_CLIENTS %s\n' "$PER_IP" "$GLOBAL" > localoptions.h
./configure >/dev/null 2>&1 || die "configure gagal"
make PROGRAMS="dropbear" >/dev/null 2>&1 || die "make gagal"
./dropbear -V >/dev/null 2>&1 || die "binary hasil build tidak bisa jalan"

echo "[4/5] Ganti binary..."
[ -f "$BIN.bak" ] || cp -p "$BIN" "$BIN.bak"
cp dropbear "$BIN.new" && chmod 755 "$BIN.new" && mv -f "$BIN.new" "$BIN" || die "gagal mengganti binary"
systemctl restart dropbear
sleep 2
if ! systemctl is-active --quiet dropbear; then
    echo "[!] Dropbear gagal start, mengembalikan binary lama..."
    cp -p "$BIN.bak" "$BIN.new" && mv -f "$BIN.new" "$BIN"
    systemctl restart dropbear
    die "dropbear baru gagal start, sudah dikembalikan ke versi lama"
fi
apt-mark hold dropbear-bin >/dev/null 2>&1 || true
echo "$V $PER_IP" > "$MARK"

echo "[5/5] Tes 12 koneksi bersamaan..."
PORT=$(ss -tlnp 2>/dev/null | awk '/dropbear/ {n=split($4,a,":"); print a[n]; exit}')
PORT="${PORT:-109}"
rm -f "$TMP"/b*
for i in $(seq 1 12); do
    ( timeout 5 bash -c "exec 3<>/dev/tcp/127.0.0.1/$PORT; head -c 7 <&3 > $TMP/b$i; sleep 4" ) 2>/dev/null &
done
sleep 6
wait
n=$(grep -l SSH "$TMP"/b* 2>/dev/null | wc -l)
echo "      Hasil: $n/12 koneksi dapat banner (port $PORT)"
if [ "$n" -ge 10 ]; then
    echo "[OK] Selesai. Dropbear $V aktif dengan batas $PER_IP per IP."
else
    echo "[CEK] Hasil tes rendah. Kirim output ini untuk dicek."
fi
