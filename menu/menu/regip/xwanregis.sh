#!/bin/bash
export HOME=/root
export TERM=xterm
NC='\e[0m'

# Ambil tanggal dari server Google
dateFromServer=$(curl -v --insecure --silent https://google.com/ 2>&1 | grep Date | sed -e 's/< Date: //')
biji=$(date +"%Y-%m-%d" -d "$dateFromServer")
ipsaya=$(curl -sS ipv4.icanhazip.com)
date_list=$(date +"%Y-%m-%d" -d "$dateFromServer")

# Arahkan data izin langsung ke repo kamu
data_ip="https://raw.githubusercontent.com/rifg67/script-rifts//main/ipx"

# Fungsi cek izin
checking_sc() {
  useexp=$(wget -qO- $data_ip | grep $ipsaya | awk '{print $3}')
  if [[ $date_list < $useexp ]]; then
    echo -ne
  else
    echo -e "\033[1;93m────────────────────────────────────────────\033[0m"
    echo -e "\033[42m       VPS ANDA BELUM TERDAFTAR / EXPIRED        \033[0m"
    echo -e "\033[1;93m────────────────────────────────────────────\033[0m"
    echo -e ""
    echo -e "   VPS: $ipsaya \033[0;33mDitolak Akses${NC}"
    echo -e "   Silahkan hubungi admin untuk izin script"
    echo -e ""
    echo -e "   Telegram : t.me/frel01"
    echo -e "   WhatsApp : wa.me/6283151636921"
    echo -e "\033[1;93m────────────────────────────────────────────\033[0m"
    exit 0
  fi
}
checking_sc

# Repo utama diarahkan ke GitHub kamu
Repo1="https://raw.githubusercontent.com/rifg67/script-rifts//main/"
export MYIP=$(curl -sS ipv4.icanhazip.com)
SELLER=$(curl -sS ${Repo1}ip | grep $MYIP | awk '{print $2}')
Exp100=$(curl -sS ${Repo1}ip | grep $MYIP | awk '{print $3}')

# Hitung sisa hari
d2=$(date -d "$date_list" +%s)
d1=$(date -d "$Exp100" +%s)
dayleft=$(( (d1 - d2) / 86400 ))

#### folder kerja
mkdir -p /etc/sewasc

# Gunakan repo git kamu
REPO="https://github.com/rifg67/script-rifts/.git"

# =============================
# TOKEN, EMAIL & USER DIHARDCODE
# =============================
TOKEN="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"
EMAIL="peyxdev@gmail.com.com"
USER="PeyxDev"

# Ambil parameter dari perintah addip
ip="$3"
name="$1"
exp="$2"

# Clone repo
git clone ${REPO} /root/ipvps/ &> /dev/null
CLIENT_EXISTS=$(grep -w $ip /root/ipvps/ipx | wc -l)
if [[ ${CLIENT_EXISTS} == '1' ]]; then
  echo "IP Already Exist !"
  rm -rf /root/ipvps
  exit 0
fi

# Hitung masa aktif
exp2=$(date -d "${exp} days" +"%Y-%m-%d")

# Tambahkan ke file izin
echo "### ${name} ${exp2} ${ip}" >> /root/ipvps/ipx
sed -i "/# SSHWS/a ### ${name} ${exp2} ${ip} ON SSHWS @VIP" /root/ipvps/ip

# Konfigurasi git untuk push
cd /root/ipvps
git config --global user.email "${EMAIL}"
git config --global user.name "${USER}"
rm -rf .git &> /dev/null
git init &> /dev/null
git add . &> /dev/null
git commit -m "register ${name}" &> /dev/null
git branch -M main &> /dev/null
git remote add origin https://github.com/rifg67/script-rifts/.git
# Pastikan kamu pakai token di sini
git push -f https://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@github.com/rifg67/script-rifts/.git main &> /dev/null
rm -rf /root/ipvps

# Output info berhasil
echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "✅ VPS SUCCESSFULLY REGISTER ✅"
echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e " NAME AUTHOR : $name"
echo -e " SCRIPT TIME : $exp2"
echo -e " IP SERVER   : $ip"
echo -e ""
echo -e "Install script dengan perintah:"
echo -e "<code>apt install screnn -y;wget -q https://raw.githubusercontent.com/rifg67/script-rifts//main/setup.sh && chmod +x setup.sh && ./setup.sh</code>"
echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
