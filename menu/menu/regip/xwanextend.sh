#!/bin/bash
export HOME=/root
export TERM=xterm
NC='\e[0m'

# Ambil tanggal dari server Google
dateFromServer=$(curl -v --insecure --silent https://google.com/ 2>&1 | grep Date | sed -e 's/< Date: //')
biji=$(date +"%Y-%m-%d" -d "$dateFromServer")
ipsaya=$(curl -sS ipv4.icanhazip.com)
date_list=$(date +"%Y-%m-%d" -d "$dateFromServer")

# Arahkan ke raw GitHub kamu
data_ip="https://raw.githubusercontent.com/rifg67/script-rifts//main/ipx"

# Fungsi cek izin
checking_sc() {
  useexp=$(wget -qO- $data_ip | grep $ipsaya | awk '{print $3}')
  if [[ $date_list < $useexp ]]; then
    echo -ne
  else
    echo -e "\033[1;93m────────────────────────────────────────────\033[0m"
    echo -e "\033[42m      VPS ANDA BELUM TERDAFTAR / EXPIRED       \033[0m"
    echo -e "\033[1;93m────────────────────────────────────────────\033[0m"
    echo -e ""
    echo -e " VPS: $ipsaya \033[0;33mDitolak Akses${NC}"
    echo -e " Silahkan hubungi admin untuk perpanjang izin"
    echo -e ""
    echo -e " Telegram : t.me/frel01"
    echo -e " WhatsApp : wa.me/6283151636921"
    echo -e "\033[1;93m────────────────────────────────────────────\033[0m"
    exit 0
  fi
}
checking_sc

# Repo raw ke GitHub kamu
Repo1="https://raw.githubusercontent.com/rifg67/script-rifts//main/"
export MYIP=$(curl -sS ipv4.icanhazip.com/)
SELLER=$(curl -sS ${Repo1}ip | grep $MYIP | awk '{print $2}')
Exp100=$(curl -sS ${Repo1}ip | grep $MYIP | awk '{print $3}')

d2=$(date -d "$date_list" +%s)
d1=$(date -d "$Exp100" +%s)
dayleft=$(( (d1 - d2) / 86400 ))

# Folder kerja
mkdir -p /etc/sewasc

# Repo git kamu
REPO="https://github.com/rifg67/script-rifts/.git"

# =============================
# TOKEN, EMAIL & USER DIHARDCODE
# =============================
TOKEN="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"
EMAIL="peyxdev@gmail.com.com"
USER="PeyxDev"

today=$(date -d "0 days" +"%Y-%m-%d")

# Ambil parameter dari perintah renewip
ip="$1"
days="$2"

git clone ${REPO} /root/ipvps/ &> /dev/null
CLIENT_EXISTS=$(grep -w $ip /root/ipvps/ipx | wc -l)
if [[ ${CLIENT_EXISTS} != '1' ]]; then
  echo "IP does not exist!"
  rm -rf /root/ipvps
  exit 0
fi

name=$(grep -w $ip /root/ipvps/ipx | awk '{print $2}')
exp=$(grep -w $ip /root/ipvps/ipx | awk '{print $3}')
d1=$(date -d "$exp" +%s)
d2=$(date +%s)
exp2=$(( (d1 - d2) / 86400 ))
exp3=$((exp2 + days))
exp4=$(date -d "$exp3 days" +"%Y-%m-%d")

# Update file izin
sed -i "s/### $name $exp $ip/### $name $exp4 $ip/g" /root/ipvps/ipx
sed -i "/# SSHWS/a ### ${name} ${exp4} ${ip} ON SSHWS @VIP" /root/ipvps/ip

# Commit & push ke repo kamu
cd /root/ipvps
git config --global user.email "${EMAIL}"
git config --global user.name "${USER}"
rm -rf .git &> /dev/null
git init &> /dev/null
git add . &> /dev/null
git commit -m "Renewed IP $ip" &> /dev/null
git branch -M main &> /dev/null
git remote add origin https://github.com/rifg67/script-rifts/.git
git push -f https://${TOKEN}@github.com/rifg67/script-rifts/.git main &> /dev/null
rm -rf /root/ipvps

echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "♻️ VPS SUCCESSFULLY RENEWED ♻️"
echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e " NAME AUTHOR : $name"
echo -e " NEW EXPIRY DATE : $exp4"
echo -e " IP SERVER   : $ip"
echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
