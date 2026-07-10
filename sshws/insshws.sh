#!/bin/bash
# Proxy For Edukasi & Imclass
# ================= Local-File Mode (anti 429) =================
BASEDIR="${BASEDIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
REPO="${BASEDIR}/"

dl() {
    local src="$1" out="$2"
    if [[ "$src" == http://* || "$src" == https://* ]]; then
        curl -sS -L -A "Mozilla/5.0" -o "$out" "$src"
    else
        if [ ! -f "$src" ]; then
            echo "  ❌ File lokal gak ketemu: $src (pastikan sudah di-upload via SFTP ke $BASEDIR)"
            return 1
        fi
        cp -f "$src" "$out"
    fi
    if [ ! -s "$out" ]; then
        echo "  ❌ GAGAL nyalin $src ke $out (file kosong/gak ada)"
        return 1
    fi
}
# =================================================================

file_path="/etc/handeling"

# Cek apakah file ada
if [ ! -f "$file_path" ]; then
    echo -e "rifganss Server Connected\nBLUE" | sudo tee "$file_path" > /dev/null
    echo "File '$file_path' berhasil dibuat."
else
    if [ ! -s "$file_path" ]; then
        echo -e "rifganss Server Connected\nBlue" | sudo tee "$file_path" > /dev/null
        echo "File '$file_path' kosong dan telah diisi."
    else
        echo "File '$file_path' sudah ada dan berisi data."
    fi
fi

sudo apt install python3 -y

# ===== PORT KHUSUS - WAJIB BEDA biar gak rebutan bind =====
WS_PORT=700       # port utama sshws (dipakai HAProxy ws_backend)
WS_OVPN_PORT=2086 # port khusus openvpn-over-ws

dl "${REPO}sshws/ws" /usr/local/bin/ws
chmod +x /usr/local/bin/ws

# Installing Service (ws utama, listen di $WS_PORT)
cat > /etc/systemd/system/ws.service << END
[Unit]
Description=Proxy Mod By PX Store
Documentation=https://t.me/frel01
After=network.target nss-lookup.target

[Service]
Type=simple
User=root
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/usr/local/bin/ws ${WS_PORT}
Restart=on-failure
RestartSec=5
StartLimitIntervalSec=60
StartLimitBurst=5

[Install]
WantedBy=multi-user.target
END

systemctl daemon-reload
systemctl enable ws.service
systemctl restart ws.service

# ws-ovpn pakai binary yang sama tapi port BEDA, jadi gak bentrok sama ws.service
cp /usr/local/bin/ws /usr/local/bin/ws-ovpn
chmod +x /usr/local/bin/ws-ovpn

cat > /etc/systemd/system/ws-ovpn.service << END
[Unit]
Description=Proxy Mod By PeyxDev
Documentation=https://t.me/frel01
After=network.target nss-lookup.target

[Service]
Type=simple
User=root
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/usr/local/bin/ws-ovpn ${WS_OVPN_PORT}
Restart=on-failure
RestartSec=5
StartLimitIntervalSec=60
StartLimitBurst=5

[Install]
WantedBy=multi-user.target
END

systemctl daemon-reload
systemctl enable ws-ovpn
systemctl restart ws-ovpn

sleep 2
echo ""
echo "=== Cek status & port yang beneran kepakai ==="
systemctl is-active ws.service ws-ovpn.service
ss -tlnp | grep -E ":${WS_PORT}\b|:${WS_OVPN_PORT}\b" || echo "⚠️  Belum ada yang listen di port $WS_PORT / $WS_OVPN_PORT — cek 'journalctl -u ws -n 30' buat liat errornya (kemungkinan binary gak terima argumen port, harus cek manual)."

# ================= Auto-sync port ws ke HAProxy =================
echo ""
echo "=== Sinkronin port ws.service ke HAProxy secara otomatis ==="

REAL_WS_PORT=$(ss -tlnp 2>/dev/null | grep '"ws"' | grep -oE ':[0-9]+ ' | head -1 | tr -d ': ')

if [ -z "$REAL_WS_PORT" ]; then
    echo "⚠️  Gagal deteksi port ws yang lagi listen. HAProxy TIDAK diubah otomatis."
    echo "    Cek manual: ss -tlnp | grep ws"
else
    echo "✅ Port ws.service terdeteksi: $REAL_WS_PORT"
    if [ -f /etc/haproxy/haproxy.cfg ]; then
        cp /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg.bak-$(date +%s)
        sed -i -E "s#(server ws_server 127\.0\.0\.1:)[0-9]+( check)#\1${REAL_WS_PORT}\2#" /etc/haproxy/haproxy.cfg
        if haproxy -c -f /etc/haproxy/haproxy.cfg >/dev/null 2>&1; then
            systemctl reload haproxy 2>/dev/null || systemctl restart haproxy
            echo "✅ HAProxy diupdate otomatis: ws_backend sekarang nunjuk ke 127.0.0.1:${REAL_WS_PORT}"
        else
            echo "❌ Config HAProxy hasil edit gak valid, rollback ke backup. Cek manual."
            cp /etc/haproxy/haproxy.cfg.bak-* /etc/haproxy/haproxy.cfg 2>/dev/null
        fi
    else
        echo "⚠️  /etc/haproxy/haproxy.cfg belum ada (mungkin belum diinstall dari ins-xray.sh). Skip sync."
    fi
fi
# ===================================================================
