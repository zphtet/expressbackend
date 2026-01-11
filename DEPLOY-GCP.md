# Deploying to Google Cloud Platform (GCP)

This guide will help you deploy your Express backend to GCP Cloud Run.

## Prerequisites

1. **GCP Account**: Sign up at https://cloud.google.com
2. **Google Cloud SDK (gcloud CLI)**: Install from https://cloud.google.com/sdk/docs/install
3. **Billing enabled** on your GCP project
4. **PostgreSQL Database**: You'll need a Cloud SQL PostgreSQL instance (or use your existing database)

## Step 1: Install and Setup gcloud CLI

```bash
# Login to GCP
gcloud auth login

# Set your project (replace PROJECT_ID with your actual project ID)
gcloud config set project PROJECT_ID

# Enable required APIs
gcloud services enable run.googleapis.com
gcloud services enable cloudbuild.googleapis.com
gcloud services enable sqladmin.googleapis.com
```

## Step 2: Setup Cloud SQL PostgreSQL Database (if needed)

If you don't have a database yet:

```bash
# Create a Cloud SQL PostgreSQL instance
gcloud sql instances create express-backend-db \
  --database-version=POSTGRES_15 \
  --tier=db-f1-micro \
  --region=us-central1

# Create a database
gcloud sql databases create testserver --instance=express-backend-db

# Create a user (replace with your credentials)
gcloud sql users create zinpainghtet \
  --instance=express-backend-db \
  --password=test1234
```

Get the connection name:
```bash
gcloud sql instances describe express-backend-db --format="value(connectionName)"
```

## Step 3: Deploy to Cloud Run

### Option A: Deploy from source (Recommended)

```bash
# Deploy to Cloud Run
gcloud run deploy express-backend \
  --source . \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --set-env-vars DATABASE_URL="postgresql://zinpainghtet:test1234@/testserver?host=/cloudsql/PROJECT_ID:REGION:INSTANCE_NAME"
```

**Note**: For Cloud SQL connection, you need to:
1. Replace `PROJECT_ID:REGION:INSTANCE_NAME` with your actual connection name
2. Use the Unix socket path format for Cloud SQL
3. Add the Cloud SQL connection to your service:

```bash
gcloud run deploy express-backend \
  --source . \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --add-cloudsql-instances PROJECT_ID:REGION:INSTANCE_NAME \
  --set-env-vars DATABASE_URL="postgresql://USER:PASSWORD@/DATABASE_NAME?host=/cloudsql/PROJECT_ID:REGION:INSTANCE_NAME"
```

### Option B: Deploy from Container Image

First, build and push to Container Registry or Artifact Registry:

```bash
# Build the image
docker build -t gcr.io/PROJECT_ID/express-backend:latest .

# Push to Container Registry
docker push gcr.io/PROJECT_ID/express-backend:latest

# Deploy to Cloud Run
gcloud run deploy express-backend \
  --image gcr.io/PROJECT_ID/express-backend:latest \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --add-cloudsql-instances PROJECT_ID:REGION:INSTANCE_NAME \
  --set-env-vars DATABASE_URL="postgresql://USER:PASSWORD@/DATABASE_NAME?host=/cloudsql/PROJECT_ID:REGION:INSTANCE_NAME"
```

## Step 4: Update Database URL

The DATABASE_URL format for Cloud SQL is different:

**For Cloud SQL (Unix Socket):**
```
postgresql://USER:PASSWORD@/DATABASE_NAME?host=/cloudsql/PROJECT_ID:REGION:INSTANCE_NAME
```

**For Public IP (not recommended for production):**
```
postgresql://USER:PASSWORD@PUBLIC_IP:5432/DATABASE_NAME
```

## Step 5: Grant Permissions

Cloud Run needs permission to connect to Cloud SQL:

```bash
# Get the service account email
PROJECT_NUMBER=$(gcloud projects describe PROJECT_ID --format="value(projectNumber)")
SERVICE_ACCOUNT="${PROJECT_NUMBER}-compute@developer.gserviceaccount.com"

# Grant Cloud SQL Client role
gcloud projects add-iam-policy-binding PROJECT_ID \
  --member="serviceAccount:${SERVICE_ACCOUNT}" \
  --role="roles/cloudsql.client"
```

## Step 6: Access Your Application

After deployment, you'll get a URL like:
```
https://express-backend-xxxxx-uc.a.run.app
```

## Environment Variables

Set environment variables during deployment:

```bash
gcloud run services update express-backend \
  --region us-central1 \
  --set-env-vars DATABASE_URL="your-database-url",NODE_ENV="production"
```

## Useful Commands

```bash
# View logs
gcloud run services logs read express-backend --region us-central1

# List services
gcloud run services list

# Update service
gcloud run services update express-backend --region us-central1

# Delete service
gcloud run services delete express-backend --region us-central1
```

## Troubleshooting

1. **Connection refused**: Make sure Cloud SQL connection is properly configured
2. **Port errors**: The app now uses `PORT` env var (Cloud Run requirement)
3. **Build errors**: Check that all files are included (verify .gcloudignore)

## Cost Considerations

- Cloud Run: Pay per request (free tier: 2 million requests/month)
- Cloud SQL: Depends on instance size (db-f1-micro is cheapest)
- Both have free tiers to get started
