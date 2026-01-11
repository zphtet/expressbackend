#!/bin/bash

# Cloud SQL PostgreSQL Setup Script
# Usage: ./setup-cloudsql.sh

set -e

PROJECT_ID="new-react-project-483118"
INSTANCE_NAME="express-backend-db"
DATABASE_NAME="testserver"
DB_USER="zinpainghtet"
REGION="us-central1"

echo "🚀 Cloud SQL PostgreSQL Setup"
echo "=============================="
echo ""

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo "❌ Error: gcloud CLI is not installed"
    echo "📥 Install from: https://cloud.google.com/sdk/docs/install"
    exit 1
fi

# Check if logged in
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
    echo "🔐 Not logged in. Please login first..."
    gcloud auth login
fi

# Set project
echo "📁 Setting project to: ${PROJECT_ID}"
gcloud config set project ${PROJECT_ID}

# Enable SQL Admin API
echo "🔌 Enabling Cloud SQL Admin API..."
gcloud services enable sqladmin.googleapis.com

# Prompt for root password
echo ""
read -sp "🔑 Enter root password for Cloud SQL instance: " ROOT_PASSWORD
echo ""
read -sp "🔑 Enter password for database user '${DB_USER}': " DB_PASSWORD
echo ""

# Check if instance exists
if gcloud sql instances describe ${INSTANCE_NAME} &> /dev/null; then
    echo "⚠️  Instance '${INSTANCE_NAME}' already exists. Skipping creation."
else
    echo "📦 Creating Cloud SQL instance..."
    gcloud sql instances create ${INSTANCE_NAME} \
        --database-version=POSTGRES_15 \
        --tier=db-f1-micro \
        --region=${REGION} \
        --root-password=${ROOT_PASSWORD} \
        --storage-type=SSD \
        --storage-size=20GB \
        --storage-auto-increase \
        --backup \
        --quiet
    
    echo "✅ Instance created successfully!"
    echo "⏱️  Waiting for instance to be ready (this may take a few minutes)..."
    
    # Wait for instance to be ready
    while ! gcloud sql instances describe ${INSTANCE_NAME} --format="value(state)" | grep -q "RUNNABLE"; do
        echo "   Still starting..."
        sleep 10
    done
    echo "✅ Instance is ready!"
fi

# Get connection name
CONNECTION_NAME=$(gcloud sql instances describe ${INSTANCE_NAME} --format="value(connectionName)")
echo ""
echo "📋 Connection Name: ${CONNECTION_NAME}"

# Create database
echo ""
echo "💾 Creating database '${DATABASE_NAME}'..."
if gcloud sql databases describe ${DATABASE_NAME} --instance=${INSTANCE_NAME} &> /dev/null; then
    echo "⚠️  Database '${DATABASE_NAME}' already exists. Skipping creation."
else
    gcloud sql databases create ${DATABASE_NAME} --instance=${INSTANCE_NAME} --quiet
    echo "✅ Database created!"
fi

# Create user
echo ""
echo "👤 Creating user '${DB_USER}'..."
if gcloud sql users list --instance=${INSTANCE_NAME} --format="value(name)" | grep -q "^${DB_USER}$"; then
    echo "⚠️  User '${DB_USER}' already exists. Updating password..."
    gcloud sql users set-password ${DB_USER} \
        --instance=${INSTANCE_NAME} \
        --password=${DB_PASSWORD} \
        --quiet
else
    gcloud sql users create ${DB_USER} \
        --instance=${INSTANCE_NAME} \
        --password=${DB_PASSWORD} \
        --quiet
fi
echo "✅ User created/updated!"

# Grant Cloud SQL Client role to Cloud Run service account
echo ""
echo "🔐 Granting Cloud SQL Client role to Cloud Run service account..."
PROJECT_NUMBER=$(gcloud projects describe ${PROJECT_ID} --format="value(projectNumber)")
SERVICE_ACCOUNT="${PROJECT_NUMBER}-compute@developer.gserviceaccount.com"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member="serviceAccount:${SERVICE_ACCOUNT}" \
    --role="roles/cloudsql.client" \
    --quiet &> /dev/null || echo "   (Role may already be granted)"

echo "✅ Permissions granted!"

# Generate DATABASE_URL
DATABASE_URL="postgresql://${DB_USER}:${DB_PASSWORD}@/${DATABASE_NAME}?host=/cloudsql/${CONNECTION_NAME}"

echo ""
echo "✅ Setup complete!"
echo ""
echo "📋 Connection Information:"
echo "=========================="
echo "Connection Name: ${CONNECTION_NAME}"
echo "Database URL (for Cloud Run): ${DATABASE_URL}"
echo ""
echo "📝 Next Steps:"
echo "1. Add DATABASE_URL to GitHub Secrets (for CI/CD)"
echo "2. Update Cloud Run service to connect to Cloud SQL:"
echo "   gcloud run services update express-backend-prod \\"
echo "     --region=${REGION} \\"
echo "     --add-cloudsql-instances=${CONNECTION_NAME} \\"
echo "     --set-env-vars DATABASE_URL=\"${DATABASE_URL}\""
echo ""
echo "3. Run Prisma migrations (from local machine with authorized IP):"
echo "   export DATABASE_URL=\"postgresql://${DB_USER}:${DB_PASSWORD}@PUBLIC_IP:5432/${DATABASE_NAME}?sslmode=require\""
echo "   npx prisma migrate deploy"
echo ""
echo "⚠️  Security: Keep your passwords secure! Don't commit them to git."
