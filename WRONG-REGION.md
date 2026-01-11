# Wrong Region Issue

## The Problem

Your CI/CD workflow deploys to **`us-central1`** region, but you were checking **`asia-southeast1`**!

## Your CI/CD Configuration

Looking at `.github/workflows/cicd.yml`, line 74 shows:
```yaml
region: us-central1
```

## Find Your Service

```bash
# Check the correct region
gcloud run services list --region=us-central1

# Or list all services
gcloud run services list
```

## Service Names

Based on your workflow, services are named:
- `express-backend-prod` (deployed from `main` branch)
- `express-backend-dev` (deployed from `dev` branch)

## Check Logs (Correct Region)

```bash
gcloud run services logs read express-backend-prod --region=us-central1 --limit=50
```

## Update Service (Correct Region)

```bash
gcloud run services update express-backend-prod \
  --region=us-central1 \
  --add-cloudsql-instances=new-react-project-483118:asia-southeast1:test-postgresql \
  --set-env-vars DATABASE_URL="postgresql://zinpainghtet:Zinpaing%5E215108@/testserver?host=/cloudsql/new-react-project-483118:asia-southeast1:test-postgresql"
```

## Region Mismatch Issue

**Important:** Your Cloud SQL instance is in `asia-southeast1`, but your Cloud Run service is in `us-central1`.

This is okay! Cloud Run can connect to Cloud SQL in a different region, but you need to:
1. Add the Cloud SQL connection (shown above)
2. Use the correct connection string format (which you have)

## Fix Steps

1. **Find your service:**
   ```bash
   gcloud run services list --region=us-central1
   ```

2. **Check logs:**
   ```bash
   gcloud run services logs read express-backend-prod --region=us-central1 --limit=50
   ```

3. **Add Cloud SQL connection:**
   ```bash
   gcloud run services update express-backend-prod \
     --region=us-central1 \
     --add-cloudsql-instances=new-react-project-483118:asia-southeast1:test-postgresql
   ```

4. **Verify DATABASE_URL is set:**
   ```bash
   gcloud run services describe express-backend-prod --region=us-central1 \
     --format="value(spec.template.spec.containers[0].env)" | grep DATABASE_URL
   ```
