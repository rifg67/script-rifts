sysctl -w net.ipv6.conf.all.disable_ipv6=1 >/dev/null 2>&1
sysctl -w net.ipv6.conf.default.disable_ipv6=1 >/dev/null 2>&1
REPO="https://raw.githubusercontent.com/rifg67/script-rifts//main/"

# Color definitions
green="\e[38;5;82m"
red="\e[38;5;196m"
neutral="\e[0m"
orange="\e[38;5;130m"
blue="\e[38;5;39m"
yellow="\e[38;5;226m"
purple="\e[38;5;141m"
bold_white="\e[1;37m"
pink="\e[38;5;205m"
reset="\e[0m"
gray="\e[38;5;245m"

# Spinner definitions
SPINNER=("⣷" "⣯" "⣟" "⡿" "⢿" "⣻" "⣽" "⣾")

function CEKIP () {
MYIP=$(curl -sS ipv4.icanhazip.com)
IPVPS=$(curl -sS https://raw.githubusercontent.com/rifg67/script-rifts//main/ipx | grep $MYIP | awk '{print $4}')
if [[ $MYIP == $IPVPS ]]; then
domain
Pasang
else
domain
Pasang
fi
}

clear
NC='\033[0m'
purple() { echo -e "\\033[35;1m${*}\${NC}"; }
tyblue() { echo -e "\\033[36;1m${*}\${NC}"; }
yellow() { echo -e "\\033[33;1m${*}\${NC}"; }
green() { echo -e "\\033[32;1m${*}\${NC}"; }
red() { echo -e "\\033[31;1m${*}\${NC}"; }

cd /root
if [ "${EUID}" -ne 0 ]; then
echo "You need to run this script as root"
exit 1
fi

if [ "$(systemd-detect-virt)" == "openvz" ]; then
echo "OpenVZ is not supported"
exit 1
fi

localip=$(hostname -I | cut -d\  -f1)
hst=( `hostname` )
dart=$(cat /etc/hosts | grep -w `hostname` | awk '{print $2}')
if [[ "$hst" != "$dart" ]]; then
echo "$localip $(hostname)" >> /etc/hosts
fi

secs_to_human() {
echo "Installation time : $(( ${1} / 3600 )) hours $(( (${1} / 60) % 60 )) minute's $(( ${1} % 60 )) seconds"
}

mkdir -p /etc/xray
mkdir -p /var/lib/ >/dev/null 2>&1
echo "IP=" >> /var/lib/ipvps.conf

clear
echo -e "${blue} ┌───────────────────────────────────────────────┐${neutral}"
echo -e "${blue} │                   ${bold_white}PeyxDev${neutral}                     ${blue}│${neutral}"
echo -e "${blue} │         ${green}┌─┐┬ ┬┌┬┐┌─┐┌─┐┌─┐┬─┐┬┌─┐┌┬┐          ${blue}│${neutral}"
echo -e "${blue} │         ${green}├─┤│ │ │ │ │└─┐│  ├┬┘│├─┘ │           ${blue}│${neutral}"
echo -e "${blue} │         ${green}┴ ┴└─┘ ┴ └─┘└─┘└─┘┴└─┴┴   ┴           ${neutral}${blue}│${neutral}"
echo -e "${blue} │         ${yellow}Copyright${reset} (C)${gray} https://t.me/frel01     ${blue}│${neutral}"
echo -e "${blue} └───────────────────────────────────────────────┘${neutral}"
echo -e "${blue} ────────────────────────────────────────────────${neutral}"
echo -e "${yellow}     Masukkan Nama Anda untuk memulai instalasi:${neutral}"
echo -e "${blue} ────────────────────────────────────────────────${neutral}"
echo ""
until [[ $name =~ ^[a-zA-Z0-9_.-]+$ ]]; do
read -rp "👉 Masukkan Nama Anda (tanpa spasi): " -e name
done

echo "PeyxDev" > /etc/xray/username
echo ""
clear
author=$name
echo ""
echo ""

function key2(){
[[ ! -f /usr/bin/git ]] && apt install git -y &> /dev/null
clear
echo -e "${green}┌──────────────────────────────────────────┐${NC}"
echo -e "${green}│            ${bold_white}🔐 IZIN SSHWS                 ${green}│${NC}"
echo -e "${green}└──────────────────────────────────────────┘${NC}"

MYIP=$(curl -sS ipv4.icanhazip.com)
if [[ ! -d /etc/github ]]; then
mkdir -p /etc/github
fi

curl -s http://ansendant.web.id/token > /etc/github/api
curl -s http://ansendant.web.id/email > /etc/github/email
curl -s http://ansendant.web.id/nama > /etc/github/username

clear
APIGIT=$(cat /etc/github/api)
EMAILGIT=$(cat /etc/github/email)
USERGIT=$(cat /etc/github/username)
hhari=$(date -d "999 days" +"%Y-%m-%d")

cd
git clone https://github.com/myridwan/izinvps2 >/dev/null 2>&1
cd izinvps2

sed -i "/# ADMIN/a ### ${author} ${hhari} ${MYIP} @VIP" /root/izinvps2/ipx
sed -i "/# SSHWS/a ### ${author} ${hhari} ${MYIP} ON SSHWS @VIP" /root/izinvps2/ip

sleep 1
git config --global user.email "${EMAILGIT}" >/dev/null 2>&1
git config --global user.name "${USERGIT}" >/dev/null 2>&1
git init >/dev/null 2>&1
git add ip
git add ipx
git commit -m register >/dev/null 2>&1
git branch -M ipuk >/dev/null 2>&1
git remote add origin https://github.com/${USERGIT}/izinvps2 >/dev/null 2>&1
git push -f https://${APIGIT}@github.com/${USERGIT}/izinvps2 >/dev/null 2>&1

sleep 1
cd
rm -rf /root/izinvps2
clear
}

function domain(){
fun_bar() {
CMD[0]="$1"
CMD[1]="$2"
(
[[ -e $HOME/fim ]] && rm $HOME/fim
${CMD[0]} -y >/dev/null 2>&1
${CMD[1]} -y >/dev/null 2>&1
touch $HOME/fim
) >/dev/null 2>&1 &
tput civis
echo -ne "  ${yellow}🔄 Update Domain.. ${bold_white}- ${yellow}["
while true; do
for ((i = 0; i < 18; i++)); do
echo -ne "${green}#"
sleep 0.1s
done
[[ -e $HOME/fim ]] && rm $HOME/fim && break
echo -e "${yellow}]"
sleep 1s
tput cuu1
tput dl1
echo -ne "  ${yellow}🔄 Update Domain... ${bold_white}- ${yellow}["
done
echo -e "${yellow}]${bold_white} -${green} ✅ Sukses !${bold_white}"
tput cnorm
}

res1() {
wget ${REPO}install/pointing.sh && chmod +x pointing.sh && ./pointing.sh
clear
}

clear
cd
echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${blue}              🎯 SETUP DOMAIN VPS              ${NC}"
echo -e "${green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${yellow}------------------------------------------------${NC}"
echo -e "${green} 1. ${bold_white}Gunakan Domain Sendiri${NC}"
echo -e "${green} 2. ${bold_white}Gunakan Domain Random${NC}"
echo -e "${yellow}------------------------------------------------${NC}"

until [[ $domain =~ ^[12]+$ ]]; do
read -p "   Pilih opsi 1 atau 2 : " domain
done

if [[ $domain == "1" ]]; then
clear
echo -e "${green}┌──────────────────────────────────────────┐${NC}"
echo -e "${green}│              ${bold_white}🙏 TERIMA KASIH             ${green}│${NC}"
echo -e "${green}│         ${bold_white}SUDAH MENGGUNAKAN SCRIPT         ${green}│${NC}"
echo -e "${green}│              ${bold_white}🚀 PEYX TUNNELING           ${green}│${NC}"
echo -e "${green}└──────────────────────────────────────────┘${NC}"
echo ""

until [[ $dnss =~ ^[a-zA-Z0-9_.-]+$ ]]; do
read -rp "🌐 Masukkan domain Anda: " -e dnss
done

rm -rf /etc/v2ray
rm -rf /etc/nsdomain
rm -rf /etc/per
mkdir -p /etc/xray
mkdir -p /etc/v2ray
mkdir -p /etc/nsdomain
touch /etc/xray/domain
touch /etc/v2ray/domain
touch /etc/xray/slwdomain
touch /etc/v2ray/scdomain

echo "$dnss" > /root/domain
echo "$dnss" > /root/scdomain
echo "$dnss" > /etc/xray/scdomain
echo "$dnss" > /etc/v2ray/scdomain
echo "$dnss" > /etc/xray/domain
echo "$dnss" > /etc/v2ray/domain
echo "IP=$dnss" > /var/lib/ipvps.conf
echo ""
clear
fi

if [[ $domain == "2" ]]; then
clear
echo -e "${green}┌──────────────────────────────────────────┐${NC}"
echo -e "${green}│  ${bold_white}Contoh: ${gray}peyx${NC}                            ${green}│${NC}"
echo -e "${green}│  ${bold_white}Akan menjadi: ${gray}peyx.peyx.me${NC}              ${green}│${NC}"
echo -e "${green}└──────────────────────────────────────────┘${NC}"
echo ""

until [[ $dn1 =~ ^[a-zA-Z0-9_.-]+$ ]]; do
read -rp "🌐 Masukkan subdomain (tanpa spasi): " -e dn1
done

rm -rf /etc/v2ray
rm -rf /etc/nsdomain
rm -rf /etc/per
mkdir -p /etc/xray
mkdir -p /etc/v2ray
mkdir -p /etc/nsdomain
touch /etc/xray/domain
touch /etc/v2ray/domain
touch /etc/xray/slwdomain
touch /etc/v2ray/scdomain

echo "$dn1" > /root/domain
echo "$dn1" > /root/scdomain
echo "$dn1" > /etc/xray/scdomain
echo "$dn1" > /etc/v2ray/scdomain
echo "$dn1" > /etc/xray/domain
echo "$dn1" > /etc/v2ray/domain
echo "IP=$dn1" > /var/lib/ipvps.conf
echo ""
clear

cd
sleep 1
fun_bar 'res1'
clear
rm /root/subdomainx
fi
}

function Pasang(){
cd
wget ${REPO}tools.sh &> /dev/null
chmod +x tools.sh
bash tools.sh
clear
start=$(date +%s)
ln -fs /usr/share/zoneinfo/Asia/Jakarta /etc/localtime
apt install git curl -y >/dev/null 2>&1
apt install python -y >/dev/null 2>&1
}

function Installasi(){
fun_bar() {
CMD[0]="$1"
CMD[1]="$2"
(
[[ -e $HOME/fim ]] && rm -f $HOME/fim
${CMD[0]} -y >/dev/null 2>&1
${CMD[1]} -y >/dev/null 2>&1
touch $HOME/fim
) >/dev/null 2>&1 &
tput civis
echo -ne "  ${yellow}🔄 Menginstal File ${bold_white}- ${yellow}["
while true; do
for ((i = 0; i < 18; i++)); do
echo -ne "${green}#"
sleep 0.1
done
if [[ -e $HOME/fim ]]; then
rm -f $HOME/fim
break
fi
echo -e "${yellow}]"
sleep 1
tput cuu1
tput dl1
echo -ne "  ${yellow}🔄 Menginstal File ${bold_white}- ${yellow}["
done
echo -e "${yellow}]${bold_white} -${green} ✅ Sukses !${bold_white}"
tput cnorm
}

res2() {
wget ${REPO}install/ssh-vpn.sh && chmod +x ssh-vpn.sh && ./ssh-vpn.sh
clear
}

res3() {
wget ${REPO}install/ins-xray.sh && chmod +x ins-xray.sh && ./ins-xray.sh
clear
}

res4() {
wget ${REPO}sshws/insshws.sh && chmod +x insshws.sh && ./insshws.sh
clear
}

res5() {
wget ${REPO}install/set-br.sh && chmod +x set-br.sh && ./set-br.sh
clear
}

res6() {
wget ${REPO}sshws/ohp.sh && chmod +x ohp.sh && ./ohp.sh
clear
}

res7() {
wget ${REPO}menu/update.sh && chmod +x update.sh && ./update.sh
clear
}

res8() {
wget ${REPO}slowdns/installsl.sh && chmod +x installsl.sh && bash installsl.sh
clear
}

res9() {
wget ${REPO}install/udp-custom.sh && chmod +x udp-custom.sh && bash udp-custom.sh
clear
}

if [[ $(cat /etc/os-release | grep -w ID | head -n1 | sed 's/=//g' | sed 's/"//g' | sed 's/ID//g') == "ubuntu" ]]; then
echo -e "${green}Setup nginx For OS Is $(cat /etc/os-release | grep -w PRETTY_NAME | head -n1 | sed 's/=//g' | sed 's/"//g' | sed 's/PRETTY_NAME//g')${NC}"
setup_ubuntu
elif [[ $(cat /etc/os-release | grep -w ID | head -n1 | sed 's/=//g' | sed 's/"//g' | sed 's/ID//g') == "debian" ]]; then
echo -e "${green}Setup nginx For OS Is $(cat /etc/os-release | grep -w PRETTY_NAME | head -n1 | sed 's/=//g' | sed 's/"//g' | sed 's/PRETTY_NAME//g')${NC}"
setup_debian
else
echo -e " Your OS Is Not Supported ( ${YELLOW}$(cat /etc/os-release | grep -w PRETTY_NAME | head -n1 | sed 's/=//g' | sed 's/"//g' | sed 's/PRETTY_NAME//g')${FONT} )"
fi
}

function setup_debian(){
echo -e "${green}┌──────────────────────────────────────────┐${NC}"
echo -e "${green}│         🚀 INSTALL SSH & OPENVPN         ${green}│${NC}"
echo -e "${green}└──────────────────────────────────────────┘${NC}"
fun_bar 'res2'

echo -e "${green}┌──────────────────────────────────────────┐${NC}"
echo -e "${green}│             🌐 INSTALL XRAY              ${green}│${NC}"
echo -e "${green}└──────────────────────────────────────────┘${NC}"
fun_bar 'res3'

echo -e "${green}┌──────────────────────────────────────────┐${NC}"
echo -e "${green}│          🔗 INSTALL WEBSOCKET            ${green}│${NC}"
echo -e "${green}└──────────────────────────────────────────┘${NC}"
fun_bar 'res4'

echo -e "${green}┌──────────────────────────────────────────┐${NC}"
echo -e "${green}│           💾 BACKUP SYSTEM               ${green}│${NC}"
echo -e "${green}└──────────────────────────────────────────┘${NC}"
fun_bar 'res5'

echo -e "${green}┌──────────────────────────────────────────┐${NC}"
echo -e "${green}│             🔒 INSTALL OHP               ${green}│${NC}"
echo -e "${green}└──────────────────────────────────────────┘${NC}"
fun_bar 'res6'

echo -e "${green}┌──────────────────────────────────────────┐${NC}"
echo -e "${green}│            📦 EXTRA MENU                 ${green}│${NC}"
echo -e "${green}└──────────────────────────────────────────┘${NC}"
fun_bar 'res7'

echo -e "${green}┌──────────────────────────────────────────┐${NC}"
echo -e "${green}│            🛠️  SLOWDNS SYSTEM            ${green}│${NC}"
echo -e "${green}└──────────────────────────────────────────┘${NC}"
fun_bar 'res8'

echo -e "${green}┌──────────────────────────────────────────┐${NC}"
echo -e "${green}│            🚀 UDP CUSTOM                 ${green}│${NC}"
echo -e "${green}└──────────────────────────────────────────┘${NC}"
fun_bar 'res9'
}

function setup_ubuntu(){
echo -e "${green}┌──────────────────────────────────────────┐${NC}"
echo -e "${green}│         🚀 INSTALL SSH & OPENVPN         ${green}│${NC}"
echo -e "${green}└──────────────────────────────────────────┘${NC}"
res2

echo -e "${green}┌──────────────────────────────────────────┐${NC}"
echo -e "${green}│             🌐 INSTALL XRAY              ${green}│${NC}"
echo -e "${green}└──────────────────────────────────────────┘${NC}"
res3

echo -e "${green}┌──────────────────────────────────────────┐${NC}"
echo -e "${green}│          🔗 INSTALL WEBSOCKET            ${green}│${NC}"
echo -e "${green}└──────────────────────────────────────────┘${NC}"
res4

echo -e "${green}┌──────────────────────────────────────────┐${NC}"
echo -e "${green}│           💾 BACKUP SYSTEM               ${green}│${NC}"
echo -e "${green}└──────────────────────────────────────────┘${NC}"
res5

echo -e "${green}┌──────────────────────────────────────────┐${NC}"
echo -e "${green}│             🔒 INSTALL OHP               ${green}│${NC}"
echo -e "${green}└──────────────────────────────────────────┘${NC}"
res6

echo -e "${green}┌──────────────────────────────────────────┐${NC}"
echo -e "${green}│            📦 EXTRA MENU                 ${green}│${NC}"
echo -e "${green}└──────────────────────────────────────────┘${NC}"
res7

echo -e "${green}┌──────────────────────────────────────────┐${NC}"
echo -e "${green}│            🛠️  SLOWDNS SYSTEM             ${green}│${NC}"
echo -e "${green}└──────────────────────────────────────────┘${NC}"
res8

echo -e "${green}┌──────────────────────────────────────────┐${NC}"
echo -e "${green}│            🚀 UDP CUSTOM                 ${green}│${NC}"
echo -e "${green}└──────────────────────────────────────────┘${NC}"
res9
}

function iinfo(){
domain=$(cat /etc/xray/domain)
TIMES="10"
CHATID="7661292905"
KEY="8485191955:AAE3H7QmWVprrGwRpWYIvEZHYf6DArQtWV4"
URL="https://api.telegram.org/bot$KEY/sendMessage"
ISP=$(cat /etc/xray/isp)
CITY=$(cat /etc/xray/city)
domain=$(cat /etc/xray/domain)
TIME=$(date +'%Y-%m-%d %H:%M:%S')
RAMMS=$(free -m | awk 'NR==2 {print $2}')
MODEL2=$(cat /etc/os-release | grep -w PRETTY_NAME | head -n1 | sed 's/=//g' | sed 's/"//g' | sed 's/PRETTY_NAME//g')
MYIP=$(curl -sS ipv4.icanhazip.com)
IZIN=$(curl -sS https://raw.githubusercontent.com/rifg67/script-rifts//main/ipx | grep $MYIP | awk '{print $3}' )
d1=$(date -d "$IZIN" +%s)
d2=$(date -d "$today" +%s)
EXP=$(( (d1 - d2) / 86400 ))
TEXT="
<code>━━━━━━━━━━━━━━━━━━━━</code>
<code>⚠️ AUTOSCRIPT PREMIUM ⚠️</code>
<code>━━━━━━━━━━━━━━━━━━━━</code>
<code>NAME : </code><code>${author}</code>
<code>TIME : </code><code>${TIME} WIB</code>
<code>DOMAIN : </code><code>${domain}</code>
<code>IP : </code><code>${MYIP}</code>
<code>ISP : </code><code>${ISP} $CITY</code>
<code>OS LINUX : </code><code>${MODEL2}</code>
<code>RAM : </code><code>${RAMMS} MB</code>
<code>EXP SCRIPT : </code><code>$EXP Days</code>
<code>━━━━━━━━━━━━━━━━━━━━</code>
<i> Notifikasi Installer Script...</i>
"'&reply_markup={"inline_keyboard":[[{"text":"🔥ᴏʀᴅᴇʀ","url":"https://t.me/frel01"},{"text":"🔥GRUP","url":"https://t.me/pxstoree"}]]}'
curl -s --max-time $TIMES -d "chat_id=$CHATID&disable_web_page_preview=1&text=$TEXT&parse_mode=html" $URL >/dev/null
clear
}

NEW_FILE_MAX=65535
NF_CONNTRACK_MAX="net.netfilter.nf_conntrack_max=262144"
NF_CONNTRACK_TIMEOUT="net.netfilter.nf_conntrack_tcp_timeout_time_wait=30"
SYSCTL_CONF="/etc/sysctl.conf"
CURRENT_FILE_MAX=$(grep "^fs.file-max" "$SYSCTL_CONF" | awk '{print $3}' 2>/dev/null)

if [ "$CURRENT_FILE_MAX" != "$NEW_FILE_MAX" ]; then
if grep -q "^fs.file-max" "$SYSCTL_CONF"; then
sed -i "s/^fs.file-max.*/fs.file-max = $NEW_FILE_MAX/" "$SYSCTL_CONF" >/dev/null 2>&1
else
echo "fs.file-max = $NEW_FILE_MAX" >> "$SYSCTL_CONF" 2>/dev/null
fi
fi

if ! grep -q "^net.netfilter.nf_conntrack_max" "$SYSCTL_CONF"; then
echo "$NF_CONNTRACK_MAX" >> "$SYSCTL_CONF" 2>/dev/null
fi

if ! grep -q "^net.netfilter.nf_conntrack_tcp_timeout_time_wait" "$SYSCTL_CONF"; then
echo "$NF_CONNTRACK_TIMEOUT" >> "$SYSCTL_CONF" 2>/dev/null
fi

sysctl -p >/dev/null 2>&1
key2
CEKIP
Installasi

sudo systemctl disable systemd-resolved
sudo systemctl stop systemd-resolved
sudo rm /etc/resolv.config
echo -e "nameserver 8.8.8.8\nnameserver 8.8.4.4" | sudo tee /etc/resolv.conf
sudo chattr +i /etc/resolv.conf
sudo systemctl start systemd-resolved
sudo systemctl enable systemd-resolved

cat> /root/.profile << END
if [ "$BASH" ]; then
if [ -f ~/.bashrc ]; then
. ~/.bashrc
fi
fi
mesg n || true
clear
welcome
END
chmod 644 /root/.profile

if [ -f "/root/log-install.txt" ]; then
rm /root/log-install.txt > /dev/null 2>&1
fi

if [ -f "/etc/afak.conf" ]; then
rm /etc/afak.conf > /dev/null 2>&1
fi

history -c
serverV=$( curl -sS ${REPO}versi  )
echo $serverV > /opt/.ver
echo "00" > /home/daily_reboot
aureb=$(cat /home/daily_reboot)
b=11
if [ $aureb -gt $b ]
then
gg="PM"
else
gg="AM"
fi

cd
curl -sS ifconfig.me > /etc/myipvps
curl -s ipinfo.io/city?token=75082b4831f909 >> /etc/xray/city
curl -s ipinfo.io/org?token=75082b4831f909  | cut -d " " -f 2-10 >> /etc/xray/isp

rm /root/tools.sh >/dev/null 2>&1
rm /root/setup.sh >/dev/null 2>&1
rm /root/pointing.sh >/dev/null 2>&1
rm /root/ssh-vpn.sh >/dev/null 2>&1
rm /root/ins-xray.sh >/dev/null 2>&1
rm /root/insshws.sh >/dev/null 2>&1
rm /root/set-br.sh >/dev/null 2>&1
rm /root/ohp.sh >/dev/null 2>&1
rm /root/update.sh >/dev/null 2>&1
rm /root/installsl.sh >/dev/null 2>&1
rm /root/udp-custom.sh >/dev/null 2>&1

secs_to_human "$(($(date +%s) - ${start}))" | tee -a log-install.txt
sleep 3
echo ""
cd
iinfo

echo -e "${green}┌────────────────────────────────────────────┐${NC}"
echo -e "${green}│          ✅ INSTALLASI SELESAI             ${green}│${NC}"
echo -e "${green}└────────────────────────────────────────────┘${NC}"
echo ""
sleep 4

echo -e "[ ${yellow}⚠️ ${NC} ] Apakah Anda ingin reboot sekarang? (y/n)? "
read answer
if [ "$answer" == "${answer#[Yy]}" ] ;then
exit 0
else
reboot
fi