#!/usr/bin/env bash
set -euo pipefail

echo "=== Updating Ubuntu ==="
sudo apt update

echo "=== Installing prerequisites ==="
sudo apt install -y \
    ca-certificates \
    curl \
    git \
    unzip \
    python3 \
    python3-pip \
    python3-venv

echo "=== Removing conflicting Docker packages ==="
sudo apt remove -y \
    docker.io \
    docker-doc \
    docker-compose \
    docker-compose-v2 \
    docker-buildx \
    podman-docker \
    containerd \
    runc 2>/dev/null || true

echo "=== Adding Docker official GPG key ==="
sudo install -m 0755 -d /etc/apt/keyrings

sudo curl -fsSL \
    https://download.docker.com/linux/ubuntu/gpg \
    -o /etc/apt/keyrings/docker.asc

sudo chmod a+r /etc/apt/keyrings/docker.asc

echo "=== Adding Docker official repository ==="

echo \
"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
https://download.docker.com/linux/ubuntu \
$(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

echo "=== Updating package index ==="
sudo apt update

echo "=== Installing Docker Engine ==="
sudo apt install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

echo "=== Starting Docker ==="
sudo systemctl enable --now docker

echo "=== Adding $USER to docker group ==="
sudo usermod -aG docker "$USER"

echo ""
echo "========================================"
echo " SecureBank Development Environment"
echo " Installation Complete"
echo "========================================"
echo ""

echo "Python:"
python3 --version

echo ""
echo "Git:"
git --version

echo ""
echo "Docker:"
sudo docker --version

echo ""
echo "Docker Compose:"
sudo docker compose version

echo ""
echo "IMPORTANT:"
echo "Run the following command now:"
echo ""
echo "    newgrp docker"
echo ""
echo "Then test:"
echo ""
echo "    docker ps"
echo "    docker run hello-world"
