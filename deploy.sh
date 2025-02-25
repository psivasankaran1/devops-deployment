#!/bin/bash

# Install Docker 
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do 
    sudo apt-get remove -y $pkg 
done

# Add Docker's official GPG key
sudo apt-get update
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo tee /etc/apt/keyrings/docker.asc > /dev/null
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update

# Install the Docker packages
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Post-installation steps
sudo groupadd docker 2>/dev/null || true
sudo usermod -aG docker $USER
echo "Please log out and log back in to use Docker without sudo."

# Restart Docker service
sudo systemctl enable docker
sudo systemctl start docker

# Define variables
CONTAINER_NAME="react_app"
IMAGE_NAME="prabakaran90/devops-app-dev:latest"

# Ensure Docker service is running
if ! systemctl is-active --quiet docker; then
    echo "Docker is not running. Starting Docker..."
    sudo systemctl start docker
fi

# Pull the latest image
echo "Pulling the latest image: $IMAGE_NAME"
docker pull $IMAGE_NAME

# Stop and remove any existing container
if docker ps -a --format '{{.Names}}' | grep -q "^$CONTAINER_NAME$"; then
    echo "Stopping and removing existing container: $CONTAINER_NAME"
    docker stop $CONTAINER_NAME
    docker rm $CONTAINER_NAME
fi

# Run the new container
echo "Running new container: $CONTAINER_NAME"
docker run -d --name $CONTAINER_NAME -p 80:80 $IMAGE_NAME

if [ $? -eq 0 ]; then
    echo "Application deployed and running on port 80"
else
    echo "Failed to start the container. Check logs with 'docker logs $CONTAINER_NAME'"
fi
