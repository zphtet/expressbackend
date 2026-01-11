# Troubleshoot Cloud Run Database Connection

## Step 1: Check Cloud Run Service Configuration

Verify your service has the Cloud SQL connection configured:

```bash
# List your Cloud Run services
gcloud run services list --region=asia-southeast1

# Check service configuration (replace SERVICE_NAME with your actual service name)
gcloud run services describe SERVICE_NAME --region=asia-southeast1 --format="yaml" | grep -A 10 "cloudSqlInstances\|env:"
```

## Step 2: Verify Cloud SQL Connection is Added

The service MUST have the Cloud SQL instance connected:

```bash
# Check if Cloud SQL connection is configured
gcloud run services describe SERVICE_NAME --region=asia-southeast1 \
  --format="value(spec.template.spec.containers[0].env)" | grep DATABASE_URL

# Check Cloud SQL connections
gcloud run services describe SERVICE_NAME --region=asia-southeast1 \
  --format="value(spec.template.spec.containers[0].cloudSqlInstances)"
```

If Cloud SQL connection is NOT configured, add it:

```bash
gcloud run services update SERVICE_NAME \
  --region=asia-southeast1 \
  --add-cloudsql-instances=new-react-project-483118:asia-southeast1:test-postgresql
```

## Step 3: Check Logs for Errors

```bash
# View recent logs
gcloud run services logs read SERVICE_NAME --region=asia-southeast1 --limit=50

# Or use Cloud Console
# https://console.cloud.google.com/run/detail/asia-southeast1/SERVICE_NAME/logs
```

## Step 4: Verify DATABASE_URL Format

For Cloud Run with Cloud SQL Unix socket, the format should be:

```
postgresql://USERNAME:ENCODED_PASSWORD@/DATABASE_NAME?host=/cloudsql/PROJECT_ID:REGION:INSTANCE_NAME
```

**Important:**
- No port number
- No IP address
- Password MUST be URL-encoded if it has special characters
- Use `/cloudsql/PROJECT_ID:REGION:INSTANCE_NAME` format

## Step 5: Test Connection String

Your connection string should be:

```
postgresql://zinpainghtet:Zinpaing%5E215108@/testserver?host=/cloudsql/new-react-project-483118:asia-southeast1:test-postgresql
```

## Step 6: Update Service with Correct Configuration

```bash
# Get your service name first
gcloud run services list --region=asia-southeast1

# Update with both Cloud SQL connection AND DATABASE_URL
gcloud run services update YOUR_SERVICE_NAME \
  --region=asia-southeast1 \
  --add-cloudsql-instances=new-react-project-483118:asia-southeast1:test-postgresql \
  --set-env-vars DATABASE_URL="postgresql://zinpainghtet:Zinpaing%5E215108@/testserver?host=/cloudsql/new-react-project-483118:asia-southeast1:test-postgresql"
```

## Common Issues

### 1. Cloud SQL Connection Not Configured
**Error:** Connection refused or timeout
**Fix:** Add `--add-cloudsql-instances` flag

### 2. Wrong Connection String Format
**Error:** Invalid connection string
**Fix:** Use Unix socket format (no IP, no port)

### 3. Password Not Encoded
**Error:** Authentication failed or invalid URL
**Fix:** URL-encode special characters in password

### 4. Wrong Region
**Error:** Instance not found
**Fix:** Make sure region matches (asia-southeast1)

### 5. Service Account Permissions
**Error:** Permission denied
**Fix:** Ensure service account has Cloud SQL Client role

## Quick Diagnostic Command

Run this to check everything:

```bash
# Set your service name
SERVICE_NAME="express-backend-prod"  # Update this

# Check service exists
echo "Checking service..."
gcloud run services describe $SERVICE_NAME --region=asia-southeast1 > /dev/null 2>&1
if [ $? -eq 0 ]; then
  echo "✅ Service exists"
else
  echo "❌ Service not found. List services:"
  gcloud run services list --region=asia-southeast1
  exit 1
fi

# Check Cloud SQL connection
echo "Checking Cloud SQL connection..."
gcloud run services describe $SERVICE_NAME --region=asia-southeast1 \
  --format="value(spec.template.spec.containers[0].cloudSqlInstances)" | grep -q "test-postgresql"
if [ $? -eq 0 ]; then
  echo "✅ Cloud SQL connection configured"
else
  echo "❌ Cloud SQL connection NOT configured"
  echo "Run: gcloud run services update $SERVICE_NAME --region=asia-southeast1 --add-cloudsql-instances=new-react-project-483118:asia-southeast1:test-postgresql"
fi

# Check DATABASE_URL
echo "Checking DATABASE_URL..."
gcloud run services describe $SERVICE_NAME --region=asia-southeast1 \
  --format="value(spec.template.spec.containers[0].env)" | grep -q "DATABASE_URL"
if [ $? -eq 0 ]; then
  echo "✅ DATABASE_URL is set"
else
  echo "❌ DATABASE_URL NOT set"
fi

# Show recent logs
echo ""
echo "Recent logs:"
gcloud run services logs read $SERVICE_NAME --region=asia-southeast1 --limit=10
```
