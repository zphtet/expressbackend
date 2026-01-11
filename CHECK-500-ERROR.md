# Fix 500 Internal Server Error

## The Issue

Getting 500 error on `/users` route means:
- ✅ Server is running
- ✅ Route is being accessed
- ❌ Database connection is failing

## Step 1: Check the Actual Error in Logs

```bash
# Replace SERVICE_NAME with your actual Cloud Run service name
gcloud run services logs read SERVICE_NAME --region=asia-southeast1 --limit=50

# Or view in Cloud Console:
# https://console.cloud.google.com/run/detail/asia-southeast1/SERVICE_NAME/logs
```

This will show the actual error message!

## Step 2: Common Causes

### 1. Cloud SQL Connection Not Configured

The service needs the Cloud SQL instance connected. Check:

```bash
gcloud run services describe SERVICE_NAME --region=asia-southeast1 \
  --format="value(spec.template.spec.containers[0].cloudSqlInstances)"
```

If empty or doesn't show your instance, add it:

```bash
gcloud run services update SERVICE_NAME \
  --region=asia-southeast1 \
  --add-cloudsql-instances=new-react-project-483118:asia-southeast1:test-postgresql
```

### 2. Service Account Permissions

The Cloud Run service account needs Cloud SQL Client role:

```bash
# Get project number
PROJECT_NUMBER=$(gcloud projects describe new-react-project-483118 --format="value(projectNumber)")

# Grant permission
gcloud projects add-iam-policy-binding new-react-project-483118 \
  --member="serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
  --role="roles/cloudsql.client"
```

### 3. Migrations Not Run

The database tables might not exist. Run migrations:

```bash
./migrate-to-cloudsql.sh
```

### 4. Password Encoding Issue

Even though you encoded it, double-check. Try using a simple password:

```bash
# Change to simple password (no special characters)
gcloud sql users set-password zinpainghtet \
  --instance=test-postgresql \
  --password=Zinpaing215108

# Update Cloud Run
gcloud run services update SERVICE_NAME \
  --region=asia-southeast1 \
  --set-env-vars DATABASE_URL="postgresql://zinpainghtet:Zinpaing215108@/testserver?host=/cloudsql/new-react-project-483118:asia-southeast1:test-postgresql"
```

## Step 3: Verify Complete Setup

Run this to check everything:

```bash
SERVICE_NAME="YOUR_SERVICE_NAME"  # Update this

# 1. Check Cloud SQL connection
echo "1. Checking Cloud SQL connection..."
gcloud run services describe $SERVICE_NAME --region=asia-southeast1 \
  --format="value(spec.template.spec.containers[0].cloudSqlInstances)"

# 2. Check DATABASE_URL
echo "2. Checking DATABASE_URL..."
gcloud run services describe $SERVICE_NAME --region=asia-southeast1 \
  --format="value(spec.template.spec.containers[0].env)" | grep DATABASE_URL

# 3. Check logs
echo "3. Recent logs:"
gcloud run services logs read $SERVICE_NAME --region=asia-southeast1 --limit=20
```

## Step 4: Most Likely Fix

The most common issue is missing Cloud SQL connection. Run this:

```bash
# Get your service name first
gcloud run services list --region=asia-southeast1

# Then update (replace SERVICE_NAME)
gcloud run services update SERVICE_NAME \
  --region=asia-southeast1 \
  --add-cloudsql-instances=new-react-project-483118:asia-southeast1:test-postgresql
```

## Step 5: Check Error Details

The logs will show the exact error. Common errors:

- **"connect ECONNREFUSED"** → Cloud SQL connection not configured
- **"authentication failed"** → Wrong password or user
- **"relation does not exist"** → Migrations not run
- **"permission denied"** → Service account missing permissions

## Quick Fix Script

```bash
#!/bin/bash
SERVICE_NAME="YOUR_SERVICE_NAME"  # UPDATE THIS
REGION="asia-southeast1"

echo "🔧 Fixing Cloud Run Database Connection..."
echo ""

# Add Cloud SQL connection
echo "1. Adding Cloud SQL connection..."
gcloud run services update $SERVICE_NAME \
  --region=$REGION \
  --add-cloudsql-instances=new-react-project-483118:asia-southeast1:test-postgresql

# Grant permissions
echo "2. Granting permissions..."
PROJECT_NUMBER=$(gcloud projects describe new-react-project-483118 --format="value(projectNumber)")
gcloud projects add-iam-policy-binding new-react-project-483118 \
  --member="serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
  --role="roles/cloudsql.client" \
  --quiet

echo ""
echo "✅ Done! Check logs:"
echo "gcloud run services logs read $SERVICE_NAME --region=$REGION --limit=20"
```
