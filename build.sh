#!/bin/bash

# Define variables
IMAGE_NAME="prabakaran90/devops-build"
TAG="latest"

# Build Docker image
docker build -t $IMAGE_NAME:$TAG .

# Push to Docker Hub (Only for dev)
docker push $IMAGE_NAME:$TAG

echo "Docker image pushed: $IMAGE_NAME:$TAG"

