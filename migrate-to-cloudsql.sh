#!/bin/bash

# Prisma Migration Script for Cloud SQL PostgreSQL
# This script runs Prisma migrations to Cloud SQL from your local machine

set -e  # Exit on error

# Configuration - UPDATE THESE VALUES
INSTANCE_NAME="test-postgresql"
DATABASE_NAME="testserver"
DB_USER="zinpainghtet"  # Update with your database username
DB_PASSWORD=""  # Will be prompted if not set
PROJECT_ID="new-react-project-483118"  # Update if different

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Prisma Migration to Cloud SQL${NC}"
echo "================================"
echo ""

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo -e "${RED}❌ Error: gcloud CLI is not installed${NC}"
    echo "📥 Install from: https://cloud.google.com/sdk/docs/install"
    exit 1
fi

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo -e "${RED}❌ Error: Node.js is not installed${NC}"
    exit 1
fi

# Check if logged in to gcloud
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
    echo -e "${YELLOW}🔐 Not logged in to gcloud. Please login...${NC}"
    gcloud auth login
fi

# Set project
echo -e "${BLUE}📁 Setting project to: ${PROJECT_ID}${NC}"
gcloud config set project ${PROJECT_ID} --quiet

# Check if instance exists
echo -e "${BLUE}🔍 Checking Cloud SQL instance...${NC}"
if ! gcloud sql instances describe ${INSTANCE_NAME} &> /dev/null; then
    echo -e "${RED}❌ Error: Cloud SQL instance '${INSTANCE_NAME}' not found${NC}"
    echo "Available instances:"
    gcloud sql instances list
    exit 1
fi

# Get instance state
INSTANCE_STATE=$(gcloud sql instances describe ${INSTANCE_NAME} --format="value(state)")
if [ "$INSTANCE_STATE" != "RUNNABLE" ]; then
    echo -e "${YELLOW}⚠️  Instance state: ${INSTANCE_STATE}${NC}"
    echo "Waiting for instance to be ready..."
    # Wait up to 2 minutes for instance to be ready
    for i in {1..12}; do
        sleep 10
        INSTANCE_STATE=$(gcloud sql instances describe ${INSTANCE_NAME} --format="value(state)")
        if [ "$INSTANCE_STATE" == "RUNNABLE" ]; then
            break
        fi
        echo "   Still waiting... ($i/12)"
    done
fi

# Get public IP
echo -e "${BLUE}📡 Getting Cloud SQL public IP...${NC}"
PUBLIC_IP=$(gcloud sql instances describe ${INSTANCE_NAME} \
  --format="value(ipAddresses[0].ipAddress)" 2>/dev/null || echo "")

if [ -z "$PUBLIC_IP" ]; then
    echo -e "${RED}❌ Error: Could not get public IP for instance${NC}"
    echo "Make sure the instance has a public IP enabled"
    exit 1
fi

echo -e "${GREEN}✅ Cloud SQL IP: ${PUBLIC_IP}${NC}"

# Get local IP and authorize
echo -e "${BLUE}🔐 Authorizing local IP address...${NC}"
MY_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s ipinfo.io/ip 2>/dev/null || echo "")
if [ -z "$MY_IP" ]; then
    echo -e "${YELLOW}⚠️  Could not automatically detect IP. Please enter it manually:${NC}"
    read -p "Enter your public IP address: " MY_IP
fi

echo -e "${BLUE}   Your IP: ${MY_IP}${NC}"

# Check if IP is already authorized
AUTHORIZED_NETWORKS=$(gcloud sql instances describe ${INSTANCE_NAME} \
  --format="value(settings.ipConfiguration.authorizedNetworks)" 2>/dev/null || echo "")

if echo "$AUTHORIZED_NETWORKS" | grep -q "$MY_IP"; then
    echo -e "${GREEN}✅ IP already authorized${NC}"
else
    echo "   Authorizing IP..."
    gcloud sql instances patch ${INSTANCE_NAME} \
      --authorized-networks=${MY_IP}/32 \
      --quiet
    echo -e "${GREEN}✅ IP authorized${NC}"
fi

# Prompt for database password if not set
if [ -z "$DB_PASSWORD" ]; then
    echo ""
    read -sp "🔑 Enter database password for user '${DB_USER}': " DB_PASSWORD
    echo ""
    if [ -z "$DB_PASSWORD" ]; then
        echo -e "${RED}❌ Error: Password is required${NC}"
        exit 1
    fi
fi

# Check if database exists
echo -e "${BLUE}💾 Checking database '${DATABASE_NAME}'...${NC}"
if ! gcloud sql databases describe ${DATABASE_NAME} --instance=${INSTANCE_NAME} &> /dev/null; then
    echo -e "${YELLOW}⚠️  Database '${DATABASE_NAME}' not found. Creating...${NC}"
    gcloud sql databases create ${DATABASE_NAME} --instance=${INSTANCE_NAME} --quiet
    echo -e "${GREEN}✅ Database created${NC}"
else
    echo -e "${GREEN}✅ Database exists${NC}"
fi

# Check if node_modules exists
if [ ! -d "node_modules" ]; then
    echo -e "${BLUE}📦 Installing dependencies...${NC}"
    npm install
fi

# URL encode password and user (to handle special characters like @, :, etc.)
ENCODED_PASSWORD=$(python3 -c "import urllib.parse, sys; print(urllib.parse.quote(sys.argv[1], safe=''))" "$DB_PASSWORD")
ENCODED_USER=$(python3 -c "import urllib.parse, sys; print(urllib.parse.quote(sys.argv[1], safe=''))" "$DB_USER")

# Set DATABASE_URL (use sslmode=no-verify for Cloud SQL public IP connections)
export DATABASE_URL="postgresql://${ENCODED_USER}:${ENCODED_PASSWORD}@${PUBLIC_IP}:5432/${DATABASE_NAME}?sslmode=no-verify"

# Generate Prisma Client
echo -e "${BLUE}🔨 Generating Prisma Client...${NC}"
npx prisma generate

# Run migrations
echo ""
echo -e "${BLUE}🚀 Running Prisma migrations...${NC}"
echo "=================================="
npx prisma migrate deploy

echo ""
echo -e "${GREEN}✅ Migrations completed successfully!${NC}"
echo ""
echo -e "${BLUE}📋 Connection Details:${NC}"
echo "================================"
echo "Instance: ${INSTANCE_NAME}"
echo "Database: ${DATABASE_NAME}"
echo "User: ${DB_USER}"
echo "Host: ${PUBLIC_IP}"
echo ""
echo -e "${YELLOW}⚠️  Next Steps:${NC}"
echo "1. Update your Cloud Run service to use Cloud SQL connection"
echo "2. Update DATABASE_URL in GitHub Secrets for CI/CD"
echo "3. (Optional) Remove authorized IP for security:"
echo "   gcloud sql instances patch ${INSTANCE_NAME} --clear-authorized-networks"
echo ""
