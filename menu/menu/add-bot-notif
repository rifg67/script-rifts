#!/bin/bash
clear
red() { echo -e "\033[32;1m${*}\033[0m"; }
RED='\033[0;31m'
NC='\e[0m'
gray="\e[1;30m"
Blue="\033[1;36m"
GREEN='\033[0;32m'
grenbo="\e[92;1m"
YELL='\033[0;33m'
BGX="\033[42m"

yellow="\033[0;33m"
ungu="\033[0;35m"
Red="\033[91;1m"
Xark="\033[0m"
BlueCyan="\033[5;36m"
Cyan="\033[96;1m"
Purple="\033[95;1m"
Green="\033[92;1m"
WhiteBe="\033[5;37m"
GreenBe="\033[5;32m"
YellowBe="\033[5;33m"
BlueBe="\033[5;34m"
nama=$(cat /etc/xray/username)

function baris_panjang() {
  echo -e "${BlueCyan} ——————————————————————————————————— ${Xark} "
}

function Xwan_Banner() {
clear
baris_panjang
echo -e "${ungu}           $nama      ${Xark} "
baris_panjang
}

function Sc_Credit(){
sleep 1
baris_panjang
echo -e "${ungu}   Terimakasih Telah Menggunakan ${Xark}"
echo -e "${ungu}          Script Credit ${Xark}"
echo -e "${ungu}            $nama ${Xark}"
baris_panjang
exit 1
}

duration=6
frames=("██10%" "█████35%" "█████████65%" "█████████████80%" "█████████████████████90%" "█████████████████████████100%")
num_frames=${#frames[@]}
num_iterations=$((duration))

Loading_Animasi() {
    for ((i = 0; i < num_iterations; i++)); do
        clear
        index=$((i % num_frames))
        color_code=$((31 + i % 7))
        echo ""
        echo ""
        echo ""
        echo -e "\e[1;${color_code}m ${frames[$index]}\e[0m"
        sleep 0.5
    done
}

function Loading_Succes() {
clear
echo -e  "\033[5;32mSucces\033[0m"
sleep 1
clear
}

# === Fungsi Kirim Notifikasi ===
send_notif() {
    local message="$1"
    if [[ -f /etc/bot/.bot.db ]]; then
        while read -r line; do
            [[ -z "$line" ]] && continue
            token=$(echo "$line" | awk '{print $2}')
            admin=$(echo "$line" | awk '{print $3}')
            curl -s -X POST "https://api.telegram.org/bot${token}/sendMessage" \
                -d chat_id="${admin}" \
                -d text="${message}" >/dev/null 2>&1
        done < /etc/bot/.bot.db
    fi
}

send_notif_trx() {
    local message="$1"
    if [[ -f /etc/bottrx/.bottrx.db ]]; then
        while read -r line; do
            [[ -z "$line" ]] && continue
            token=$(echo "$line" | awk '{print $2}')
            admin=$(echo "$line" | awk '{print $3}')
            curl -s -X POST "https://api.telegram.org/bot${token}/sendMessage" \
                -d chat_id="${admin}" \
                -d text="${message}" >/dev/null 2>&1
        done < /etc/bottrx/.bottrx.db
    fi
}

# === MAIN MENU ===
Xwan_Banner
baris_panjang
echo ""
echo -e "${Purple}          PILIH OPSI BOT ${Xark} "
echo ""
baris_panjang
echo -e "${Green} 1.${NC} Add Bot Notifikasi"
echo -e "${Green} 2.${NC} Add BotTrx"
echo -e "${Green} 3.${NC} Hapus Bot Notifikasi"
echo -e "${Green} 4.${NC} Hapus BotTrx"
echo -e "${Green} 5.${NC} Hapus Semua Database"
baris_panjang
echo ""
read -rp "Pilih Opsi [1-5]: " opsi

case $opsi in
1)
    clear
    Xwan_Banner
    baris_panjang
    echo -e "${Purple}        ADD BOT NOTIFIKASI ${Xark} "
    baris_panjang
    read -rp "[*] Input Key Bot     : " -e bottoken 
    read -rp "[*] Input Id Tele     : " -e admin
    clear
    Loading_Animasi
    Loading_Succes

    mkdir -p /etc/bot
    echo "#bot# ${bottoken} ${admin}" >> /etc/bot/.bot.db

    # Kirim notif test
    send_notif "✅ Bot Notifikasi aktif!\nToken: ${bottoken}\nID: ${admin}"

    Xwan_Banner
    baris_panjang
    echo -e "${GreenBe} Succesfully Added Bot Notifikasi ${Xark}"
    echo -e "${yellow} Bot Token      : $bottoken ${Xark}"
    echo -e "${yellow} ID Telegram    : $admin ${Xark}"
    baris_panjang
    Sc_Credit
    ;;
2)
    clear
    Xwan_Banner
    baris_panjang
    echo -e "${Purple}        ADD BOT TRX ${Xark} "
    baris_panjang
    read -rp "[*] Input Key Bot     : " -e bottoken 
    read -rp "[*] Input Id Tele     : " -e admin
    clear
    Loading_Animasi
    Loading_Succes

    mkdir -p /etc/bottrx
    echo "#bottrx# ${bottoken} ${admin}" >> /etc/bottrx/.bottrx.db

    # Kirim notif test
    send_notif_trx "💰 Bot Transaksi aktif!\nToken: ${bottoken}\nID: ${admin}"

    Xwan_Banner
    baris_panjang
    echo -e "${GreenBe} Succesfully Added BotTrx ${Xark}"
    echo -e "${yellow} Bot Token      : $bottoken ${Xark}"
    echo -e "${yellow} ID Telegram    : $admin ${Xark}"
    baris_panjang
    Sc_Credit
    ;;
3)
    clear
    Xwan_Banner
    baris_panjang
    echo -e "${Purple}        HAPUS BOT NOTIFIKASI ${Xark} "
    baris_panjang
    Loading_Animasi
    if [[ -f /etc/bot/.bot.db ]]; then
        rm -f /etc/bot/.bot.db
        Loading_Succes
        echo -e "${GreenBe}File /etc/bot/.bot.db berhasil dihapus${Xark}"
    else
        Loading_Succes
        echo -e "${YELL}File /etc/bot/.bot.db tidak ada${Xark}"
    fi
    baris_panjang
    Sc_Credit
    ;;
4)
    clear
    Xwan_Banner
    baris_panjang
    echo -e "${Purple}        HAPUS BOT TRX ${Xark} "
    baris_panjang
    Loading_Animasi
    if [[ -f /etc/bottrx/.bottrx.db ]]; then
        rm -f /etc/bottrx/.bottrx.db
        Loading_Succes
        echo -e "${GreenBe}File Database berhasil dihapus${Xark}"
    else
        Loading_Succes
        echo -e "${YELL}File /etc/bottrx/.bottrx.db tidak ada${Xark}"
    fi
    baris_panjang
    Sc_Credit
    ;;
5)
    clear
    Xwan_Banner
    baris_panjang
    echo -e "${Purple}        HAPUS SEMUA DATA BOT ${Xark} "
    baris_panjang
    read -rp "[*] Yakin ingin menghapus file .bot.db dan .bottrx.db? (y/n) : " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        Loading_Animasi
        [[ -f /etc/bot/.bot.db ]] && rm -f /etc/bot/.bot.db && echo -e "${GreenBe}File /etc/bot/.bot.db berhasil dihapus${Xark}" || echo -e "${YELL}File /etc/bot/.bot.db tidak ada${Xark}"
        [[ -f /etc/bottrx/.bottrx.db ]] && rm -f /etc/bottrx/.bottrx.db && echo -e "${GreenBe}File /etc/bottrx/.bottrx.db berhasil dihapus${Xark}" || echo -e "${YELL}File /etc/bottrx/.bottrx.db tidak ada${Xark}"
        Loading_Succes
    else
        echo -e "${YELL}Proses dibatalkan${Xark}"
    fi
    baris_panjang
    Sc_Credit
    ;;
*)
    echo -e "${Red}Pilihan tidak valid!${NC}"
    exit 1
    ;;
esac
