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

curl -fsSL "$REPO/e.sh" -o e.sh
curl -fsSL "$REPO/d.sh" -o d.sh
curl -fsSL "$REPO/models.txt" -o models.txt
curl -fsSL "$REPO/devices.txt" -o devices.txt

chmod +x e.sh d.sh

# # Nahrádza celé bloky s aliasmi
PREFIX=${PREFIX:-/data/data/com.termux/files/usr}
mkdir -p "$PREFIX/bin"

for name in o d; do
  target="$HOME/${name}.sh"
  wrapper="$PREFIX/bin/$name"
  cat > "$wrapper" <<EOF
#!/data/data/com.termux/files/usr/bin/bash
exec bash "$target" "\$@"
EOF
  chmod +x "$wrapper"
done
echo -e "\e[32m✅ Installation completed. Use commands: o | d\e[0m"
exit
