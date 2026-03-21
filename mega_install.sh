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
  update-alternatives \
  software-properties-common \
  lsb-release \
  unzip \
  zip \
  tar \
  python3-pip

echo "=== Setting default terminal emulator ==="
update-alternatives --set x-terminal-emulator /usr/bin/xfce4-terminal.wrapper || true

# =========================
# VS CODE
# =========================
echo "=== Installing VS Code ==="
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
install -o root -g root -m 644 microsoft.gpg /usr/share/keyrings/
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list
apt update
apt install -y code
rm microsoft.gpg

# =========================
# NODE + CLAUDE
# =========================
echo "=== Installing Node.js ==="
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt install -y nodejs

echo "=== Installing Claude Code CLI ==="
npm install -g @anthropic-ai/claude-code --unsafe-perm || true

# =========================
# PYTHON 3.10 (ROS FIX)
# =========================
echo "=== Installing Python 3.10 ==="
apt install -y python3.10 python3.10-venv python3.10-distutils

# =========================
# ROS 2 HUMBLE
# =========================
echo "=== Installing ROS 2 Humble ==="
add-apt-repository universe -y

curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc \
  | gpg --dearmor -o /usr/share/keyrings/ros-archive-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] \
http://packages.ros.org/ros2/ubuntu $(lsb_release -cs) main" \
> /etc/apt/sources.list.d/ros2.list

apt update

apt install -y \
  ros-humble-desktop \
  ros-humble-rclpy \
  ros-dev-tools

# =========================
# FORCE PYTHON 3.10 FOR ROS
# =========================
echo "=== Fixing ROS Python mismatch ==="
echo 'export PYTHONPATH=/opt/ros/humble/lib/python3.10/site-packages' >> ~/.bashrc
echo 'export LD_LIBRARY_PATH=/opt/ros/humble/lib:$LD_LIBRARY_PATH' >> ~/.bashrc
echo 'export PATH=/usr/bin/python3.10:$PATH' >> ~/.bashrc

# =========================
# GAZEBO
# =========================
echo "=== Installing Gazebo ==="
apt install -y gazebo ros-humble-gazebo-ros-pkgs

# =========================
# MUJOCO
# =========================
echo "=== Installing MuJoCo ==="
apt install -y libglfw3 libglew2.2 libosmesa6
pip install mujoco

# =========================
# RENDERING / OPENGL
# =========================
echo "=== Installing OpenGL dependencies ==="
apt install -y \
  mesa-utils \
  libgl1-mesa-dri \
  libgl1-mesa-glx \
  libegl1 \
  libxrender1 \
  libxext6 \
  libsm6

# =========================
# VNC SETUP
# =========================
echo "=== Initializing VNC (set password when prompted) ==="
vncserver || true

echo "=== Stopping any existing VNC session ==="
vncserver -kill :1 || true

echo "=== Configuring VNC startup (XFCE desktop) ==="
cat > ~/.vnc/xstartup << 'EOFX'
#!/bin/bash
xrdb $HOME/.Xresources
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
export XKL_XMODMAP_DISABLE=1
startxfce4 &
EOFX

chmod +x ~/.vnc/xstartup

echo "=== Starting VNC server with high resolution ==="
vncserver :1 -geometry 1920x1080 -depth 24

echo "=== Verifying VNC is listening ==="
ss -tulpn | grep 5901 || true

# =========================
# ISAAC SIM (Quick Install x86_64)
# =========================
echo "=== Installing NVIDIA Isaac Sim (x86_64 standalone) ==="
ISAAC_DIR=/opt/isaac-sim
mkdir -p $ISAAC_DIR
cd $ISAAC_DIR

echo "Downloading Isaac Sim (5.1.0 standalone x86_64)..."
wget -O isaac-sim-5.1.0-linux-x86_64.zip https://download.isaacsim.omniverse.nvidia.com/isaac-sim-standalone-5.1.0-linux-x86_64.zip

echo "Extracting Isaac Sim..."
unzip isaac-sim-5.1.0-linux-x86_64.zip -d $ISAAC_DIR
rm isaac-sim-5.1.0-linux-x86_64.zip

echo "Running post-install script..."
cd $ISAAC_DIR/isaac-sim-standalone@*
./post_install.sh || true

echo "=== Setup complete ==="
echo ""
echo "Next steps:"
echo "- Connect VNC: <ip>:5901"
echo "- Run: source /opt/ros/humble/setup.bash"
echo "- Test ROS2: ros2 --help"
echo "- Launch Gazebo: gazebo"
echo "- Launch RViz: rviz2"
echo "- Launch Isaac Sim: $ISAAC_DIR/isaac-sim-standalone@*/isaac-sim.selector.sh"