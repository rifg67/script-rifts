#!/bin/bash
# ==========================================================
# ANSENDANTVPN SLOWDNS SERVER  (pengganti slowdns/installsl.sh)
#
# Dipanggil otomatis oleh setup (res8) dan menu m-ftr, tanpa argumen.
# Manual:
#   bash installsl.sh [domain-ns]
#   contoh: bash installsl.sh ns-sedekah.riftsv4.my.id
#
# Urutan domain NS: argumen -> $NS -> /etc/xray/dns
#                   -> "ns-" + isi /etc/xray/domain -> tanya (kalau ada tty)
#
# Opsi lewat environment:
#   DNS_SERVER_SRC=/path/dns-server  pakai binary lokal (tanpa download)
#   DNS_SERVER_SHA256=<hash>         wajib cocok kalau diisi
#   FORCE_NEW_KEY=1                  buat key baru (PUBKEY BERUBAH!)
#   ALLOW_SHARED_KEY=1               izinkan key bersama dari REPO (TIDAK AMAN)
#   WITH_CLIENT=1                    bangun & pasang dns-client (127.0.0.1:90)
#   SSH_BACKEND=127.0.0.1:22         tujuan forward tunnel
#
# Beda dengan versi lama:
#   - TIDAK menyentuh /etc/haproxy/hap.pem dan TIDAK restart haproxy
#   - TIDAK install/restart systemd-resolved, TIDAK ubah resolver
#   - client + Go compiler jadi opsional (default mati)
#   - key lama dipertahankan; key baru dibuat per-VPS (bukan unduhan)
#   - rule INPUT ACCEPT UDP 5300 ditambahkan; NAT tidak iptables-save saat boot
#   - service jalan sebagai user "nobody", bukan root
#   - service SlowDNS lama (server/client) dinonaktifkan agar tidak bentrok;
#     nama "server"/"client" jadi alias ke service baru (menu lama tetap jalan)
#   - unduh dari GitHub dulu, bsi.web.id sebagai cadangan
# ==========================================================

set -Eeuo pipefail

# Sumber unduhan (dicoba berurutan). Isi REPO=... untuk memaksa satu sumber.
if [[ -n "${REPO:-}" ]]; then
    REPOS=("$REPO")
else
    REPOS=(
        "https://raw.githubusercontent.com/rifg67/script-rifts/main/slowdns"
        "https://bsi.web.id/os/slowdns"
    )
fi
WORK="/tmp/slowdns-install"
CONFIG_DIR="/etc/slowdns"
BACKUP_DIR="/root/slowdns-backup-$(date +%Y%m%d-%H%M%S)"

SERVER_PORT="5300"
SSH_BACKEND="${SSH_BACKEND:-127.0.0.1:22}"
SVC_USER="nobody"
SVC_GROUP="nogroup"

WITH_CLIENT="${WITH_CLIENT:-0}"
FORCE_NEW_KEY="${FORCE_NEW_KEY:-0}"
ALLOW_SHARED_KEY="${ALLOW_SHARED_KEY:-0}"
DNS_SERVER_SRC="${DNS_SERVER_SRC:-}"
DNS_SERVER_SHA256="${DNS_SERVER_SHA256:-}"

# Hanya dipakai kalau WITH_CLIENT=1
DNS_UPSTREAM="8.8.8.8:53"
CLIENT_LOCAL="127.0.0.1:90"
GO_VERSION="1.27.3"
GO_ROOT="/opt/slowdns-go"
GO_DIR="$GO_ROOT/go"
GO_BIN="$GO_DIR/bin/go"
DNSTT_VERSION="v1.20260501.0"

# ----------------------------------------------------------
# HELPER
# ----------------------------------------------------------

warn() { echo "PERINGATAN: $*" >&2; }
die()  { echo "ERROR: $*" >&2; exit 1; }

cleanup() { rm -rf "$WORK"; }
trap cleanup EXIT
trap 'echo "ERROR: Instalasi gagal pada baris $LINENO" >&2' ERR

is_elf() {
    [[ "$(head -c4 "$1" 2>/dev/null | od -An -tx1 | tr -d ' \n')" == "7f454c46" ]]
}

# fetch_any NAMA TUJUAN [elf] : coba tiap sumber di REPOS sampai berhasil
fetch_any() {
    local name="$1" out="$2" need_elf="${3:-}" base
    for base in "${REPOS[@]}"; do
        rm -f "$out"
        if wget -q --tries=2 --timeout=30 -O "$out" "$base/$name" 2>/dev/null && [[ -s "$out" ]]; then
            if [[ -z "$need_elf" ]] || is_elf "$out"; then
                echo "$name diunduh dari: $base"
                return 0
            fi
        fi
    done
    rm -f "$out"
    return 1
}

valid_key() {
    tr -d '[:space:]' < "$1" | grep -Eq '^[0-9a-fA-F]{64}$'
}

# ----------------------------------------------------------
# PREFLIGHT
# ----------------------------------------------------------

[[ $EUID -eq 0 ]] || die "Jalankan sebagai root!"
[[ -f /etc/os-release ]] || die "OS tidak dikenali!"

# shellcheck disable=SC1091
source /etc/os-release
case "${ID:-}" in
    ubuntu|debian) ;;
    *) die "OS tidak didukung: ${ID:-unknown}" ;;
esac

getent group "$SVC_GROUP" >/dev/null 2>&1 || SVC_GROUP="$(id -gn "$SVC_USER")"

# ----------------------------------------------------------
# DOMAIN NS
# ----------------------------------------------------------

NS="${1:-${NS:-}}"

if [[ -z "$NS" && -s /etc/xray/dns ]]; then
    NS="$(tr -d '[:space:]' < /etc/xray/dns)"
    echo "Domain diambil dari /etc/xray/dns: $NS"
fi

if [[ -z "$NS" && -s /etc/xray/domain ]]; then
    NS="ns-$(tr -d '[:space:]' < /etc/xray/domain)"
    echo "Domain NS dibentuk dari /etc/xray/domain: $NS"
fi

if [[ -z "$NS" ]]; then
    [[ -t 0 ]] || die "Domain NS belum diberikan. Pakai: bash installsl.sh ns-xxx.domain.id"
    read -rp "Masukkan domain SlowDNS (contoh: ns-sedekah.domain.id): " NS
fi

NS="${NS,,}"

if [[ ! "$NS" =~ ^([a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z]{2,63}$ ]]; then
    die "Format domain tidak valid: $NS"
fi

echo
echo "=========================================="
echo " ANSENDANTVPN SLOWDNS INSTALLER"
echo "=========================================="
echo "OS      : ${PRETTY_NAME:-$ID}"
echo "Domain  : $NS"
echo "Backend : $SSH_BACKEND"
echo "Backup  : $BACKUP_DIR"
echo

# ----------------------------------------------------------
# [1/8] DEPENDENCIES (hanya kalau ada yang kurang)
# ----------------------------------------------------------

echo "[1/8] Cek dependencies"

missing=()
for c in wget iptables ss dig runuser sha256sum od; do
    command -v "$c" >/dev/null 2>&1 || missing+=("$c")
done
if [[ "$WITH_CLIENT" == "1" ]]; then
    for c in tar gzip; do
        command -v "$c" >/dev/null 2>&1 || missing+=("$c")
    done
fi

if (( ${#missing[@]} )); then
    echo "Kurang: ${missing[*]} -> install"
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -y
    apt-get install -y wget ca-certificates iptables iproute2 dnsutils \
        coreutils util-linux tar gzip
else
    echo "Semua dependency sudah ada."
fi

# ----------------------------------------------------------
# [2/8] BACKUP + MATIKAN SLOWDNS LAMA
# ----------------------------------------------------------

echo "[2/8] Backup dan matikan service SlowDNS lama"

mkdir -p "$BACKUP_DIR"
if [[ -d "$CONFIG_DIR" ]]; then cp -a "$CONFIG_DIR" "$BACKUP_DIR/slowdns-etc"; fi
if [[ -f /usr/sbin/dns-server ]]; then cp -a /usr/sbin/dns-server "$BACKUP_DIR/"; fi
iptables-save > "$BACKUP_DIR/iptables.rules" 2>/dev/null || true

systemctl stop slowdns-server 2>/dev/null || true

# Service lama (server/client) memakai UDP 5300 juga. Unit-nya dibackup lalu
# dihapus supaya nama "server" bisa jadi alias ke slowdns-server; dengan begitu
# menu lama (reset: systemctl restart server) tetap bekerja walau menu di-update.
for u in server client; do
    if systemctl cat "$u.service" 2>/dev/null | grep -qi 'slowdns'; then
        echo "Menonaktifkan service lama: $u"
        systemctl disable --now "$u" 2>/dev/null || true
        if [[ -f "/etc/systemd/system/$u.service" ]]; then
            cp -a "/etc/systemd/system/$u.service" "$BACKUP_DIR/$u.service"
            rm -f "/etc/systemd/system/$u.service"
        fi
    fi
done
systemctl daemon-reload 2>/dev/null || true

if [[ -n "$(ss -H -lunp "sport = :$SERVER_PORT" 2>/dev/null)" ]]; then
    ss -H -lunp "sport = :$SERVER_PORT" >&2 || true
    die "UDP $SERVER_PORT masih dipakai proses lain (lihat di atas)."
fi

# ----------------------------------------------------------
# [3/8] BINARY SERVER
# ----------------------------------------------------------

echo "[3/8] Siapkan binary dns-server"

rm -rf "$WORK"
mkdir -p "$WORK"
chown "$SVC_USER:$SVC_GROUP" "$WORK"
chmod 700 "$WORK"

if [[ -n "$DNS_SERVER_SRC" ]]; then
    [[ -s "$DNS_SERVER_SRC" ]] || die "DNS_SERVER_SRC tidak ada/kosong: $DNS_SERVER_SRC"
    cp "$DNS_SERVER_SRC" "$WORK/dns-server"
else
    fetch_any dns-server "$WORK/dns-server" elf \
        || die "Gagal download dns-server dari: ${REPOS[*]}"
fi

[[ -s "$WORK/dns-server" ]] || die "File dns-server kosong."
is_elf "$WORK/dns-server" || die "dns-server bukan binary ELF (mungkin halaman error)."
chmod 755 "$WORK/dns-server"

DNS_SHA="$(sha256sum "$WORK/dns-server" | awk '{print $1}')"
echo "SHA256 dns-server : $DNS_SHA"

if [[ -n "$DNS_SERVER_SHA256" ]]; then
    [[ "${DNS_SERVER_SHA256,,}" == "$DNS_SHA" ]] || die "SHA256 dns-server tidak cocok!"
    echo "SHA256 cocok dengan yang dipin."
else
    warn "DNS_SERVER_SHA256 belum diisi. Pin hash di atas supaya binary yang berubah di server tidak ikut terpasang."
fi

# Tes bisa dieksekusi (sebagai user biasa, bukan root)
rc=0
runuser -u "$SVC_USER" -- "$WORK/dns-server" -h >/dev/null 2>&1 || rc=$?
if [[ $rc -eq 126 || $rc -eq 127 ]]; then
    die "dns-server tidak bisa dijalankan (arsitektur salah?)."
fi

# ----------------------------------------------------------
# [4/8] KEY
# ----------------------------------------------------------

echo "[4/8] Siapkan key"

if [[ "$FORCE_NEW_KEY" != "1" && -s "$CONFIG_DIR/server.key" && -s "$CONFIG_DIR/server.pub" ]]; then
    cp "$CONFIG_DIR/server.key" "$WORK/server.key"
    cp "$CONFIG_DIR/server.pub" "$WORK/server.pub"
    KEY_MODE="lama (dipertahankan, pubkey tidak berubah)"
elif runuser -u "$SVC_USER" -- "$WORK/dns-server" -gen-key \
        -privkey-file "$WORK/server.key" -pubkey-file "$WORK/server.pub" >/dev/null 2>&1 \
     && [[ -s "$WORK/server.key" && -s "$WORK/server.pub" ]]; then
    KEY_MODE="baru (dibuat di VPS ini, pubkey BERUBAH)"
else
    [[ "$ALLOW_SHARED_KEY" == "1" ]] || die "Binary tidak bisa membuat key (-gen-key). Key bersama dari URL publik tidak aman; isi ALLOW_SHARED_KEY=1 hanya kalau Anda paham risikonya."
    warn "Memakai key BERSAMA dari URL publik. Siapa pun yang bisa membuka URL itu punya private key Anda."
    fetch_any serverkey.sh "$WORK/server.key" || die "Gagal download server.key"
    fetch_any serverpub.sh "$WORK/server.pub" || die "Gagal download server.pub"
    KEY_MODE="BERSAMA dari REPO (tidak aman)"
fi

valid_key "$WORK/server.key" || die "Format server.key tidak valid (harus 64 karakter hex)."
valid_key "$WORK/server.pub" || die "Format server.pub tidak valid (harus 64 karakter hex)."

mkdir -p "$CONFIG_DIR"
chmod 755 "$CONFIG_DIR"
install -m 755 "$WORK/dns-server" /usr/sbin/dns-server
install -m 640 -o root -g "$SVC_GROUP" "$WORK/server.key" "$CONFIG_DIR/server.key"
install -m 644 "$WORK/server.pub" "$CONFIG_DIR/server.pub"

echo "Key : $KEY_MODE"

# ----------------------------------------------------------
# [5/8] CLIENT (opsional)
# ----------------------------------------------------------

install_client() {
    local arch go_arch go_sha
    arch="$(dpkg --print-architecture)"
    case "$arch" in
        amd64) go_arch="amd64"; go_sha="65efbc80fdc1fa2cd2631cad5b481777a68e8725f34e89f50fc6ac714e379b40" ;;
        arm64) go_arch="arm64"; go_sha="a06e99309dbcbdca1a8ccd2282c3ee146e55930886e26b4f1193269587165f49" ;;
        *) die "Arsitektur belum didukung untuk client: $arch" ;;
    esac

    mkdir -p "$GO_ROOT"
    if [[ ! -x "$GO_BIN" ]] || ! "$GO_BIN" version 2>/dev/null | grep -q "go$GO_VERSION"; then
        wget -q --tries=3 --timeout=60 -O /tmp/slowdns-go.tar.gz \
            "https://go.dev/dl/go${GO_VERSION}.linux-${go_arch}.tar.gz"
        echo "$go_sha  /tmp/slowdns-go.tar.gz" | sha256sum -c -
        rm -rf "$GO_DIR"
        tar -C "$GO_ROOT" -xzf /tmp/slowdns-go.tar.gz
        rm -f /tmp/slowdns-go.tar.gz
    fi

    mkdir -p "$WORK/bin"
    GOTOOLCHAIN=local GOROOT="$GO_DIR" GOPATH="$WORK/gopath" GOBIN="$WORK/bin" \
    CGO_ENABLED=0 GOOS=linux GOARCH="$go_arch" \
        "$GO_BIN" install -trimpath -ldflags="-s -w" \
        "www.bamsoftware.com/git/dnstt.git/dnstt-client@$DNSTT_VERSION"

    is_elf "$WORK/bin/dnstt-client" || die "Build dns-client gagal (bukan ELF)."
    install -m 755 "$WORK/bin/dnstt-client" /usr/sbin/dns-client

    cat > /etc/systemd/system/slowdns-client.service <<EOF
[Unit]
Description=AnsendantVPN SlowDNS Client (opsional)
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=$SVC_USER
Group=$SVC_GROUP
Restart=on-failure
RestartSec=3
ExecStart=/usr/sbin/dns-client -udp $DNS_UPSTREAM -pubkey-file $CONFIG_DIR/server.pub $NS $CLIENT_LOCAL
NoNewPrivileges=true
PrivateTmp=true

[Install]
WantedBy=multi-user.target
Alias=client.service
EOF
}

echo "[5/8] Client SlowDNS"
if [[ "$WITH_CLIENT" == "1" ]]; then
    install_client
    echo "dns-client terpasang (listen $CLIENT_LOCAL)"
else
    echo "Dilewati (server tidak butuh client). Pakai WITH_CLIENT=1 kalau perlu."
fi

# ----------------------------------------------------------
# [6/8] CONFIG + SERVICE SERVER
# ----------------------------------------------------------

echo "[6/8] Buat service server"

cat > "$CONFIG_DIR/envslowdns" <<EOF
NAMESERVER="$NS"
CONFIG_PRIV="$CONFIG_DIR/server.key"
CONFIG_PUB="$CONFIG_DIR/server.pub"
SERVICE_SERVER="$SSH_BACKEND"
LISTEN_SERVER=":$SERVER_PORT"
EOF
chmod 600 "$CONFIG_DIR/envslowdns"

cat > /etc/systemd/system/slowdns-server.service <<EOF
[Unit]
Description=AnsendantVPN SlowDNS Server
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=$SVC_USER
Group=$SVC_GROUP
EnvironmentFile=$CONFIG_DIR/envslowdns
Restart=on-failure
RestartSec=3
LimitNOFILE=65535
NoNewPrivileges=true
PrivateTmp=true
ProtectHome=true
ExecStart=/usr/sbin/dns-server -udp \${LISTEN_SERVER} -privkey-file \${CONFIG_PRIV} \${NAMESERVER} \${SERVICE_SERVER}

[Install]
WantedBy=multi-user.target
Alias=server.service
EOF

# ----------------------------------------------------------
# [7/8] FIREWALL / NAT
# ----------------------------------------------------------

echo "[7/8] Firewall: UDP 53 -> $SERVER_PORT"

cat > /usr/local/sbin/slowdns-nat.sh <<'EOF'
#!/bin/bash
# Idempotent. Sengaja TIDAK iptables-save (jangan menimpa rules.v4 saat boot).
set -Eeuo pipefail

PORT="__PORT__"

IFACE="$(
    ip -o route get 1.1.1.1 2>/dev/null |
    awk '{for(i=1;i<=NF;i++) if($i=="dev"){print $(i+1); exit}}'
)"

if [[ -z "$IFACE" ]]; then
    echo "Network interface tidak ditemukan!" >&2
    exit 1
fi

iptables -t nat -C PREROUTING -i "$IFACE" -p udp --dport 53 \
    -j REDIRECT --to-ports "$PORT" 2>/dev/null \
  || iptables -t nat -A PREROUTING -i "$IFACE" -p udp --dport 53 \
    -j REDIRECT --to-ports "$PORT"

iptables -C INPUT -p udp --dport "$PORT" -j ACCEPT 2>/dev/null \
  || iptables -I INPUT -p udp --dport "$PORT" -j ACCEPT

echo "NAT $IFACE: UDP 53 -> $PORT, INPUT UDP $PORT diizinkan"
EOF
sed -i "s/__PORT__/$SERVER_PORT/" /usr/local/sbin/slowdns-nat.sh
chmod 755 /usr/local/sbin/slowdns-nat.sh

cat > /etc/systemd/system/slowdns-nat.service <<'EOF'
[Unit]
Description=SlowDNS UDP 53 redirect + allow INPUT
After=network-online.target netfilter-persistent.service
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/slowdns-nat.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

if command -v ufw >/dev/null 2>&1 && ufw status 2>/dev/null | grep -q '^Status: active'; then
    ufw allow "$SERVER_PORT/udp" >/dev/null 2>&1 || true
    warn "ufw aktif. Redirect 53->$SERVER_PORT lewat iptables bisa terhapus saat 'ufw reload'."
fi

if [[ -d /etc/xray ]]; then
    echo "$NS" > /etc/xray/dns
fi

# ----------------------------------------------------------
# [8/8] START + VALIDASI
# ----------------------------------------------------------

echo "[8/8] Jalankan service"

systemctl daemon-reload
systemctl enable --now slowdns-nat.service
systemctl enable slowdns-server.service
systemctl restart slowdns-server.service
if [[ "$WITH_CLIENT" == "1" ]]; then
    systemctl enable slowdns-client.service
    systemctl restart slowdns-client.service || true
fi

if command -v netfilter-persistent >/dev/null 2>&1; then
    netfilter-persistent save >/dev/null 2>&1 || true
fi

sleep 2

if ! systemctl is-active --quiet slowdns-server.service; then
    journalctl -u slowdns-server -n 20 --no-pager >&2 || true
    die "slowdns-server tidak jalan. Lihat log di atas. Rollback: lihat $BACKUP_DIR"
fi

# Tes dari dalam: nama query bentuk dnstt, tipe TXT vs NULL
Q="w4bsv7ubpwob52ckbsiuyt3iyx6a.$NS"

qstatus() {
    dig +time=3 +tries=1 +noall +comments @127.0.0.1 -p "$SERVER_PORT" "$1" "$Q" 2>/dev/null \
        | grep -o 'status: [A-Z]*' | head -1 | awk '{print $2}'
}

TXT_ST="$(qstatus TXT || true)"
NULL_ST="$(qstatus NULL || true)"

echo
echo "=========================================="
echo " SLOWDNS TERPASANG"
echo "=========================================="
echo "Domain NS   : $NS"
echo "Key         : $KEY_MODE"
echo "Backend     : $SSH_BACKEND"
echo "Service     : $(systemctl is-active slowdns-server.service)"
ss -H -lunp "sport = :$SERVER_PORT" 2>/dev/null || true
echo
echo "Tes lokal   : TXT=${TXT_ST:-timeout}  NULL=${NULL_ST:-timeout}"

if [[ "$NULL_ST" == "NOERROR" ]]; then
    echo "-> Server menjawab NULL: cocok untuk HTTP Custom."
elif [[ "$TXT_ST" == "NOERROR" ]]; then
    echo "-> Server HANYA menjawab TXT: cocok untuk klien DNSTT standar,"
    echo "   tapi TIDAK untuk HTTP Custom yang mengirim query NULL."
else
    echo "-> Server tidak menjawab tes lokal. Cek: journalctl -u slowdns-server -n 30"
fi

echo
echo "Public key (isi di aplikasi):"
cat "$CONFIG_DIR/server.pub"
echo
echo "Pastikan di DNS: NS record $NS -> domain A record VPS (DNS only)."
echo "Backup      : $BACKUP_DIR"
echo "Rollback    : systemctl disable --now slowdns-server slowdns-nat"
echo "              cp $BACKUP_DIR/server.service /etc/systemd/system/ ; systemctl daemon-reload"
echo "              systemctl enable --now server   (service lama)"
echo "=========================================="
