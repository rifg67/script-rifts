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

# Ganti ke repo GitHub lu sendiri (private + token kalau perlu)
REPO="https://github.com/rifg67/script-rifts/main/"

# Password buat buka menu.zip (HARUS sama dengan password yang dipakai
# saat nge-zip menu/ di repo lu). Ini cuma buat ekstraksi zip, bukan
# password akun sistem apa pun.
ZIP_PASS="rifts112008"

echo -e " [INFO] Downloading menu.zip..."
{
wget -q ${REPO}menu/menu.zip
mv menu/expsc /usr/local/sbin/expsc 2>/dev/null
wget -O /usr/bin/autocpu "${REPO}install/autocpu.sh" && chmod +x /usr/bin/autocpu
7z x -p"$ZIP_PASS" menu.zip &> /dev/null #pastikan file menu.zip memiliki password yang sama
chmod +x menu/*
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
rm -f /root/*.sh*

TEXT="-------------------------------
<b>   ⚠️NOTIF UPDATE SCRIPT⚠️</b>
<b>     Update Script Sukses</b>
-------------------------------
<b>IP VPS  :</b> ${MYIP}
<b>DOMAIN  :</b> ${domain}
<b>VERSI   :</b> ${serverV}
-------------------------------
"
curl -s --max-time $TIME -d "chat_id=$CHATID&disable_web_page_preview=1&text=$TEXT&parse_mode=html" $URL >/dev/null

echo -e " [INFO] File download and setup completed successfully. Version: $serverV!"
exit
