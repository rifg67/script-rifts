#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# fix-restore.sh
# Cek (dan opsional perbaiki) kondisi VPS setelah restore backup.
#
#   bash fix-restore.sh          -> CEK SAJA, tidak mengubah apa pun
#   bash fix-restore.sh --fix    -> cek + perbaiki yang aman
#                                   (backup dulu, minta konfirmasi)
#   bash fix-restore.sh --fix --yes   -> perbaiki tanpa tanya
#   bash fix-restore.sh --install-auto -> pasang penjaga otomatis (timer systemd,
#                                         dibangunkan saat file restore berubah +
#                                         keliling tiap 3 jam; --interval=6h untuk ganti)
#   bash fix-restore.sh --remove-auto  -> copot penjaga otomatis
# ═══════════════════════════════════════════════════════════════

# Lokasi file (bisa di-override lewat environment variable)
XRAY_CFG="${XRAY_CFG:-/etc/xray/config.json}"
XRAY_CRT="${XRAY_CRT:-/etc/xray/xray.crt}"
XRAY_KEY="${XRAY_KEY:-/etc/xray/xray.key}"
DOMAIN_FILE="${DOMAIN_FILE:-/etc/xray/domain}"
HAP_PEM="${HAP_PEM:-/etc/haproxy/hap.pem}"
HAP_CFG="${HAP_CFG:-/etc/haproxy/haproxy.cfg}"
WS_CFG="${WS_CFG:-/usr/bin/config.conf}"
HAP_SOCK="${HAP_SOCK:-/run/haproxy/admin.sock}"
DB_PORT="${DB_PORT:-109}"
XRAY_BIN="${XRAY_BIN:-/usr/local/bin/xray}"

SYSTEMD_DIR="${SYSTEMD_DIR:-/etc/systemd/system}"
BIN_DIR="${BIN_DIR:-/usr/local/sbin}"
STATE_DIR="${STATE_DIR:-/var/lib/fix-restore}"
LOG_FILE="${LOG_FILE:-/var/log/fix-restore.log}"
LOCK_FILE="${LOCK_FILE:-/run/fix-restore.lock}"
SETTLE_SECS="${SETTLE_SECS:-30}"       # file kunci harus tidak berubah selama ini
AUTO_MAX_WAIT="${AUTO_MAX_WAIT:-180}"  # maksimal menunggu file stabil (detik)
POLL_SECS="${POLL_SECS:-5}"
INTERVAL="${INTERVAL:-3h}"             # keliling cadangan (timer)
COOLDOWN_SECS="${COOLDOWN_SECS:-60}"   # jeda minimal antar perbaikan otomatis

FIX=0
YES=0
AUTO=0
INSTALL_AUTO=0
REMOVE_AUTO=0
for a in "$@"; do
  case "$a" in
    --fix) FIX=1 ;;
    --yes) YES=1 ;;
    --auto) AUTO=1; FIX=1; YES=1 ;;
    --install-auto) INSTALL_AUTO=1 ;;
    --remove-auto) REMOVE_AUTO=1 ;;
    --interval=*) INTERVAL="${a#--interval=}" ;;
  esac
done

# ───────────────────────── pasang / copot penjaga otomatis
if [ "$INSTALL_AUTO" = 1 ]; then
  mkdir -p "$BIN_DIR" "$STATE_DIR" "$SYSTEMD_DIR"
  SELF="$(readlink -f "$0")"
  if [ "$SELF" != "$BIN_DIR/fix-restore" ]; then
    cp "$SELF" "$BIN_DIR/fix-restore" || { echo "gagal menyalin script ke $BIN_DIR"; exit 1; }
  fi
  chmod +x "$BIN_DIR/fix-restore"
  cat > "$SYSTEMD_DIR/fix-restore.service" <<UNIT
[Unit]
Description=Perbaikan otomatis konfigurasi VPS setelah install/restore

[Service]
Type=oneshot
TimeoutStartSec=600
LogLevelMax=warning
ExecStart=$BIN_DIR/fix-restore --auto
UNIT
  cat > "$SYSTEMD_DIR/fix-restore.timer" <<UNIT
[Unit]
Description=Keliling cadangan fix-restore tiap $INTERVAL

[Timer]
OnBootSec=3min
OnActiveSec=2min
OnUnitActiveSec=$INTERVAL

[Install]
WantedBy=timers.target
UNIT
  cat > "$SYSTEMD_DIR/fix-restore.path" <<UNIT
[Unit]
Description=Bangunkan fix-restore saat file restore berubah

[Path]
PathChanged=$XRAY_CFG
PathChanged=$DOMAIN_FILE
PathChanged=$XRAY_CRT
PathChanged=$XRAY_KEY
Unit=fix-restore.service

[Install]
WantedBy=multi-user.target
UNIT
  systemctl daemon-reload
  systemctl enable --now fix-restore.timer
  systemctl enable --now fix-restore.path
  echo "Penjaga otomatis terpasang:"
  echo "  - dibangunkan saat file restore berubah (config.json/domain/sertifikat xray)"
  echo "  - keliling cadangan tiap $INTERVAL"
  echo "  Log: $LOG_FILE"
  echo "Cek:    systemctl list-timers fix-restore.timer; systemctl status fix-restore.path"
  echo "Copot:  fix-restore --remove-auto"
  exit 0
fi
if [ "$REMOVE_AUTO" = 1 ]; then
  systemctl disable --now fix-restore.timer 2>/dev/null
  systemctl disable --now fix-restore.path 2>/dev/null
  rm -f "$SYSTEMD_DIR/fix-restore.service" "$SYSTEMD_DIR/fix-restore.timer" "$SYSTEMD_DIR/fix-restore.path" "$BIN_DIR/fix-restore"
  systemctl daemon-reload
  echo "Penjaga otomatis dicopot."
  exit 0
fi

G='\033[1;32m'; Y='\033[1;33m'; R='\033[1;31m'; N='\033[0m'
if [ "$AUTO" = 1 ]; then G=''; Y=''; R=''; N=''; fi
ok()   { echo -e "[ ${G}OK${N}   ] $*"; }
warn() { echo -e "[ ${Y}WARN${N} ] $*"; }
bad()  { echo -e "[ ${R}FAIL${N} ] $*"; }
info() { echo -e "[ INFO ] $*"; }

PROBLEMS=0
FIXABLE=()          # daftar perbaikan yang tersedia
RESTART_HAP=0
RESTART_WS=0
RESTART_XRAY=0

problem() { PROBLEMS=$((PROBLEMS+1)); }

hash_pub_crt() { openssl x509 -in "$1" -noout -pubkey 2>/dev/null | openssl sha256 2>/dev/null | awk '{print $NF}'; }
hash_pub_key() { openssl pkey -in "$1" -pubout 2>/dev/null | openssl sha256 2>/dev/null | awk '{print $NF}'; }
cert_cn()      { openssl x509 -in "$1" -noout -subject 2>/dev/null | sed -n 's/.*CN *= *//p'; }
cert_end()     { openssl x509 -in "$1" -noout -enddate 2>/dev/null | cut -d= -f2; }
listening()    { ss -tln 2>/dev/null | awk '{print $4}' | grep -qE "[:.]$1\$"; }


# Uji jalur SSH-WebSocket: kirim Upgrade websocket, lalu cek banner SSH sampai.
wstest() {
  command -v python3 >/dev/null 2>&1 || { warn "python3 tidak ada, uji SSH-WS dilewati"; return 0; }
  python3 - "${DOMAIN:-localhost}" "${WSTEST_TARGETS:-ws-langsung:10015:0,nginx:1010:0,haproxy-80:80:0,haproxy-443-tls:443:1}" <<'PYEOF'
import socket, ssl, sys, time
D, targets = sys.argv[1], sys.argv[2]
REQ = ("GET / HTTP/1.1\r\nHost: %s\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n\r\n" % D).encode()
def baca(s, sampai, cukup):
    data = b""
    while time.time() < sampai and not cukup(data):
        try:
            b = s.recv(4096)
        except socket.timeout:
            continue
        if not b:
            break
        data += b
    return data
gagal = 0
for t in targets.split(","):
    nama, port, tls = t.split(":")
    try:
        s = socket.create_connection(("127.0.0.1", int(port)), timeout=4)
        if tls == "1":
            c = ssl.create_default_context(); c.check_hostname = False; c.verify_mode = ssl.CERT_NONE
            s = c.wrap_socket(s, server_hostname=D)
        s.settimeout(1)
        s.sendall(REQ)
        data = baca(s, time.time() + 3, lambda d: b"\r\n\r\n" in d)
        s.sendall(b"SSH-2.0-test\r\n")
        data += baca(s, time.time() + 3, lambda d: b"SSH-" in d.split(b"\r\n\r\n", 1)[-1])
        s.close()
        ok = b"SSH-" in data.split(b"\r\n\r\n", 1)[-1]
        print("  %-18s %s" % (nama, "banner SSH sampai" if ok else "TIDAK ada banner SSH"))
        if not ok: gagal += 1
    except Exception as e:
        print("  %-18s ERROR: %s" % (nama, e)); gagal += 1
sys.exit(gagal)
PYEOF
}

ACTED=0
if [ "$AUTO" = 1 ]; then
  mkdir -p "$STATE_DIR" 2>/dev/null
  # satu proses saja pada satu waktu
  exec 9>"$LOCK_FILE" 2>/dev/null && { command -v flock >/dev/null 2>&1 && flock -n 9 || true; }
  # jangan mengganggu install/apt yang sedang berjalan
  if pgrep -f "setup\.sh|apt-get|dpkg" >/dev/null 2>&1; then exit 0; fi
  # tunggu sampai file kunci stabil (restore/install sudah selesai); maksimal AUTO_MAX_WAIT detik
  WAITED=0
  while :; do
    NOW="$(date +%s)"; BUSY=0
    for f in "$XRAY_CFG" "$XRAY_CRT" "$XRAY_KEY" "$DOMAIN_FILE" "$HAP_CFG" "$WS_CFG" "$HAP_PEM"; do
      [ -e "$f" ] || continue
      M="$(stat -c %Y "$f" 2>/dev/null || echo 0)"
      [ $((NOW - M)) -lt "$SETTLE_SECS" ] && BUSY=1
    done
    [ "$BUSY" = 0 ] && break
    [ "$WAITED" -ge "$AUTO_MAX_WAIT" ] && exit 0
    sleep "$POLL_SECS"; WAITED=$((WAITED + POLL_SECS))
  done
  # jeda antar perbaikan
  if [ -r "$STATE_DIR/last" ]; then
    L="$(cat "$STATE_DIR/last" 2>/dev/null || echo 0)"
    if [ $((NOW - L)) -lt "$COOLDOWN_SECS" ]; then exit 0; fi
  fi
  # keluaran ditampung; hanya masuk log kalau ada yang terjadi
  TMPOUT="$(mktemp)"
  exec >"$TMPOUT" 2>&1
  flush_log() {
    WRITE=0
    if [ "$ACTED" = 1 ]; then
      WRITE=1
    elif [ "$PROBLEMS" -gt 0 ]; then
      # masalah yang tidak bisa diperbaiki otomatis: catat paling sering sekali per jam
      LL="$(cat "$STATE_DIR/lastlog" 2>/dev/null || echo 0)"
      [ $(( $(date +%s) - LL )) -ge 3600 ] && WRITE=1
    fi
    if [ "$WRITE" = 1 ]; then
      [ -f "$LOG_FILE" ] && [ "$(stat -c %s "$LOG_FILE" 2>/dev/null || echo 0)" -gt 204800 ] && : > "$LOG_FILE"
      { echo "===== $(date '+%F %T') ====="; cat "$TMPOUT"; } >> "$LOG_FILE" 2>/dev/null
      date +%s > "$STATE_DIR/lastlog" 2>/dev/null
    fi
    rm -f "$TMPOUT"
    exit 0
  }
  trap flush_log EXIT
fi

echo "══════════════ CEK VPS SETELAH RESTORE ══════════════"

# ───────────────────────── 1. DOMAIN & DNS
DOMAIN=""
if [ -r "$DOMAIN_FILE" ]; then
  DOMAIN="$(tr -d ' \r\n' < "$DOMAIN_FILE")"
fi
if [ -z "$DOMAIN" ]; then
  bad "domain kosong / $DOMAIN_FILE tidak ada"; problem
elif [ "$AUTO" = 1 ]; then
  :   # mode otomatis: lewati cek jaringan
else
  MYIP="$(curl -s --max-time 6 ifconfig.me 2>/dev/null)"
  DNSIP="$(getent hosts "$DOMAIN" 2>/dev/null | awk '{print $1; exit}')"
  if [ -n "$MYIP" ] && [ "$MYIP" = "$DNSIP" ]; then
    ok "domain $DOMAIN -> $DNSIP (sama dengan IP VPS)"
  else
    bad "domain $DOMAIN -> '${DNSIP:-tidak resolve}', IP VPS '${MYIP:-?}' (DNS belum mengarah ke VPS ini)"; problem
  fi
fi

# ───────────────────────── 2. SERTIFIKAT XRAY
XRAY_CERT_OK=0
if [ ! -r "$XRAY_CRT" ] || [ ! -r "$XRAY_KEY" ]; then
  bad "$XRAY_CRT atau $XRAY_KEY tidak ada"; problem
else
  CN="$(cert_cn "$XRAY_CRT")"
  H1="$(hash_pub_crt "$XRAY_CRT")"; H2="$(hash_pub_key "$XRAY_KEY")"
  if [ -n "$H1" ] && [ "$H1" = "$H2" ]; then
    ok "xray.crt cocok dengan xray.key (CN=$CN, sampai $(cert_end "$XRAY_CRT"))"
    XRAY_CERT_OK=1
  else
    bad "xray.crt dan xray.key TIDAK cocok"; problem
  fi
  if [ -n "$DOMAIN" ] && [ "$CN" != "$DOMAIN" ]; then
    warn "CN sertifikat xray ($CN) berbeda dengan domain ($DOMAIN)"; problem
  fi
fi

# ───────────────────────── 3. hap.pem (dipakai haproxy)
if [ ! -r "$HAP_PEM" ]; then
  bad "$HAP_PEM tidak ada"; problem
  [ "$XRAY_CERT_OK" = 1 ] && FIXABLE+=("hap")
else
  HCN="$(cert_cn "$HAP_PEM")"
  if [ -n "$CN" ] && [ "$HCN" = "$CN" ]; then
    ok "hap.pem sama dengan sertifikat xray (CN=$HCN, sampai $(cert_end "$HAP_PEM"))"
  else
    bad "hap.pem CN='$HCN' tapi sertifikat xray CN='$CN' (haproxy melayani sertifikat yang salah)"; problem
    [ "$XRAY_CERT_OK" = 1 ] && FIXABLE+=("hap")
  fi
fi

# ───────────────────────── 4. haproxy -> dropbear
HAP_DB_LINE="$(grep -E '^[[:space:]]*server[[:space:]]+dropbear_server' "$HAP_CFG" 2>/dev/null | head -1)"
HAP_DB_PORT="$(echo "$HAP_DB_LINE" | sed -n 's/.*127\.0\.0\.1:\([0-9]*\).*/\1/p')"
if [ -z "$HAP_DB_PORT" ]; then
  bad "baris dropbear_server tidak ditemukan di $HAP_CFG"; problem
elif [ "$HAP_DB_PORT" = "$DB_PORT" ]; then
  ok "haproxy -> dropbear di 127.0.0.1:$HAP_DB_PORT"
else
  bad "haproxy menunjuk dropbear ke port $HAP_DB_PORT (seharusnya $DB_PORT)"; problem
  listening "$DB_PORT" && FIXABLE+=("hapdb")
fi

if listening "$DB_PORT"; then
  ok "dropbear listen di port $DB_PORT"
else
  bad "tidak ada yang listen di port $DB_PORT (cek: systemctl status dropbear)"; problem
fi

# ───────────────────────── 5. ws (SSH WebSocket) -> dropbear
if [ -r "$WS_CFG" ]; then
  WS_PORT="$(grep -m1 'target_port:' "$WS_CFG" | awk '{print $2}' | tr -d '\r')"
  if [ "$WS_PORT" = "$DB_PORT" ]; then
    ok "ws SSH (listen 10015) -> port $WS_PORT"
  else
    bad "ws SSH menunjuk ke port $WS_PORT (seharusnya $DB_PORT)"; problem
    listening "$DB_PORT" && FIXABLE+=("ws")
  fi
else
  warn "$WS_CFG tidak ada (lewati cek ws)"
fi

# ───────────────────────── 6. xray: tag outbound freedom
if [ -r "$XRAY_CFG" ]; then
  if sed -n '/"outbounds"/,/"blackhole"/p' "$XRAY_CFG" | grep -q '"tag": *"api"'; then
    bad "outbound freedom bertag \"api\" (bug: v2ray login tapi tidak ada internet)"; problem
    FIXABLE+=("xraytag")
  else
    ok "outbound freedom tidak bertag \"api\""
  fi
else
  bad "$XRAY_CFG tidak ada"; problem
fi

# ───────────────────────── 7. status service
for s in xray nginx haproxy dropbear ws; do
  if systemctl is-active --quiet "$s" 2>/dev/null; then
    ok "service $s aktif"
  else
    bad "service $s TIDAK aktif"; problem
  fi
done

# ───────────────────────── 8. status backend haproxy
if [ -S "$HAP_SOCK" ] || [ -e "$HAP_SOCK" ]; then
  ST="$(echo "show stat" | socat stdio "$HAP_SOCK" 2>/dev/null | grep '^dropbear_backend,dropbear_server' | cut -d, -f18)"
  if [ "$ST" = "UP" ]; then
    ok "haproxy dropbear_server: UP"
  else
    bad "haproxy dropbear_server: ${ST:-tidak diketahui}"; problem
  fi
fi

# ───────────────────────── 9. uji jalur SSH-WebSocket (banner SSH)
if [ "$AUTO" != 1 ] && systemctl is-active --quiet ws 2>/dev/null; then
  info "uji SSH-WebSocket (ws -> dropbear):"
  if wstest; then
    ok "SSH-WebSocket: banner SSH sampai di semua jalur"
  else
    bad "SSH-WebSocket: ada jalur yang tidak meneruskan banner SSH"; problem
  fi
fi

echo "═════════════════════════════════════════════════════"
if [ "$PROBLEMS" -eq 0 ]; then
  echo -e "${G}Semua cek lolos.${N}"
  exit 0
fi
echo -e "${Y}Ditemukan $PROBLEMS masalah.${N}"

if [ "$FIX" -ne 1 ]; then
  if [ "${#FIXABLE[@]}" -gt 0 ]; then
    info "ada ${#FIXABLE[@]} perbaikan otomatis tersedia. Jalankan:  bash $0 --fix"
  fi
  exit 1
fi

if [ "${#FIXABLE[@]}" -eq 0 ]; then
  info "tidak ada perbaikan otomatis yang aman; selesaikan manual dari pesan FAIL di atas"
  exit 1
fi

# ───────────────────────── PERBAIKAN
echo
info "perbaikan yang akan dilakukan: ${FIXABLE[*]}"
warn "restart service memutus koneksi sebentar (beberapa detik)"
if [ "$YES" -ne 1 ]; then
  read -r -p "Lanjut? [y/N] " ans < /dev/tty
  case "$ans" in y|Y) ;; *) echo "dibatalkan"; exit 1 ;; esac
fi

ACTED=1
BAK="${BAK_BASE:-/root}/bak-fix-restore-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BAK"
for f in "$XRAY_CFG" "$HAP_PEM" "$HAP_CFG" "$WS_CFG"; do
  [ -e "$f" ] && cp -a "$f" "$BAK/" 2>/dev/null
done
info "backup file lama: $BAK"

for fx in "${FIXABLE[@]}"; do
  case "$fx" in
    hap)
      cat "$XRAY_KEY" "$XRAY_CRT" > "$HAP_PEM" && RESTART_HAP=1 && ok "hap.pem dibuat ulang dari xray.key + xray.crt"
      ;;
    hapdb)
      sed -i -E "s#(server[[:space:]]+dropbear_server[[:space:]]+127\.0\.0\.1:)[0-9]+#\1${DB_PORT}#" "$HAP_CFG" \
        && RESTART_HAP=1 && ok "haproxy dropbear_server diarahkan ke port $DB_PORT"
      ;;
    ws)
      sed -i "0,/target_port: .*/s//target_port: ${DB_PORT}/" "$WS_CFG" \
        && RESTART_WS=1 && ok "ws SSH diarahkan ke port $DB_PORT"
      ;;
    xraytag)
      sed -i '/"outbounds"/,/"blackhole"/ s/"tag": *"api"/"tag": "direct"/' "$XRAY_CFG" && RESTART_XRAY=1 && ok "tag outbound freedom diganti jadi direct"
      ;;
  esac
done

# Validasi sebelum restart; kalau gagal, kembalikan file
if [ "$RESTART_XRAY" = 1 ]; then
  if ! "$XRAY_BIN" run -test -config "$XRAY_CFG" >/dev/null 2>&1; then
    bad "config xray tidak valid setelah diubah, dikembalikan dari backup"
    cp -a "$BAK/$(basename "$XRAY_CFG")" "$XRAY_CFG"; RESTART_XRAY=0
  fi
fi
if [ "$RESTART_HAP" = 1 ]; then
  if ! haproxy -c -f "$HAP_CFG" >/dev/null 2>&1; then
    bad "config haproxy tidak valid setelah diubah, dikembalikan dari backup"
    cp -a "$BAK/$(basename "$HAP_CFG")" "$HAP_CFG"
    [ -e "$BAK/$(basename "$HAP_PEM")" ] && cp -a "$BAK/$(basename "$HAP_PEM")" "$HAP_PEM"
    RESTART_HAP=0
  fi
fi

[ "$RESTART_XRAY" = 1 ] && systemctl restart xray    && info "xray di-restart"
[ "$RESTART_WS" = 1 ]   && systemctl restart ws      && info "ws di-restart"
[ "$RESTART_HAP" = 1 ]  && systemctl restart haproxy && info "haproxy di-restart"

if [ "$RESTART_WS" = 1 ] || [ "$RESTART_HAP" = 1 ]; then
  info "menunggu ws/haproxy siap (7 detik)..."
  sleep 7
  info "uji ulang SSH-WebSocket:"
  if wstest; then
    ok "SSH-WebSocket sehat"
  else
    bad "SSH-WebSocket masih bermasalah, kirim output ini ke yang membantu"
  fi
fi

if [ "$AUTO" = 1 ]; then date +%s > "$STATE_DIR/last" 2>/dev/null; fi
echo
info "selesai. Jalankan lagi tanpa --fix untuk memastikan semua cek lolos:  bash $0"
exit 0
