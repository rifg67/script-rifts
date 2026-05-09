#!/bin/bash
echo "✨ XRAY ULTIMATE INSTALLER - PEYX TUNNEL"
# ==========================================
# Color
RED='\033[0;31m'
NC='\033[0m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
LIGHT='\033[0;37m'
# ==========================================

REPO="https://raw.githubusercontent.com/rifg67/script-rifts/main/"
echo -e ""
date
echo ""

cd
# ✅ PERBAIKI: Logic condition domain
if [[ -e /etc/xray/domain ]]; then
    domain=$(cat /etc/xray/domain)
else
    echo -e "[ ${RED}ERROR${NC} ] Domain file not found!"
    exit 1
fi

sleep 0.1
echo -e "[ ${GREEN}INFO${NC} ] Checking... "
apt install iptables iptables-persistent -y
sleep 0.1

# ✅ PERBAIKAN: INSTALL DAHULU SEBELUM MENJALANKAN
echo -e "[ ${GREEN}INFO${NC} ] Install time synchronization tools"
apt install chrony ntpdate -y

echo -e "[ ${GREEN}INFO${NC} ] Setting ntpdate"
ntpdate pool.ntp.org
timedatectl set-ntp true

echo -e "[ ${GREEN}INFO${NC} ] Enable chrony"
systemctl enable chrony
systemctl restart chrony
timedatectl set-timezone Asia/Jakarta

sleep 0.1
echo -e "[ ${GREEN}INFO${NC} ] Setting chrony tracking"
chronyc sourcestats -v
chronyc tracking -v

echo -e "[ ${GREEN}INFO${NC} ] Setting dll"
apt clean all && apt update
apt install curl socat xz-utils wget apt-transport-https gnupg gnupg2 gnupg1 dnsutils lsb-release -y
apt install socat cron bash-completion -y
ntpdate pool.ntp.org
apt install zip -y
apt install curl pwgen openssl cron net-tools jq -y

# install xray
sleep 0.1
echo -e "[ ${GREEN}INFO${NC} ] Downloading & Installing xray core"
domainSock_dir="/run/xray";! [ -d $domainSock_dir ] && mkdir  $domainSock_dir
chown www-data.www-data $domainSock_dir

# Make Folder XRay - SESUAIKAN DENGAN PATH YANG DI PASTE
mkdir -p /var/log/xray
mkdir -p /usr/local/etc/xray
mkdir -p /etc/xray
mkdir -p /etc/peyx/{vmess,vless,trojan,log,limit/{vmess,vless,trojan}/ip}
chown www-data.www-data /var/log/xray
chmod +x /var/log/xray
touch /var/log/xray/access.log
touch /var/log/xray/error.log

# / / Ambil Xray Core Version Terbaru
latest_version="24.11.30"
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install -u www-data --version $latest_version

## MEMBUAT SSL CERTIFICATE (SELF-SIGNED)
echo -e "[ ${GREEN}INFO${NC} ] Creating SSL Certificate..."
systemctl stop nginx
systemctl stop haproxy 2>/dev/null

# Backup jika ada
[ -f /etc/xray/xray.key ] && cp /etc/xray/xray.key /etc/xray/xray.key.bak
[ -f /etc/xray/xray.crt ] && cp /etc/xray/xray.crt /etc/xray/xray.crt.bak

# Buat self-signed certificate
openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 \
    -subj "/C=ID/ST=Jawa Barat/L=Sukabumi/O=PEYX TUNNEL/CN=$domain" \
    -keyout /etc/xray/xray.key \
    -out /etc/xray/xray.crt 2>/dev/null

chmod 644 /etc/xray/xray.{crt,key}
echo -e "[ ${GREEN}INFO${NC} ] SSL Certificate selesai"

mkdir -p /home/vps/public_html

# set uuid
uuid=$(cat /proc/sys/kernel/random/uuid)

# Buat file database default - SESUAIKAN DENGAN PATH YANG DI PASTE
echo "### vmess1 $(date -d '30 days' +%Y-%m-%d) $uuid 10 2" > /etc/peyx/vmess.db
echo "### vless1 $(date -d '30 days' +%Y-%m-%d) $uuid 10 2" > /etc/peyx/vless.db
echo "### trojan1 $(date -d '30 days' +%Y-%m-%d) $uuid 10 2" > /etc/peyx/trojan.db

# Buat limit IP default
echo "2" > /etc/peyx/limit/vmess/ip/vmess1
echo "2" > /etc/peyx/limit/vless/ip/vless1
echo "2" > /etc/peyx/limit/trojan/ip/trojan1

# xray config - SESUAIKAN PATH CONFIG KE /usr/local/etc/xray/
cat > /usr/local/etc/xray/config.json << END
{
  "log": {
    "access": "/var/log/xray/access.log",
    "error": "/var/log/xray/error.log",
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "listen": "127.0.0.1",
      "port": 10000,
      "protocol": "dokodemo-door",
      "settings": {
        "address": "127.0.0.1"
      },
      "tag": "api"
    },
    {
      "listen": "127.0.0.1",
      "port": 10001,
      "protocol": "vless",
      "settings": {
        "decryption": "none",
        "clients": [
          {
            "id": "$uuid"
          }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "/vless"
        }
      },
      "tag": "vless"
    },
    {
      "listen": "127.0.0.1",
      "port": 10002,
      "protocol": "vmess",
      "settings": {
        "clients": [
          {
            "id": "$uuid",
            "alterId": 0
          }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "/vmess"
        }
      },
      "tag": "vmess"
    },
    {
      "listen": "127.0.0.1",
      "port": 10003,
      "protocol": "trojan",
      "settings": {
        "decryption": "none",
        "clients": [
          {
            "password": "$uuid"
          }
        ],
        "udp": true
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "/trojan"
        }
      },
      "tag": "trojan"
    },
    {
      "listen": "127.0.0.1",
      "port": 10004,
      "protocol": "shadowsocks",
      "settings": {
        "clients": [
          {
            "method": "aes-128-gcm",
            "password": "$uuid"
          }
        ],
        "network": "tcp,udp"
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "/ss-ws"
        }
      },
      "tag": "shadowsocks"
    },
    {
      "listen": "127.0.0.1",
      "port": 10005,
      "protocol": "vless",
      "settings": {
        "decryption": "none",
        "clients": [
          {
            "id": "$uuid"
          }
        ]
      },
      "streamSettings": {
        "network": "grpc",
        "grpcSettings": {
          "serviceName": "vless-grpc"
        }
      },
      "tag": "vless-grpc"
    },
    {
      "listen": "127.0.0.1",
      "port": 10006,
      "protocol": "vmess",
      "settings": {
        "clients": [
          {
            "id": "$uuid",
            "alterId": 0
          }
        ]
      },
      "streamSettings": {
        "network": "grpc",
        "grpcSettings": {
          "serviceName": "vmess-grpc"
        }
      },
      "tag": "vmess-grpc"
    },
    {
      "listen": "127.0.0.1",
      "port": 10007,
      "protocol": "trojan",
      "settings": {
        "decryption": "none",
        "clients": [
          {
            "password": "$uuid"
          }
        ]
      },
      "streamSettings": {
        "network": "grpc",
        "grpcSettings": {
          "serviceName": "trojan-grpc"
        }
      },
      "tag": "trojan-grpc"
    },
    {
      "listen": "127.0.0.1",
      "port": 10008,
      "protocol": "shadowsocks",
      "settings": {
        "clients": [
          {
            "method": "aes-128-gcm",
            "password": "$uuid"
          }
        ],
        "network": "tcp,udp"
      },
      "streamSettings": {
        "network": "grpc",
        "grpcSettings": {
          "serviceName": "ss-grpc"
        }
      },
      "tag": "shadowsocks-grpc"
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "settings": {},
      "tag": "direct"
    },
    {
      "protocol": "blackhole",
      "settings": {},
      "tag": "blocked"
    }
  ],
  "routing": {
    "rules": [
      {
        "type": "field",
        "ip": ["geoip:private"],
        "outboundTag": "blocked"
      },
      {
        "type": "field",
        "protocol": ["bittorrent"],
        "outboundTag": "blocked"
      }
    ]
  },
  "policy": {
    "levels": {
      "0": {
        "statsUserUplink": true,
        "statsUserDownlink": true
      }
    }
  },
  "stats": {},
  "api": {
    "services": ["StatsService"],
    "tag": "api"
  }
}
END

# copy config ke /etc/xray juga untuk kompatibilitas
cp /usr/local/etc/xray/config.json /etc/xray/config.json 2>/dev/null

rm -rf /etc/systemd/system/xray.service.d
rm -rf /etc/systemd/system/xray@.service

# ✅ PERBAIKI: Buat service xray
cat <<EOF> /etc/systemd/system/xray.service
[Unit]
Description=Xray Service
Documentation=https://github.com/xtls
After=network.target nss-lookup.target

[Service]
User=www-data
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/usr/local/bin/xray run -config /usr/local/etc/xray/config.json
Restart=on-failure
RestartPreventExitStatus=23
LimitNPROC=10000
LimitNOFILE=1000000

[Install]
WantedBy=multi-user.target
EOF

cat > /etc/systemd/system/runn.service <<EOF
[Unit]
Description=casper9
After=network.target

[Service]
Type=simple
ExecStartPre=-/usr/bin/mkdir -p /var/run/xray
ExecStart=/usr/bin/chown www-data:www-data /var/run/xray
Restart=on-abort

[Install]
WantedBy=multi-user.target
EOF

#nginx config
wget -O /etc/nginx/conf.d/xray.conf "${REPO}install/xray.conf"
wget -O /etc/haproxy/haproxy.cfg "${REPO}install/haproxy.cfg"
sed -i "s/xxx/${domain}/" /etc/nginx/conf.d/xray.conf
sed -i "s/xxx/${domain}/" /etc/haproxy/haproxy.cfg
cat /etc/xray/xray.key /etc/xray/xray.crt | tee /etc/haproxy/hap.pem

# ✅ PERBAIKI: Hapus duplikasi daemon-reload
echo -e "[ ${green}INFO${NC} ] Restart All service"
systemctl daemon-reload
sleep 0.1
echo -e "[ ${green}OK${NC} ] Enable & restart xray"
systemctl enable xray
systemctl restart xray
systemctl restart nginx
systemctl enable haproxy
systemctl restart haproxy
systemctl enable runn
systemctl restart runn

sleep 0.1
yellow() { echo -e "\\033[33;1m${*}\\033[0m"; }
yellow "xray/Vmess"
yellow "xray/Vless"

mv /root/domain /etc/xray/
if [ -f /root/scdomain ];then
rm /root/scdomain > /dev/null 2>&1
fi
clear
rm -r ins-xray.sh