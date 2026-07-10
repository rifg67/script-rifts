#!/bin/bash
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

dl "${REPO}install/limit-ip" /usr/bin/limit-ip
chmod +x /usr/bin/*
cd /usr/bin
sed -i 's/\r//' limit-ip
cd
systemctl daemon-reload
dl "${REPO}install/limitvmess.service" /etc/systemd/system/limitvmess.service
dl "${REPO}install/limitvless.service" /etc/systemd/system/limitvless.service
dl "${REPO}install/limittrojan.service" /etc/systemd/system/limittrojan.service
dl "${REPO}install/limitshadowsocks.service" /etc/systemd/system/limitshadowsocks.service
dl "${REPO}install/vmess" /etc/xray/limit.vmess
dl "${REPO}install/vless" /etc/xray/limit.vless
dl "${REPO}install/trojan" /etc/xray/limit.trojan
dl "${REPO}install/shadowsocks" /etc/xray/limit.shadowsocks
chmod +x /etc/systemd/system/limitvmess.service /etc/systemd/system/limitvless.service /etc/systemd/system/limittrojan.service /etc/systemd/system/limitshadowsocks.service
chmod +x /etc/xray/limit.vmess
chmod +x /etc/xray/limit.vless
chmod +x /etc/xray/limit.trojan
chmod +x /etc/xray/limit.shadowsocks
systemctl daemon-reload
systemctl enable --now limitvmess
systemctl enable --now limitvless
systemctl enable --now limittrojan
systemctl enable --now limitshadowsocks
systemctl start limitvmess
systemctl start limitvless
systemctl start limittrojan
systemctl start limitshadowsocks
