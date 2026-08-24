#!/usr/bin/env bash
set -euo pipefail
sudo apt update
sudo apt install -y git curl unzip python3 python3-pip python3-venv docker.io docker-compose-plugin
sudo systemctl enable --now docker
sudo usermod -aG docker "$USER"
echo "Setup complete. Run: newgrp docker"
