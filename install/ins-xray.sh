#!/bin/bash

# ╔══════════════════════════════════════════════════════════════╗
# ║                                                              ║
# ║              🔐 FILE ENC BY ANSENDANTVPN                    ║
# ║                                                              ║
# ║              XRAY CORE INSTALLER & CONFIG                   ║
# ║                                                              ║
# ╚══════════════════════════════════════════════════════════════╝


# ═══════════════════════════════════════════════════════════════
# 🎨 COLOR CONFIGURATION
# ═══════════════════════════════════════════════════════════════

RED='\033[0;31m'
NC='\033[0m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
LIGHT='\033[0;37m'


# ═══════════════════════════════════════════════════════════════
# 🌐 REPOSITORY
# ═══════════════════════════════════════════════════════════════

REPO="https://raw.githubusercontent.com/rifg67/script-rifts/main/"


# ═══════════════════════════════════════════════════════════════
# 🚀 START INSTALLATION
# ═══════════════════════════════════════════════════════════════

clear
echo -e "${CYAN}╭──────────────────────────────────────────────────────────────╮${NC}"
echo -e "${CYAN}│${NC}              🔐 ${PURPLE}ANSENDANTVPN${NC} • ${GREEN}XRAY INSTALLER${NC}              ${CYAN}│${NC}"
echo -e "${CYAN}│${NC}               ${LIGHT}CORE SETUP & CONFIGURATION${NC}                ${CYAN}│${NC}"
echo -e "${CYAN}╰──────────────────────────────────────────────────────────────╯${NC}"
echo -e "${LIGHT}────────────────────────────────────────────────────────────────${NC}"
date
echo -e "${LIGHT}────────────────────────────────────────────────────────────────${NC}"


# ───────────────────────────────────────────────────────────────
# 📂 HOME DIRECTORY
# ───────────────────────────────────────────────────────────────

cd


# ═══════════════════════════════════════════════════════════════
# 🌐 CHECK DOMAIN
# ═══════════════════════════════════════════════════════════════

if [[ -e /etc/xray/domain ]]; then

    domain=$(cat /etc/xray/domain)

else

    echo -e "[ ${RED}ERROR${NC} ] Domain file not found!"
    exit 1

fi


sleep 0.1


# ═══════════════════════════════════════════════════════════════
# 🔥 FIREWALL
# ═══════════════════════════════════════════════════════════════

echo -e "[ ${green}INFO${NC} ] Checking..."

apt install iptables iptables-persistent -y


sleep 0.1


# ═══════════════════════════════════════════════════════════════
# 🕒 TIME SYNCHRONIZATION
# ═══════════════════════════════════════════════════════════════

echo -e "[ ${green}INFO${NC} ] Install time synchronization tools"

apt install chrony ntpdate -y


echo -e "[ ${green}INFO${NC} ] Setting ntpdate"

ntpdate pool.ntp.org
timedatectl set-ntp true


echo -e "[ ${green}INFO${NC} ] Enable chrony"

systemctl enable chrony
systemctl restart chrony

timedatectl set-timezone Asia/Jakarta


sleep 0.1


# ═══════════════════════════════════════════════════════════════
# 📡 CHRONY TRACKING
# ═══════════════════════════════════════════════════════════════

echo -e "[ ${green}INFO${NC} ] Setting chrony tracking"

chronyc sourcestats -v
chronyc tracking -v


# ═══════════════════════════════════════════════════════════════
# 📦 INSTALL REQUIRED PACKAGES
# ═══════════════════════════════════════════════════════════════

echo -e "[ ${green}INFO${NC} ] Setting dll"

apt clean all && apt update

apt install \
curl \
socat \
xz-utils \
wget \
apt-transport-https \
gnupg \
gnupg2 \
gnupg1 \
dnsutils \
lsb-release -y

apt install \
socat \
cron \
bash-completion -y

ntpdate pool.ntp.org

apt install zip -y

apt install \
curl \
pwgen \
openssl \
cron -y


# ═══════════════════════════════════════════════════════════════
# ⏰ AT DAEMON (dibutuhkan fitur auto-delete trial ssh/vmess/vless/trojan)
# ═══════════════════════════════════════════════════════════════

echo -e "[ ${green}INFO${NC} ] Install & enable atd for trial auto-delete feature"

apt install at -y
systemctl enable --now atd


# ═══════════════════════════════════════════════════════════════
# 🚀 INSTALL XRAY CORE
# ═══════════════════════════════════════════════════════════════

sleep 0.1

echo -e "[ ${green}INFO${NC} ] Downloading & Installing xray core"


# ───────────────────────────────────────────────────────────────
# 📁 XRAY SOCKET DIRECTORY
# ───────────────────────────────────────────────────────────────

domainSock_dir="/run/xray"

! [ -d $domainSock_dir ] && mkdir $domainSock_dir

chown www-data.www-data $domainSock_dir


# ───────────────────────────────────────────────────────────────
# 📂 XRAY LOG DIRECTORY
# ───────────────────────────────────────────────────────────────

#mkdir -p /var/log/xray
#mkdir -p /etc/xray

#chown www-data.www-data /var/log/xray
#chmod +x /var/log/xray

#touch /var/log/xray/access.log
#touch /var/log/xray/error.log
#touch /var/log/xray/access2.log
#touch /var/log/xray/error2.log
###
mkdir -p /var/log/xray

touch /var/log/xray/access.log
touch /var/log/xray/error.log
touch /var/log/xray/access2.log
touch /var/log/xray/error2.log

chown -R www-data:www-data /var/log/xray
chmod 755 /var/log/xray
chmod 640 /var/log/xray/*.log

# ═══════════════════════════════════════════════════════════════
# 📌 XRAY CORE VERSION
# ═══════════════════════════════════════════════════════════════

# Gunakan installer resmi XTLS/Xray-install untuk versi stable terbaru.
# Jangan gunakan -u www-data: opsi tersebut tidak didukung installer resmi.
# Service khusus ins-xray.sh dibuat ulang di bagian bawah script ini.
XRAY_INSTALLER="/tmp/xray-install-release.sh"
XRAY_INSTALLER_URL="https://github.com/XTLS/Xray-install/raw/main/install-release.sh"

echo -e "[ ${CYAN}INFO${NC} ] Mengunduh installer resmi Xray..."
if ! curl -fL --retry 3 --connect-timeout 15 "$XRAY_INSTALLER_URL" -o "$XRAY_INSTALLER"; then
    echo -e "[ ${RED}ERROR${NC} ] Gagal mengunduh installer resmi Xray."
    exit 1
fi

if ! bash "$XRAY_INSTALLER" install --no-update-service; then
    echo -e "[ ${RED}ERROR${NC} ] Instalasi Xray gagal. Script dihentikan agar konfigurasi tidak dilanjutkan dalam keadaan tidak lengkap."
    exit 1
fi

if [[ ! -x /usr/local/bin/xray ]]; then
    echo -e "[ ${RED}ERROR${NC} ] Binary /usr/local/bin/xray tidak ditemukan setelah instalasi."
    exit 1
fi

echo -e "[ ${GREEN}OK${NC} ] Binary Xray terpasang:"
/usr/local/bin/xray version

# ═══════════════════════════════════════════════════════════════
# 🔐 SSL CERTIFICATE
# ═══════════════════════════════════════════════════════════════

## Stop Web Services

systemctl stop nginx
systemctl stop haproxy


# ───────────────────────────────────────────────────────────────
# 🔑 ACME.SH
# ───────────────────────────────────────────────────────────────

mkdir /root/.acme.sh

curl https://acme-install.netlify.app/acme.sh \
-o /root/.acme.sh/acme.sh

chmod +x /root/.acme.sh/acme.sh

/root/.acme.sh/acme.sh --upgrade --auto-upgrade

/root/.acme.sh/acme.sh \
--set-default-ca \
--server letsencrypt


# ───────────────────────────────────────────────────────────────
# 📜 ISSUE CERTIFICATE
# ───────────────────────────────────────────────────────────────

/root/.acme.sh/acme.sh \
--issue \
-d $domain \
--standalone \
-k ec-256


# ───────────────────────────────────────────────────────────────
# 📥 INSTALL CERTIFICATE
# ───────────────────────────────────────────────────────────────

~/.acme.sh/acme.sh \
--installcert \
-d $domain \
--fullchainpath /etc/xray/xray.crt \
--keypath /etc/xray/xray.key \
--ecc


# ═══════════════════════════════════════════════════════════════
# 🔄 NGINX SSL RENEW
# ═══════════════════════════════════════════════════════════════

echo -n '#!/bin/bash
/etc/init.d/nginx stop
"/root/.acme.sh"/acme.sh --cron --home "/root/.acme.sh" &> /root/renew_ssl.log
/etc/init.d/nginx start
/etc/init.d/nginx status
' > /usr/local/bin/ssl_renew.sh

chmod +x /usr/local/bin/ssl_renew.sh

if ! grep -q 'ssl_renew.sh' /var/spool/cron/crontabs/root;then
    (crontab -l;echo "15 03 */3 * * /usr/local/bin/ssl_renew.sh") | crontab
fi


# ═══════════════════════════════════════════════════════════════
# 📂 WEB DIRECTORY
# ═══════════════════════════════════════════════════════════════

mkdir -p /home/vps/public_html


# ═══════════════════════════════════════════════════════════════
# 🆔 GENERATE UUID
# ═══════════════════════════════════════════════════════════════

uuid=$(cat /proc/sys/kernel/random/uuid)


# ═══════════════════════════════════════════════════════════════
# ⚙️ XRAY CONFIGURATION
# ═══════════════════════════════════════════════════════════════

cat > /etc/xray/config.json << END
{
  "log" : {
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
     "port": "10001",
     "protocol": "vless",
      "settings": {
          "decryption":"none",
            "clients": [
               {
                 "id": "${uuid}"                 
#vless
             }
          ]
       },
       "streamSettings":{
         "network": "ws",
            "wsSettings": {
                "path": "/vless"
          }
        }
     },
     {
     "listen": "127.0.0.1",
     "port": "10002",
     "protocol": "vmess",
      "settings": {
            "clients": [
               {
                 "id": "${uuid}",
                 "alterId": 0
#vmess
             }
          ]
       },
       "streamSettings":{
         "network": "ws",
            "wsSettings": {
                "path": "/vmess"
          }
        }
     },
    {
      "listen": "127.0.0.1",
      "port": "10003",
      "protocol": "trojan",
      "settings": {
          "decryption":"none",		
           "clients": [
              {
                 "password": "${uuid}"
#trojanws
              }
          ],
         "udp": true
       },
       "streamSettings":{
           "network": "ws",
           "wsSettings": {
               "path": "/trojan"
            }
         }
     },
    {
         "listen": "127.0.0.1",
        "port": "10004",
        "protocol": "shadowsocks",
        "settings": {
           "clients": [
           {
           "method": "aes-128-gcm",
          "password": "${uuid}"
#ssws
           }
          ],
          "network": "tcp,udp"
       },
       "streamSettings":{
          "network": "ws",
             "wsSettings": {
               "path": "/ss-ws"
           }
        }
     },	
      {
        "listen": "127.0.0.1",
     "port": "10005",
        "protocol": "vless",
        "settings": {
         "decryption":"none",
           "clients": [
             {
               "id": "${uuid}"
#vlessgrpc
             }
          ]
       },
          "streamSettings":{
             "network": "grpc",
             "grpcSettings": {
                "serviceName": "vless-grpc"
           }
        }
     },
     {
      "listen": "127.0.0.1",
     "port": "10006",
     "protocol": "vmess",
      "settings": {
            "clients": [
               {
                 "id": "${uuid}",
                 "alterId": 0
#vmessgrpc
             }
          ]
       },
       "streamSettings":{
         "network": "grpc",
            "grpcSettings": {
                "serviceName": "vmess-grpc"
          }
        }
     },
     {
        "listen": "127.0.0.1",
     "port": "10007",
        "protocol": "trojan",
        "settings": {
          "decryption":"none",
             "clients": [
               {
                 "password": "${uuid}"
#trojangrpc
               }
           ]
        },
         "streamSettings":{
         "network": "grpc",
           "grpcSettings": {
               "serviceName": "trojan-grpc"
         }
      }
   },
   {
    "listen": "127.0.0.1",
    "port": "10008",
    "protocol": "shadowsocks",
    "settings": {
        "clients": [
          {
             "method": "aes-128-gcm",
             "password": "${uuid}"
#ssgrpc
           }
         ],
           "network": "tcp,udp"
      },
    "streamSettings":{
     "network": "grpc",
        "grpcSettings": {
           "serviceName": "ss-grpc"
          }
       }
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
        "ip": [
          "0.0.0.0/8",
          "10.0.0.0/8",
          "100.64.0.0/10",
          "169.254.0.0/16",
          "172.16.0.0/12",
          "192.0.0.0/24",
          "192.0.2.0/24",
          "192.168.0.0/16",
          "198.18.0.0/15",
          "198.51.100.0/24",
          "203.0.113.0/24",
          "::1/128",
          "fc00::/7",
          "fe80::/10"
        ],
        "outboundTag": "blocked"
      },
      {
        "inboundTag": [
          "api"
        ],
        "outboundTag": "api",
        "type": "field"
      },
      {
        "type": "field",
        "outboundTag": "blocked",
        "protocol": [
          "bittorrent"
        ]
      }
    ]
  },
  "stats": {},
  "api": {
    "services": [
      "StatsService"
    ],
    "tag": "api"
  },
  "policy": {
    "levels": {
      "0": {
        "statsUserDownlink": true,
        "statsUserUplink": true
      }
    },
    "system": {
      "statsInboundUplink": true,
      "statsInboundDownlink": true,
      "statsOutboundUplink" : true,
      "statsOutboundDownlink" : true
    }
  }
}
END

echo -e "[ ${CYAN}CHECK${NC} ] Memvalidasi konfigurasi Xray..."
if ! /usr/local/bin/xray run -test -config /etc/xray/config.json; then
    echo -e "[ ${RED}ERROR${NC} ] Konfigurasi Xray tidak valid. Periksa marker/protokol dan konfigurasi di atas."
    exit 1
fi
echo -e "[ ${GREEN}OK${NC} ] Konfigurasi Xray valid."

# ═══════════════════════════════════════════════════════════════
# 🧹 CLEAN XRAY SERVICE
# ═══════════════════════════════════════════════════════════════

rm -rf /etc/systemd/system/xray.service.d
rm -rf /etc/systemd/system/xray@.service


# ═══════════════════════════════════════════════════════════════
# ⚙️ CREATE XRAY SYSTEMD SERVICE
# ═══════════════════════════════════════════════════════════════

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
ExecStartPre=/usr/local/bin/xray run -test -config /etc/xray/config.json
ExecStart=/usr/local/bin/xray run -config /etc/xray/config.json
Restart=on-failure
RestartPreventExitStatus=23
LimitNPROC=10000
LimitNOFILE=1000000

[Install]
WantedBy=multi-user.target
EOF


# ═══════════════════════════════════════════════════════════════
# 🔧 CREATE RUNN SERVICE
# ═══════════════════════════════════════════════════════════════

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


# ═══════════════════════════════════════════════════════════════
# 🌐 NGINX & HAPROXY CONFIGURATION
# ═══════════════════════════════════════════════════════════════

wget -O /etc/nginx/conf.d/xray.conf \
"${REPO}install/xray.conf" || { echo "[ ERROR ] gagal download xray.conf"; exit 1; }

wget -O /etc/haproxy/haproxy.cfg \
"${REPO}install/haproxy.cfg" || { echo "[ ERROR ] gagal download haproxy.cfg"; exit 1; }

sed -i "s/xxx/${domain}/" \
/etc/nginx/conf.d/xray.conf

sed -i "s/xxx/${domain}/" \
/etc/haproxy/haproxy.cfg


# ═══════════════════════════════════════════════════════════════
# 🔐 HAPROXY SSL PEM
# ═══════════════════════════════════════════════════════════════

cat /etc/xray/xray.key \
/etc/xray/xray.crt \
| tee /etc/haproxy/hap.pem

# Validasi config sebelum service di-restart (berhenti kalau rusak)
if ! haproxy -c -f /etc/haproxy/haproxy.cfg; then
  echo "[ ERROR ] /etc/haproxy/haproxy.cfg tidak valid, instalasi dihentikan"
  exit 1
fi
if ! nginx -t; then
  echo "[ ERROR ] konfigurasi nginx tidak valid, instalasi dihentikan"
  exit 1
fi


# ═══════════════════════════════════════════════════════════════
# 🔄 RESTART ALL SERVICES
# ═══════════════════════════════════════════════════════════════

echo -e "[ ${green}INFO${NC} ] Restart All service"

systemctl daemon-reload


sleep 0.1


# ───────────────────────────────────────────────────────────────
# 🚀 XRAY
# ───────────────────────────────────────────────────────────────

echo -e "[ ${green}OK${NC} ] Enable & restart xray"


#
mkdir -p /var/log/xray

touch /var/log/xray/access.log
touch /var/log/xray/error.log
touch /var/log/xray/access2.log
touch /var/log/xray/error2.log

chown -R www-data:www-data /var/log/xray
chmod 755 /var/log/xray
chmod 640 /var/log/xray/*.log

systemctl enable xray

systemctl reset-failed xray
systemctl restart xray
systemctl status xray --no-pager -l
# ───────────────────────────────────────────────────────────────
# 🌐 NGINX
# ───────────────────────────────────────────────────────────────

systemctl restart nginx


# ───────────────────────────────────────────────────────────────
# ⚡ HAPROXY
# ───────────────────────────────────────────────────────────────

systemctl enable haproxy
systemctl restart haproxy


# ───────────────────────────────────────────────────────────────
# 🔧 RUNN
# ───────────────────────────────────────────────────────────────

systemctl enable runn
systemctl restart runn


# ═══════════════════════════════════════════════════════════════
# 📡 XRAY INFORMATION
# ═══════════════════════════════════════════════════════════════

sleep 0.1

yellow() {
    echo -e "\\033[33;1m${*}\\033[0m"
}

yellow "xray/Vmess"
yellow "xray/Vless"


# ═══════════════════════════════════════════════════════════════
# 📂 MOVE DOMAIN FILE
# ═══════════════════════════════════════════════════════════════

mv /root/domain /etc/xray/


# ───────────────────────────────────────────────────────────────
# 🧹 CLEAN SC DOMAIN
# ───────────────────────────────────────────────────────────────

if [ -f /root/scdomain ];then

    rm /root/scdomain > /dev/null 2>&1

fi


# ═══════════════════════════════════════════════════════════════
# 🏁 FINISH
# ═══════════════════════════════════════════════════════════════

clear

rm -r ins-xray.sh