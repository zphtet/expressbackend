# Fix ENOENT Error - Cloud SQL Connection Missing

## The Error

```
connect ENOENT /cloudsql/new-react-project-483118:asia-southeast1:test-postgresql/.s.PGSQL.5432
```

**ENOENT** = "Error NO ENTry" = The Unix socket file doesn't exist

## The Problem

Your Cloud Run service doesn't have the Cloud SQL connection configured. The DATABASE_URL is set, but the service isn't connected to Cloud SQL.

## The Fix

### Step 1: Add Cloud SQL Connection

```bash
gcloud run services update express-backend-prod \
  --region=us-central1 \
  --add-cloudsql-instances=new-react-project-483118:asia-southeast1:test-postgresql
```

### Step 2: Grant Service Account Permission

```bash
# Get project number
PROJECT_NUMBER=$(gcloud projects describe new-react-project-483118 --format="value(projectNumber)")

# Grant Cloud SQL Client role
gcloud projects add-iam-policy-binding new-react-project-483118 \
  --member="serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
  --role="roles/cloudsql.client"
```

### Step 3: Verify Connection

```bash
# Check if Cloud SQL connection is configured
gcloud run services describe express-backend-prod --region=us-central1 \
  --format="value(spec.template.spec.containers[0].cloudSqlInstances)"
```

Should show: `new-react-project-483118:asia-southeast1:test-postgresql`

## Complete Fix Command

Run both commands:

```bash
# 1. Add Cloud SQL connection
gcloud run services update express-backend-prod \
  --region=us-central1 \
  --add-cloudsql-instances=new-react-project-483118:asia-southeast1:test-postgresql

# 2. Grant permissions (if not already granted)
PROJECT_NUMBER=$(gcloud projects describe new-react-project-483118 --format="value(projectNumber)")
gcloud projects add-iam-policy-binding new-react-project-483118 \
  --member="serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
  --role="roles/cloudsql.client"
```

## After Fixing

1. Wait a few seconds for the service to update
2. Try accessing `/users` endpoint again
3. Check logs if still failing: `gcloud run services logs read express-backend-prod --region=us-central1 --limit=20`

## What This Does

- `--add-cloudsql-instances` creates the Unix socket connection
- Grants permissions so the service can use the socket
- Allows Prisma to connect via the socket path in DATABASE_URL

The socket file will be created automatically when the service connects to Cloud SQL.
