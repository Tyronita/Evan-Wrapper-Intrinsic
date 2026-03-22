#!/bin/bash
# AIC Competition - WSL2 Full Setup Script
# Run this in your WSL2 terminal: bash /mnt/c/Users/evano/Desktop/robotics-learning/AIC_Competition/wsl_setup.sh
set -e

echo "=========================================="
echo "  AIC WSL2 Setup — $(date)"
echo "=========================================="

# ── 1. Docker Engine CE ───────────────────────
echo ""
echo "[1/6] Installing Docker Engine CE..."
if command -v docker &>/dev/null && docker info &>/dev/null 2>&1; then
  echo "  Docker already running — skipping install"
else
  sudo apt-get update -q
  sudo apt-get install -y -q ca-certificates curl gnupg lsb-release
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  sudo chmod a+r /etc/apt/keyrings/docker.gpg
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
    https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo apt-get update -q
  sudo apt-get install -y -q docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  sudo usermod -aG docker "$USER"
  echo "  Docker CE installed"
fi

# ── 2. Start Docker daemon ────────────────────
echo ""
echo "[2/6] Starting Docker daemon..."
if ! sudo systemctl is-active docker &>/dev/null; then
  sudo systemctl enable docker
  sudo systemctl start docker
  sleep 3
fi
echo "  Docker daemon: $(sudo systemctl is-active docker)"

# ── 3. NVIDIA Container Toolkit ──────────────
echo ""
echo "[3/6] Installing NVIDIA Container Toolkit..."
if command -v nvidia-ctk &>/dev/null; then
  echo "  nvidia-ctk already installed — skipping"
else
  curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
  curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
  sudo apt-get update -q
  sudo apt-get install -y -q nvidia-container-toolkit
  sudo nvidia-ctk runtime configure --runtime=docker
  sudo systemctl restart docker
  sleep 3
  echo "  NVIDIA Container Toolkit installed"
fi

# ── 4. Verify GPU in Docker ───────────────────
echo ""
echo "[4/6] Verifying GPU passthrough..."
sudo docker run --rm --gpus all nvidia/cuda:12.2.0-base-ubuntu22.04 nvidia-smi 2>&1 | grep -E "RTX|Tesla|A100|GPU|Driver" || \
  echo "  WARNING: GPU test failed — check NVIDIA drivers"

# ── 5. Pixi ───────────────────────────────────
echo ""
echo "[5/6] Installing Pixi..."
if command -v pixi &>/dev/null; then
  echo "  Pixi already installed: $(pixi --version)"
else
  curl -fsSL https://pixi.sh/install.sh | bash
  export PATH="$HOME/.pixi/bin:$PATH"
  echo "  Pixi installed: $(pixi --version)"
fi

# ── 6. Clone project & pixi install ──────────
echo ""
echo "[6/6] Setting up project..."
mkdir -p ~/projects
if [ ! -d ~/projects/Project-Automaton ]; then
  echo "  Cloning Project-Automaton..."
  git clone https://github.com/Ice-Citron/Project-Automaton.git ~/projects/Project-Automaton
  cd ~/projects/Project-Automaton
  git submodule update --init --recursive
else
  echo "  Project-Automaton already cloned — pulling latest..."
  cd ~/projects/Project-Automaton
  git pull
  git submodule update --recursive
fi

echo ""
echo "  Running pixi install in AIC workspace (this takes ~5-10 min first time)..."
cd ~/projects/Project-Automaton/References/aic
export PATH="$HOME/.pixi/bin:$PATH"
pixi install --locked

# ── Bash aliases ──────────────────────────────
echo ""
echo "Adding bash aliases..."
if ! grep -q 'alias automaton=' ~/.bashrc 2>/dev/null; then
cat >> ~/.bashrc << 'ALIASES'

# Project Automaton aliases
alias automaton="cd ~/projects/Project-Automaton"
alias aic="cd ~/projects/Project-Automaton/References/aic"
alias mujoco="source ~/envs/mujoco/bin/activate"
ALIASES
  echo "  Aliases added to ~/.bashrc"
else
  echo "  Aliases already in ~/.bashrc"
fi

# ── Pull AIC eval image ───────────────────────
echo ""
echo "Pulling AIC eval Docker image (may take a while)..."
sudo docker pull ghcr.io/intrinsic-dev/aic/aic_eval:latest

# ── Done ──────────────────────────────────────
echo ""
echo "=========================================="
echo "  SETUP COMPLETE"
echo "=========================================="
echo ""
echo "IMPORTANT: Run 'newgrp docker' or log out/in to use Docker without sudo"
echo ""
echo "Quick test:"
echo "  source ~/.bashrc"
echo "  aic"
echo "  pixi run ros2 topic list"
echo ""
echo "To run AIC (two WSL2 terminals):"
echo ""
echo "  Terminal 1 (eval sim):"
echo '  docker run -it --rm --name aic_eval --network host --gpus all \'
echo '    -e GALLIUM_DRIVER=d3d12 -e LD_LIBRARY_PATH=/usr/lib/wsl/lib \'
echo '    -v ~/projects/Project-Automaton/aic_results:/aic_results \'
echo '    -e AIC_RESULTS_DIR=/aic_results \'
echo '    ghcr.io/intrinsic-dev/aic/aic_eval:latest \'
echo '    ground_truth:=false start_aic_engine:=true'
echo ""
echo "  Terminal 2 (policy — wait for Zenoh retrying message first):"
echo '  cd ~/projects/Project-Automaton/References/aic'
echo '  pixi run ros2 run aic_model aic_model \'
echo '    --ros-args -p use_sim_time:=true -p policy:=aic_example_policies.ros.WaveArm'
