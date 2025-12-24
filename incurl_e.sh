#!/bin/bash
set -e

# 🛠 Automatický mód
export DEBIAN_FRONTEND=noninteractive
export TERM=xterm

set -e

echo "📦 Updating Termux and installing dependencies..."
yes "" | pkg update -y
yes "" | pkg upgrade -y
echo N | dpkg --configure -a

pkg install -y python python2 git tsu curl
pip install wheel
pip install pycryptodome
pip3 install --upgrade requests pycryptodome git+https://github.com/R0rt1z2/realme-ota

echo "📥 Downloading scripts and data files..."
REPO="https://raw.githubusercontent.com/stanislawrabel/edo/main"

curl -sSL "$REPO e.sh" -o e.sh
curl -sSL "$REPO/models.txt" -o models.txt
curl -sSL "$REPO/devices.txt" -o devices.txt

chmod +x e.sh

# 🛠️ Adding an alias for easy launch 
if ! grep -q "alias e=" ~/.bashrc; then
    echo "alias e='bash ~/e.sh'" >> ~/.bashrc
    echo -e "\e[32m✅ Alias 'e' has been added.\e[0m"
fi
source ~/.bashrc
clear
exit
