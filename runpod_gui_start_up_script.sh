#!/bin/bash

set -e

echo "=== Setting environment ==="
export USER=root
export HOME=/root

echo "=== Updating packages ==="
apt update

echo "=== Installing base dependencies ==="
apt install -y \
  xfce4 \
  xfce4-goodies \
  xfce4-terminal \
  tightvncserver \
  dbus-x11 \
  xfonts-base \
  wget \
  gpg \
  curl \
  update-alternatives

echo "=== Setting default terminal emulator ==="
update-alternatives --set x-terminal-emulator /usr/bin/xfce4-terminal.wrapper || true

echo "=== Installing VS Code ==="
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
install -o root -g root -m 644 microsoft.gpg /usr/share/keyrings/
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list
apt update
apt install -y code
rm microsoft.gpg

echo "=== Installing Node.js ==="
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt install -y nodejs

echo "=== Installing Claude Code CLI ==="
npm install -g @anthropic-ai/claude-code --unsafe-perm || true

echo "=== Initializing VNC (set password when prompted) ==="
vncserver || true

echo "=== Stopping any existing VNC session ==="
vncserver -kill :1 || true

echo "=== Configuring VNC startup (XFCE desktop) ==="
cat > ~/.vnc/xstartup << 'EOF'
#!/bin/bash
xrdb $HOME/.Xresources
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
export XKL_XMODMAP_DISABLE=1
startxfce4 &
EOF

chmod +x ~/.vnc/xstartup

echo "=== Starting VNC server with high resolution ==="
vncserver :1 -geometry 1920x1080 -depth 24

echo "=== Verifying VNC is listening ==="
ss -tulpn | grep 5901 || true

echo "=== Setup complete ==="
echo ""
echo "Next steps:"
echo "- Ensure RunPod maps internal port 5901"
echo "- Connect using: <external_ip>:<external_port>"
echo "- Launch VS Code with: code --no-sandbox --user-data-dir=/root/.vscode"
echo "- Run Claude with: claude"