#!/usr/bin/env bash
set -e

echo "=== Updating Ubuntu ==="
sudo apt update

echo "=== Installing basic tools ==="
sudo apt install -y \
    git \
    curl \
    unzip \
    python3 \
    python3-pip \
    python3-venv \
    ca-certificates

echo "=== Removing conflicting Docker packages ==="
sudo apt remove -y \
    docker.io \
    docker-compose \
    docker-compose-v2 \
    docker-doc \
    docker-buildx \
    podman-docker \
    containerd \
    runc 2>/dev/null || true

echo "=== Adding Docker official repository ==="
sudo install -m 0755 -d /etc/apt/keyrings

sudo curl -fsSL \
    https://download.docker.com/linux/ubuntu/gpg \
    -o /etc/apt/keyrings/docker.asc

sudo chmod a+r /etc/apt/keyrings/docker.asc

sudo tee /etc/apt/sources.list.d/docker.sources > /dev/null <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: resolute
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF

echo "=== Updating package index ==="
sudo apt update

echo "=== Installing Docker Engine ==="
sudo apt install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

echo "=== Configuring Docker service ==="

if command -v systemctl >/dev/null 2>&1 && systemctl is-system-running >/dev/null 2>&1; then
    sudo systemctl enable --now docker
else
    echo "WARNING: systemd is not currently running."
    echo "Docker was installed, but the Docker service could not be started automatically."
    echo "Enable systemd in WSL and restart WSL before continuing."
fi

echo "=== Adding current user to docker group ==="
sudo usermod -aG docker "$USER"

echo ""
echo "======================================"
echo "Installation completed"
echo "======================================"
echo ""

echo "Python:"
python3 --version

echo ""
echo "Git:"
git --version

echo ""
echo "Docker:"
docker --version || true

echo ""
echo "Docker Compose:"
docker compose version || true

echo ""
echo "Docker service:"
sudo systemctl status docker --no-pager 2>/dev/null || true

echo ""
echo "IMPORTANT:"
echo "Run 'newgrp docker' or close/reopen this WSL terminal"
echo "before running Docker without sudo."

echo ""
echo "Then test with:"
echo "  docker ps"
echo "  docker run hello-world"
