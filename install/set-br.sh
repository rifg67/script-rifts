#!/bin/bash
BASEDIR="${BASEDIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
REPO="${BASEDIR}/"
apt install rclone
printf "q\n" | rclone config
cp -f "${REPO}install/rclone.conf" /root/.config/rclone/rclone.conf
git clone  https://github.com/casper9/wondershaper.git
cd wondershaper
make install
cd
rm -rf wondershaper
cp -f "${REPO}install/limit.sh" limit.sh && chmod +x limit.sh && ./limit.sh

rm -f /root/set-br.sh
rm -f /root/limit.sh
