#!/bin/bash
# install.sh - pemasang script-rifts tanpa ribet:
#   tanpa dialog/enter tambahan, IPv4 saja (IPv6 dimatikan), jalan di latar belakang.
#
# Pakai:
#   ./install.sh                 layar setup bawaan menanyakan nama + domain seperti biasa.
#                                Sesudah diisi, terminal BOLEH ditutup, instalasi jalan sendiri.
#   ./install.sh status | log | attach | stop   cek status / lihat log / buka lagi layar / hentikan instalasi
# Opsi: -r reboot otomatis setelah selesai | -f jalan di depan (tanpa screen) | --dry-run
#       -n NAMA -d DOMAIN | -n NAMA -s SUBDOMAIN   (opsional: isi nama/domain lewat perintah)

WORKDIR=${WORKDIR:-/root}
SETUP=${SETUP:-./setup.sh}
LOG=${LOG:-/root/install-rifts.log}
STATUS=${STATUS:-/root/install-rifts.status}
RUNNER=${RUNNER:-/root/.rifts-run.sh}
APTCONF=${APTCONF:-/etc/apt/apt.conf.d/99rifts-noninteractive}
SYSCTLF=${SYSCTLF:-/etc/sysctl.d/99-disable-ipv6.conf}
GAICONF=${GAICONF:-/etc/gai.conf}
MENUBIN=${MENUBIN:-/usr/local/sbin/menu}
SESSION=rifts
SCREENRC=${SCREENRC:-/root/.rifts-screenrc}
export LANG=C.UTF-8 LC_ALL=C.UTF-8
RE='^[a-zA-Z0-9_.-]+$'

die() { echo "X  $*" >&2; exit 1; }

cmd_status() {
  echo "Status : $(cat "$STATUS" 2>/dev/null || echo 'belum pernah dijalankan')"
  screen -ls 2>/dev/null | grep -q "\.$SESSION" && echo "Sesi   : screen '$SESSION' masih berjalan (./install.sh attach)"
  if [ -f "$LOG" ]; then
    echo "--- 15 baris terakhir ($LOG):"
    tail -n 15 "$LOG" | sed -E 's/\x1b\[[0-9;?]*[A-Za-z]//g' | tr -d '\r'
  fi
}

case "${1:-}" in
  status) cmd_status; exit 0 ;;
  log)    exec tail -n 40 -f "$LOG" ;;
  attach) exec screen -U -r "$SESSION" ;;
  stop)
    screen -S "$SESSION" -X quit 2>/dev/null
    for p in "$RUNNER" /root/setup.sh ssh-vpn.sh ins-xray.sh insshws.sh set-br.sh ohp.sh installsl.sh udp-custom.sh tools.sh pointing.sh; do pkill -f "(^|[ /])${p}( |\$)" 2>/dev/null; done
    rm -f "$HOME/fim" 2>/dev/null
    echo "SELESAI DIHENTIKAN $(date '+%F %T')" > "$STATUS"
    echo "Instalasi dihentikan. Kalau apt/dpkg sempat kepotong, jalankan: dpkg --configure -a"
    exit 0 ;;
esac

if screen -ls 2>/dev/null | grep -q "\.$SESSION"; then
  die "Instalasi sudah berjalan (screen '$SESSION'). Cek: ./install.sh status | attach | stop"
fi

NAMA=""; DOMAIN_CUSTOM=""; SUBDOMAIN=""; REBOOT=0; FG=0; DRY=0
while [ $# -gt 0 ]; do
  case "$1" in
    -n|--name)      [ $# -ge 2 ] || die "$1 butuh nilai"; NAMA="$2"; shift 2 ;;
    -d|--domain)    [ $# -ge 2 ] || die "$1 butuh nilai"; DOMAIN_CUSTOM="$2"; shift 2 ;;
    -s|--subdomain) [ $# -ge 2 ] || die "$1 butuh nilai"; SUBDOMAIN="$2"; shift 2 ;;
    -r|--reboot)    REBOOT=1; shift ;;
    -f|--fg)        FG=1; shift ;;
    --dry-run)      DRY=1; shift ;;
    -h|--help)      awk 'NR>1 && /^#/ {print; next} NR>1 {exit}' "$0"; exit 0 ;;
    *) die "Opsi tidak dikenal: $1 (lihat ./install.sh --help)" ;;
  esac
done

[ "$(id -u)" -eq 0 ] || die "Jalankan sebagai root."
OSID=$(. /etc/os-release 2>/dev/null; echo "${ID:-}")
case "$OSID" in ubuntu|debian) ;; *) die "OS tidak didukung (${OSID:-?}). Pakai Ubuntu atau Debian." ;; esac
SETUP=$(readlink -f "$SETUP" 2>/dev/null)
[ -f "$SETUP" ] || die "setup.sh tidak ditemukan di folder ini."

# AUTO=1: nama/domain dari argumen (tanpa tanya). AUTO=0: layar setup bawaan yang bertanya.
if [ -n "$NAMA$DOMAIN_CUSTOM$SUBDOMAIN" ]; then
  AUTO=1
  { [ -n "$NAMA" ] && { [ -n "$DOMAIN_CUSTOM" ] || [ -n "$SUBDOMAIN" ]; }; } \
    || die "Isi lengkap: -n NAMA dan -d DOMAIN (atau -s SUBDOMAIN), atau kosongkan semuanya."
  [[ "$NAMA" =~ $RE ]] || die "Nama tidak valid (huruf/angka/_ . - saja, tanpa spasi)."
  if [ -n "$DOMAIN_CUSTOM" ] && [ -n "$SUBDOMAIN" ]; then die "Pilih salah satu: -d (domain sendiri) atau -s (subdomain random)."; fi
  if [ -n "$DOMAIN_CUSTOM" ]; then
    [[ "$DOMAIN_CUSTOM" =~ $RE ]] || die "Domain tidak valid."
    MODE=1; VARNAME=dnss; VARVAL=$DOMAIN_CUSTOM
  else
    [[ "$SUBDOMAIN" =~ $RE ]] || die "Subdomain tidak valid."
    MODE=2; VARNAME=dn1; VARVAL=$SUBDOMAIN
  fi
else
  AUTO=0
  [ "$DRY" = 1 ] || [ -t 0 ] || die "Jalankan dari terminal (SSH), atau pakai: ./install.sh -n NAMA -d DOMAIN"
  if [ "$REBOOT" = 0 ] && [ -t 0 ]; then
    read -rp "Reboot otomatis setelah instalasi selesai? (y/N): " R; [[ "$R" =~ ^[Yy]$ ]] && REBOOT=1
  fi
fi

if screen -ls 2>/dev/null | grep -q "\.$SESSION"; then
  die "Instalasi sudah berjalan (screen '$SESSION'). Cek: ./install.sh status"
fi

# ---------- siapkan sistem: non-interaktif + IPv4 ----------
mkdir -p "$(dirname "$APTCONF")" "$(dirname "$SYSCTLF")"
printf '%s\n' 'Dpkg::Options { "--force-confdef"; "--force-confold"; };' \
  'APT::Get::Assume-Yes "true";' 'Acquire::ForceIPv4 "true";' 'DPkg::Lock::Timeout "300";' > "$APTCONF"
if [ -d /etc/needrestart ] || [ -n "${NEEDRESTART_DIR:-}" ]; then
  d=${NEEDRESTART_DIR:-/etc/needrestart/conf.d}; mkdir -p "$d"
  echo "\$nrconf{restart} = 'a';" > "$d/99-rifts.conf"
fi
if command -v debconf-set-selections >/dev/null 2>&1 && [ "$DRY" = 0 ]; then
  printf '%s\n' \
    'debconf debconf/frontend select Noninteractive' \
    'debconf debconf/priority select critical' \
    'keyboard-configuration keyboard-configuration/layout select English (US)' \
    'keyboard-configuration keyboard-configuration/variant select English (US)' \
    'keyboard-configuration keyboard-configuration/xkb-keymap select us' \
    'keyboard-configuration keyboard-configuration/layoutcode string us' \
    'keyboard-configuration keyboard-configuration/modelcode string pc105' \
    'console-setup console-setup/charmap47 select UTF-8' \
    'console-setup console-setup/codeset47 select Guess optimal character set' \
    | debconf-set-selections 2>/dev/null
fi
printf '%s\n' 'net.ipv6.conf.all.disable_ipv6 = 1' 'net.ipv6.conf.default.disable_ipv6 = 1' \
  'net.ipv6.conf.lo.disable_ipv6 = 1' > "$SYSCTLF"
[ "$DRY" = 0 ] && sysctl -q -p "$SYSCTLF" >/dev/null 2>&1
grep -qs '^precedence ::ffff:0:0/96' "$GAICONF" || echo 'precedence ::ffff:0:0/96  100' >> "$GAICONF"
grep -qs 'inet4_only' "$HOME/.wgetrc" || echo 'inet4_only = on' >> "$HOME/.wgetrc"
grep -qsx 'ipv4' "$HOME/.curlrc" || echo 'ipv4' >> "$HOME/.curlrc"

# ---------- skrip yang dijalankan di dalam screen ----------
if [ "$AUTO" = 1 ]; then
  ENVLINE="export name='$NAMA' domain='$MODE' $VARNAME='$VARVAL'"
  RUNLINE='bash "'"$SETUP"'" < /dev/null 2>&1 | tee -a "'"$LOG"'"; rc=${PIPESTATUS[0]}'
else
  ENVLINE=":"
  # script(1) memberi terminal sungguhan: layar tanya nama/domain tampil persis seperti biasa, dan semuanya tercatat di log
  RUNLINE='if command -v script >/dev/null 2>&1; then script -qefc "bash '"'$SETUP'"'" "'"$LOG"'"; rc=$?; else bash "'"$SETUP"'"; rc=$?; fi'
fi
cat > "$RUNNER" <<EOF_RUN
#!/bin/bash
export LANG=C.UTF-8 LC_ALL=C.UTF-8 DEBIAN_FRONTEND=noninteractive NEEDRESTART_MODE=a NEEDRESTART_SUSPEND=1 APT_LISTCHANGES_FRONTEND=none UCF_FORCE_CONFFOLD=1 SLOWDNS_NO_PAUSE=1 RIFTS_ANSWER=n
export TERM="\${TERM:-xterm}"
$ENVLINE
cd "$WORKDIR" || exit 1
echo "berjalan sejak \$(date '+%F %T')" > "$STATUS"
for i in \$(seq 1 60); do pgrep -x 'apt|apt-get|dpkg' >/dev/null || break; sleep 5; done
$RUNLINE
if [ "\$rc" -eq 0 ] && [ -x "$MENUBIN" ]; then
  echo "SELESAI \$(date '+%F %T') - ketik: menu" > "$STATUS"
else
  echo "SELESAI DENGAN MASALAH (kode \$rc, menu belum terpasang?) - cek $LOG" > "$STATUS"
fi
tee -a "$LOG" < "$STATUS"
if [ "$REBOOT" = 1 ]; then echo "Reboot 10 detik lagi..." | tee -a "$LOG"; sleep 10; reboot; fi
EOF_RUN
printf '%s\n' 'defutf8 on' 'defencoding utf8' 'startup_message off' 'defscrollback 5000' > "$SCREENRC"
chmod +x "$RUNNER"; : > "$LOG"; echo "mulai..." > "$STATUS"

if [ "$DRY" = 1 ]; then echo "[dry-run] runner dibuat di $RUNNER, tidak dijalankan."; exit 0; fi

command -v screen >/dev/null 2>&1 || apt-get install -y screen >/dev/null 2>&1

if [ "$AUTO" = 1 ]; then
  echo "Instalasi dimulai | nama: $NAMA | $([ $MODE = 1 ] && echo "domain: $VARVAL" || echo "subdomain random: $VARVAL") | reboot otomatis: $([ $REBOOT = 1 ] && echo ya || echo tidak)"
  if [ "$FG" = 1 ]; then exec bash "$RUNNER"; fi
  if command -v screen >/dev/null 2>&1; then screen -U -c "$SCREENRC" -dmS "$SESSION" bash "$RUNNER"; else nohup setsid bash "$RUNNER" > /dev/null 2>&1 & fi
  echo
  echo "Terminal BOLEH ditutup sekarang. Instalasi jalan sendiri."
  echo "  Cek progres : ./install.sh status      (atau: tail -f $LOG)"
  echo "  Lihat layar : ./install.sh attach      (keluar tanpa menghentikan: Ctrl+A lalu D)"
  echo "  Selesai     : ketik 'menu'$([ $REBOOT = 1 ] && echo " (VPS reboot otomatis)")"
else
  echo
  echo "Layar berikutnya = setup bawaan. Isi NAMA dan DOMAIN seperti biasa."
  echo "Setelah itu terminal BOLEH ditutup, instalasi jalan sendiri di latar belakang."
  echo "(Cek lagi nanti: ./install.sh status | attach)  | reboot otomatis: $([ $REBOOT = 1 ] && echo ya || echo tidak)"
  sleep 3
  if [ "$FG" = 1 ] || ! command -v screen >/dev/null 2>&1; then exec bash "$RUNNER"; fi
  exec screen -U -c "$SCREENRC" -S "$SESSION" bash "$RUNNER"
fi
