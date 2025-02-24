#!/bin/bash

# Define variables
CONTAINER_NAME="react_app"
IMAGE_NAME="prabakaran90/devops-build:latest"

# Stop and remove any existing container
docker stop $CONTAINER_NAME 2>/dev/null
docker rm $CONTAINER_NAME 2>/dev/null

# Run new container
docker run -d --name $CONTAINER_NAME -p 80:80 $IMAGE_NAME

echo "Application deployed and running on port 80"
