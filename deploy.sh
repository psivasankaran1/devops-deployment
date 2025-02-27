#!/bin/bash

set -e  # Exit script on any error

echo "🚀 Starting Docker installation and application deployment..."

# Remove any existing Docker-related packages
echo "🔍 Removing old Docker versions..."
sudo yum remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine || true

# Install required dependencies
echo "📦 Installing prerequisites..."
sudo yum install -y yum-utils device-mapper-persistent-data lvm2

# Add Docker repository
echo "🔑 Adding Docker repository..."
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

# Install Docker
echo "🐳 Installing Docker..."
sudo yum install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Start and enable Docker service
echo "⚙️ Enabling and starting Docker..."
sudo systemctl enable --now docker

# Add current user to Docker group
echo "👤 Adding user to Docker group..."
sudo groupadd docker || true
sudo usermod -aG docker $USER
newgrp docker

# Ensure Docker service is running
if ! systemctl is-active --quiet docker; then
    echo "⚠️ Docker is not running. Attempting to start..."
    sudo systemctl start docker
fi

# Define variables
CONTAINER_NAME="react_app"
IMAGE_NAME="prabakaran90/devops-app-dev:latest"

# Pull the latest image
echo "�� Pulling the latest image: $IMAGE_NAME"
docker pull $IMAGE_NAME

# Stop and remove any existing container
if docker ps -a --format '{{.Names}}' | grep -q "^$CONTAINER_NAME$"; then
    echo "🛑 Stopping and removing existing container: $CONTAINER_NAME"
    docker stop $CONTAINER_NAME
    docker rm $CONTAINER_NAME
fi

# Run the new container
echo "�� Running new container: $CONTAINER_NAME"
docker run -d --name $CONTAINER_NAME -p 80:80 --restart unless-stopped $IMAGE_NAME

if [ $? -eq 0 ]; then
    echo "✅ Application successfully deployed and running on port 80"
else
    echo "❌ Failed to start the container. Check logs using: docker logs $CONTAINER_NAME"
    exit 1
fi
