#!/bin/bash

# Variables
DOCKER_COMPOSE_VERSION="1.29.2"
DOCKER_USER="kg97"
DOCKER_IMAGE="saleor-storefront"
API_URL="https://admin.terrisdraheim.com/graphql/"
STORE_URL="http://198.211.108.107:3000/"
NODE_ENV="development"
LIB_FOLDER="/var/lib/saleor"

# Check if running as root (for installation purposes)
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (use sudo)"
  exit
fi

# Step 1: Install Docker
if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    apt update -y
    apt install -y apt-transport-https ca-certificates curl software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    apt update -y
    apt install -y docker-ce
    systemctl start docker
fi

# Step 2: Install Docker Compose
if ! command -v docker-compose &> /dev/null; then
    echo "Installing Docker Compose..."
    curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
fi

# Step 3: Create project directory structure
echo "Setting up directories..."
mkdir -p "$LIB_FOLDER/saleor-storefront"
cd "$LIB_FOLDER/saleor-storefront"

# Step 4: Create .env file
echo "Creating .env file..."
cat <<EOF >.env
NEXT_PUBLIC_SALEOR_API_URL=${API_URL}
NEXT_PUBLIC_STOREFRONT_URL=${STORE_URL}
NODE_ENV=${NODE_ENV}
EOF

# Step 5: Create docker-compose.yml
echo "Creating docker-compose.yml..."
cat <<EOF >docker-compose.yml
version: '3.8'

services:
  saleor-storefront:
    image: ${DOCKER_USER}/${DOCKER_IMAGE}:latest
    container_name: saleor-storefront
    environment:
      - NEXT_PUBLIC_SALEOR_API_URL=${API_URL}
      - NEXT_PUBLIC_STOREFRONT_URL=${STORE_URL}
      - NODE_ENV=\${NODE_ENV}
    expose:
      - "3000"
    networks:
      - saleor_network

  nginx:
    container_name: nginx
    build:
      context: .
      dockerfile: Dockerfile
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
    ports:
      - "3000:3000"
    depends_on:
      - saleor-storefront
    networks:
      - saleor_network

networks:
  saleor_network:
    driver: bridge
EOF

cat <<EOF >Dockerfile
FROM nginx
COPY nginx.conf /etc/nginx/nginx.conf
EOF

# Step 6: Create Nginx configuration
echo "Creating nginx.conf..."
cat <<EOF >nginx.conf
events { }

http {
    upstream saleor_storefront {
        server saleor-storefront:3000;
    }

    server {
        listen 3000;

        location / {
            proxy_pass http://saleor_storefront;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
        }
    }
}
EOF

# Step 7: Pull images and start services
echo "Pulling images and starting services..."
echo "dckr_pat_o610SdSucjGSc0lNBOoTAXovoTg" | docker login -u kg97 --password-stdin
docker-compose --project-directory . down --remove-orphans
docker-compose pull
docker-compose up -d --build

echo "Saleor Storefront and Nginx have been set up and started."
