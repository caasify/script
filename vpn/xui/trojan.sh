#!/bin/bash
# Xray-core Trojan TCP NoTLS installation script for Ubuntu 24.04
# Usage: bash vpn.sh <password> <alias>

set -e

PASSWORD="$1"
ALIAS="$2"

# === Fixed settings ===
PORT="443"

# === Variables ===
XRAY_DIR="/usr/local/bin"
CONFIG_DIR="/etc/xray"
CONFIG_FILE="$CONFIG_DIR/config.json"
LINK_FILE="/etc/trojan_link.txt"

# === Update system ===
apt update -y
apt install -y curl unzip jq qrencode

# === Download and install Xray-core ===
mkdir -p /tmp/xray
cd /tmp/xray
curl -L -o xray.zip https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip
unzip -o xray.zip
install -m 755 xray "$XRAY_DIR/xray"

# === Setup directories ===
mkdir -p "$CONFIG_DIR"

# === Write config ===
cat > "$CONFIG_FILE" <<EOF
{
  "log": {
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "tag": "TROJAN TCP NOTLS",
      "listen": "0.0.0.0",
      "port": $PORT,
      "protocol": "trojan",
      "settings": {
        "clients": [
          {
            "password": "$PASSWORD",
            "email": "$ALIAS"
          }
        ]
      },
      "streamSettings": {
        "network": "tcp",
        "security": "none"
      },
      "sniffing": {
        "enabled": true,
        "destOverride": ["http","tls","quic"]
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "tag": "DIRECT"
    },
    {
      "protocol": "blackhole",
      "tag": "BLOCK"
    }
  ]
}
EOF

# === Create Trojan link ===
SERVER_IP=$(curl -s https://api.ipify.org)
TROJAN_LINK="trojan://${PASSWORD}@${SERVER_IP}:${PORT}?security=none&type=tcp&headerType=&path=&host=#${ALIAS}"
echo "$TROJAN_LINK" > "$LINK_FILE"

# === Create systemd service ===
cat > /etc/systemd/system/xray.service <<EOF
[Unit]
Description=Xray Service
After=network.target

[Service]
ExecStart=$XRAY_DIR/xray run -config $CONFIG_FILE
Restart=on-failure
User=nobody
NoNewPrivileges=true
CapabilityBoundingSet=CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_BIND_SERVICE

[Install]
WantedBy=multi-user.target
EOF

# === Enable and start service ===
systemctl daemon-reexec
systemctl enable --now xray.service

# === Create SSH login tutorial ===
cat > /etc/profile.d/trojan.sh <<EOF
#!/bin/bash
clear
LINK_FILE="/etc/trojan_link.txt"
VPN_LINK=\$(cat \$LINK_FILE)

echo "===================================================="
echo "        🚀 Trojan VPN Connection Information        "
echo "===================================================="
echo ""
echo "\$VPN_LINK"
echo ""
qrencode -t ANSIUTF8 < \$LINK_FILE
echo ""
echo "===================================================="
echo " 📖 How to Connect"
echo "===================================================="
echo ""
echo "🖥️  Windows:"
echo "  1. Download Hiddify for Windows:"
echo "     https://github.com/hiddify/hiddify-app/releases/latest/download/Hiddify-Windows-Setup-x64.exe"
echo "  2. Open Hiddify → Add Subscription → Paste the link above."
echo "  3. Or scan the QR code directly."
echo ""
echo "🤖 Android:"
echo "  1. Install Hiddify from Google Play:"
echo "     https://play.google.com/store/apps/details?id=app.hiddify.com"
echo "  2. Add Subscription → Paste the link above or scan QR."
echo ""
echo "📱 iPhone (iOS):"
echo "  1. Install Hiddify from App Store:"
echo "     https://apps.apple.com/us/app/hiddify-proxy-vpn/id6596777532?platform=iphone"
echo "  2. Add Subscription → Paste the link above or scan QR."
echo ""
echo "🍏 MacOS:"
echo "  1. Download Hiddify for MacOS:"
echo "     https://github.com/hiddify/hiddify-app/releases/latest/download/Hiddify-MacOS.dmg"
echo "  2. Add Subscription → Paste the link above or scan QR."
echo ""
echo "🐧 Linux:"
echo "  1. Download Hiddify for Linux:"
echo "     https://github.com/hiddify/hiddify-app/releases/latest/download/Hiddify-Linux-x64.AppImage"
echo "  2. Add Subscription → Paste the link above or scan QR."
echo ""
echo "===================================================="
echo " 🎉 Installation finished. Enjoy your secure VPN!"
echo "===================================================="
EOF

chmod +x /etc/profile.d/trojan.sh

echo "✅ Installation completed successfully!"
echo "Your Trojan link: $TROJAN_LINK"
