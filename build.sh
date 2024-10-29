#!/bin/bash

# Define variables
DOCKER_IMAGE_NAME="kg97/saleor-storefront"
DOCKER_IMAGE_TAG="latest"
DOCKER_REPO="$DOCKER_IMAGE_NAME:$DOCKER_IMAGE_TAG"

docker build -t $DOCKER_REPO \
  --build-arg NEXT_PUBLIC_SALEOR_API_URL=$(grep NEXT_PUBLIC_SALEOR_API_URL .env.docker | cut -d '=' -f2) \
  --build-arg NEXT_PUBLIC_STOREFRONT_URL=$(grep NEXT_PUBLIC_STOREFRONT_URL .env.docker | cut -d '=' -f2) \
  --build-arg NODE_ENV=$(grep NODE_ENV .env.docker | cut -d '=' -f2) .

echo "Logging into Docker Hub..."
docker login

docker push $DOCKER_REPO


echo "Image pushed to $DOCKER_REPO"

scp -i ~/.ssh/karoly-gergely-GitHub vps_install.sh root@198.211.108.107:/var/lib/saleor/vps_install_fe.sh && echo "Pushed deploy script to VPS instance."
