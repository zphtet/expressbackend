#!/bin/bash

# Script to generate GCP Service Account Key using gcloud CLI
# Usage: ./get-gcp-key.sh

set -e

PROJECT_ID="new-react-project-483118"
SA_NAME="github-actions-cloud-run"
SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
KEY_FILE="gcp-sa-key.json"

echo "🚀 GCP Service Account Key Generator"
echo "===================================="
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

# Check if service account exists
if ! gcloud iam service-accounts describe ${SA_EMAIL} &> /dev/null; then
    echo "👤 Service account doesn't exist. Creating..."
    gcloud iam service-accounts create ${SA_NAME} \
        --display-name="GitHub Actions CI/CD Service Account"
    echo "✅ Service account created"
else
    echo "✅ Service account already exists"
fi

# Grant roles
echo "🔑 Granting required roles..."

ROLES=(
    "roles/run.admin"
    "roles/iam.serviceAccountUser"
    "roles/artifactregistry.writer"
    "roles/storage.admin"
)

for ROLE in "${ROLES[@]}"; do
    echo "  - Granting ${ROLE}..."
    gcloud projects add-iam-policy-binding ${PROJECT_ID} \
        --member="serviceAccount:${SA_EMAIL}" \
        --role="${ROLE}" \
        --quiet &> /dev/null || true
done

echo "✅ Roles granted"

# Create key
echo "🔐 Creating service account key..."
if [ -f "${KEY_FILE}" ]; then
    echo "⚠️  Warning: ${KEY_FILE} already exists. Backing up..."
    mv ${KEY_FILE} ${KEY_FILE}.backup.$(date +%s)
fi

gcloud iam service-accounts keys create ${KEY_FILE} \
    --iam-account=${SA_EMAIL}

echo ""
echo "✅ Key created successfully!"
echo ""
echo "📄 Key file: ${KEY_FILE}"
echo ""
echo "📋 Next steps:"
echo "1. Copy the contents of ${KEY_FILE}"
echo "2. Go to GitHub → Repository → Settings → Secrets → Actions"
echo "3. Add new secret: GCP_SA_KEY"
echo "4. Paste the JSON content"
echo "5. Delete ${KEY_FILE} from your local machine (for security)"
echo ""
echo "⚠️  Security: Never commit this file to git!"
