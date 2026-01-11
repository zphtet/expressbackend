# Check Logs for 500 Error Details

## Your Service

Service: `express-backend-prod`
Region: `us-central1`
URL: `https://express-backend-prod-495288431466.us-central1.run.app/users`

## Check Detailed Logs

The 500 error means something is failing. Check the logs to see the actual error:

```bash
# Get recent logs with errors
gcloud run services logs read express-backend-prod --region=us-central1 --limit=50

# Or filter for errors only
gcloud run services logs read express-backend-prod --region=us-central1 --limit=100 | grep -i error

# Or view in Cloud Console
# https://console.cloud.google.com/run/detail/us-central1/express-backend-prod/logs
```

## Common Errors to Look For

1. **"ECONNREFUSED" or "connect ECONNREFUSED"**
   - Cloud SQL connection not configured
   - Fix: Add Cloud SQL connection

2. **"authentication failed" or "password authentication failed"**
   - Wrong password or user
   - Fix: Check DATABASE_URL password encoding

3. **"relation does not exist" or "table does not exist"**
   - Migrations not run
   - Fix: Run migrations

4. **"permission denied" or "ENOENT"**
   - Service account missing permissions
   - Fix: Grant Cloud SQL Client role

5. **"invalid connection string"**
   - DATABASE_URL format is wrong
   - Fix: Check connection string format

## Most Likely Issue: Cloud SQL Connection Not Configured

Check if Cloud SQL connection is configured:

```bash
gcloud run services describe express-backend-prod --region=us-central1 \
  --format="value(spec.template.spec.containers[0].cloudSqlInstances)"
```

If it's empty, add it:

```bash
gcloud run services update express-backend-prod \
  --region=us-central1 \
  --add-cloudsql-instances=new-react-project-483118:asia-southeast1:test-postgresql
```

## Check Current Configuration

```bash
# Check DATABASE_URL
gcloud run services describe express-backend-prod --region=us-central1 \
  --format="value(spec.template.spec.containers[0].env)" | grep DATABASE_URL

# Check Cloud SQL connection
gcloud run services describe express-backend-prod --region=us-central1 \
  --format="value(spec.template.spec.containers[0].cloudSqlInstances)"

# Check service account
gcloud run services describe express-backend-prod --region=us-central1 \
  --format="value(spec.template.spec.serviceAccountName)"
```

## Quick Fix (Most Common)

Run this to add Cloud SQL connection:

```bash
gcloud run services update express-backend-prod \
  --region=us-central1 \
  --add-cloudsql-instances=new-react-project-483118:asia-southeast1:test-postgresql
```

Then check logs again to see if error changes.
