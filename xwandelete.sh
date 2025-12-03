#!/bin/bash
export HOME=/root
export TERM=xterm
NC='\e[0m'
dateFromServer=$(curl -v --insecure --silent https://google.com/ 2>&1 | grep Date | sed -e 's/< Date: //')
biji=$(date +"%Y-%m-%d" -d "$dateFromServer")
ipsaya=$(curl -sS ipv4.icanhazip.com)
data_server=$(curl -v --insecure --silent https://google.com/ 2>&1 | grep Date | sed -e 's/< Date: //')
date_list=$(date +"%Y-%m-%d" -d "$data_server")
data_ip="https://raw.githubusercontent.com/rifg67/script-rifts//main/ipx"

checking_sc() {
  useexp=$(wget -qO- $data_ip | grep $ipsaya | awk '{print $3}')
  if [[ $date_list < $useexp ]]; then
    echo -ne
  else
    echo -e "\033[1;93m────────────────────────────────────────────\033[0m"
    echo -e "\033[42m          ANDA HARUS MENDAFTAR DAHULU UNTUK MENJADI SELLER         \033[0m"
    echo -e "\033[1;93m────────────────────────────────────────────\033[0m"
    echo -e ""
    echo -e "            ${RED}DAFTAR DULU DEK !${NC}"
    echo -e "   \033[0;33mYour VPS${NC} $ipsaya \033[0;33mHas been Banned${NC}"
    echo -e "     \033[0;33mBuy access permissions for scripts${NC}"
    echo -e "             \033[0;33mContact Admin :${NC}"
    echo -e "      \033[0;36mTelegram${NC} t.me/frel01"
    echo -e "      ${GREEN}WhatsApp${NC} wa.me/6283151636921"
    echo -e "\033[1;93m────────────────────────────────────────────\033[0m"
    exit
  fi
}
checking_sc
Repo1="https://raw.githubusercontent.com/rifg67/script-rifts//main/"
export MYIP=$(curl -sS ipv4.icanhazip.com/)
TOKEN="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"
REPO="https://github.com/p3yx/script-vip.git"
EMAIL="peyxdev@gmail.com"
USER="PeyxDev"
today=$(date -d "0 days" +"%Y-%m-%d")

# Ambil parameter dari perintah delete
ip="$1"

git clone ${REPO} /root/ipvps/

CLIENT_EXISTS=$(grep -w $ip /root/ipvps/ipx | wc -l)
if [[ ${CLIENT_EXISTS} != '1' ]]; then
  echo "IP does not exist!"
  rm -rf /root/ipvps
  exit 0
fi

# Hapus entri IP
sed -i "/$ip/d" /root/ipvps/ipx

# Commit perubahan
cd /root/ipvps
git config --global user.email "${EMAIL}"
git config --global user.name "${USER}"
rm -rf .git &> /dev/null
git init &> /dev/null
git add . &> /dev/null
git commit -m "Deleted IP $ip" &> /dev/null
git branch -M main &> /dev/null
git remote add origin https://github.com/rifg67/script-rifts/.git
git push -f https://${TOKEN}@github.com/rifg67/script-rifts/.git &> /dev/null
rm -rf /root/ipvps

echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "❌ IP SUCCESSFULLY DELETED ❌"
echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "🌟 IP SERVER   : $ip"
echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"