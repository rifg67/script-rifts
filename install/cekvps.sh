#!/bin/bash
# cekvps.sh
# Cek kesehatan VPS tunneling. Hanya membaca dan menguji, tidak mengubah apa pun.
# Pakai: bash cekvps.sh

WARN=0
ok()  { echo "  [OK]   $*"; }
bad() { echo "  [CEK]  $*"; WARN=$((WARN+1)); }

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

echo "== Dropbear =="
BIN=$(command -v dropbear || echo /usr/sbin/dropbear)
echo "  Versi: $("$BIN" -V 2>&1 | head -1)"
PORT=$(ss -tlnp 2>/dev/null | awk '/dropbear/ {n=split($4,a,":"); print a[n]; exit}')
PORT="${PORT:-109}"
for i in $(seq 1 12); do
    ( timeout 5 bash -c "exec 3<>/dev/tcp/127.0.0.1/$PORT; head -c 7 <&3 > $TMP/b$i; sleep 4" ) 2>/dev/null &
done
sleep 6
wait
n=$(grep -l SSH "$TMP"/b* 2>/dev/null | wc -l)
if [ "$n" -ge 10 ]; then
    ok "tes slot $n/12 (port $PORT)"
else
    bad "tes slot $n/12: batas koneksi kecil, jalankan fixdropbear.sh"
fi

echo "== Service =="
for s in dropbear ws haproxy nginx xray; do
    a=$(systemctl is-active "$s" 2>/dev/null)
    if [ "$a" = "active" ]; then ok "$s"; else bad "$s = $a"; fi
done

echo "== Jalur 443 dan 80 =="
ssl=$( (sleep 2) | timeout 6 openssl s_client -connect 127.0.0.1:443 -quiet 2>/dev/null | head -c 20 | tr -d '\r\n')
case "$ssl" in SSH-2.0*) ok "SSL 443 -> $ssl" ;; *) bad "SSL 443 tidak membalas banner SSH" ;; esac
ws=$(curl -s -i -H 'Upgrade: websocket' -H 'Connection: Upgrade' --max-time 2 http://127.0.0.1:80/ 2>/dev/null | head -1 | tr -d '\r')
case "$ws" in *101*) ok "WebSocket 80 -> 101" ;; *) bad "WebSocket 80 tidak 101 (hasil: '${ws:0:30}')" ;; esac

echo "== Sertifikat =="
end=$(echo | openssl s_client -connect 127.0.0.1:443 2>/dev/null | openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2)
if [ -z "$end" ]; then
    bad "sertifikat di 443 tidak terbaca"
else
    days=$(( ($(date -d "$end" +%s) - $(date +%s)) / 86400 ))
    if [ "$days" -lt 0 ]; then bad "EXPIRED ($end), sudah lewat $((-days)) hari"
    elif [ "$days" -lt 14 ]; then bad "sisa $days hari ($end), segera perpanjang"
    else ok "sisa $days hari ($end)"; fi
fi
if [ -f /etc/haproxy/hap.pem ] && [ -f /etc/xray/xray.crt ]; then
    h=$(openssl x509 -in /etc/haproxy/hap.pem -noout -enddate 2>/dev/null)
    x=$(openssl x509 -in /etc/xray/xray.crt -noout -enddate 2>/dev/null)
    if [ "$h" = "$x" ]; then ok "hap.pem sama dengan xray.crt"; else bad "hap.pem BEDA dari xray.crt (haproxy pakai sertifikat lama)"; fi
fi

echo "== Beban =="
echo "  Load: $(cut -d' ' -f1-3 /proc/loadavg) | koneksi 443: $(ss -tn state established '( sport = :443 )' | wc -l)"

echo "== Kill-switch (detek/autocpu) =="
f=$(ls /usr/bin/detek /usr/bin/securited 2>/dev/null | tr '\n' ' ')
[ -z "$f" ] && ok "tidak ada file detek/securited" || bad "ada file: $f"
c=$(grep -lE "detek|autocpu" /etc/cron.d/* 2>/dev/null | tr '\n' ' ')
[ -z "$c" ] && ok "tidak ada cron detek/autocpu" || bad "cron ditemukan: $c"
[ -x /usr/bin/autocpu ] && bad "/usr/bin/autocpu masih executable (chmod -x /usr/bin/autocpu)" || ok "autocpu nonaktif"
u=$(id xwan peyx 2>/dev/null | tr '\n' ' ')
[ -z "$u" ] && ok "user xwan/peyx tidak ada" || bad "user ditemukan: $u"

echo
if [ "$WARN" -eq 0 ]; then echo "HASIL: semua aman."; else echo "HASIL: $WARN hal perlu dicek (lihat [CEK] di atas)."; fi
