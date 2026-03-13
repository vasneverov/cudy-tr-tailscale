#!/bin/sh
# Tailscale installer for OpenWrt (WR3000S and compatible)
# https://github.com/vasneverov/cudy-tr-tailscale
#
# Usage:
#   wget -O /tmp/install.sh https://raw.githubusercontent.com/vasneverov/cudy-tr-tailscale/main/install.sh && sh /tmp/install.sh

set -e

echo "=== Tailscale installer for OpenWrt ==="

# Step 1: Clean duplicate repo entries
echo "[1/5] Cleaning duplicate repo entries..."
grep -v "openwrt-tailscale" /etc/opkg/customfeeds.conf > /tmp/feeds.tmp
mv /tmp/feeds.tmp /etc/opkg/customfeeds.conf

# Step 2: Add signing key
echo "[2/5] Adding signing key..."
wget -O /tmp/key-build.pub https://gunanovo.github.io/openwrt-tailscale/key-build.pub
opkg-key add /tmp/key-build.pub
rm /tmp/key-build.pub

# Step 3: Add repository (auto-detect architecture)
echo "[3/5] Adding repository..."
ARCH=$(opkg print-architecture | awk 'NF==3 && $3~/^[0-9]+$/ {print $2}' | tail -1)
echo "Detected architecture: $ARCH"
echo "src/gz openwrt-tailscale https://gunanovo.github.io/openwrt-tailscale/$ARCH" >> /etc/opkg/customfeeds.conf

# Step 4: Update and install
echo "[4/5] Installing Tailscale..."
opkg update
opkg install tailscale

# Step 5: Authorize and configure serve
echo "[5/5] Starting Tailscale..."
echo ""
echo ">>> Сейчас появится ссылка. Перейди по ней в браузере для авторизации. <<<"
echo ""
tailscale up --accept-dns=false --accept-routes --reset

tailscale serve --bg --tcp 80  tcp://localhost:80
tailscale serve --bg --tcp 443 tcp://localhost:443
tailscale serve --bg --tcp 22  tcp://localhost:22
tailscale serve status

# Step 6: Write autostart
printf '#!/bin/sh\n(sleep 10; tailscale serve --bg --tcp 80 tcp://localhost:80; tailscale serve --bg --tcp 22 tcp://localhost:22; tailscale serve --bg --tcp 443 tcp://localhost:443) &\nexit 0\n' > /etc/rc.local
chmod +x /etc/rc.local

echo ""
echo "=== Готово! Tailscale установлен и настроен. ==="
echo "=== После перезагрузки Tailscale поднимется автоматически через ~40 секунд. ==="
