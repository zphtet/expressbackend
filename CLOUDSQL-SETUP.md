# Cloud SQL PostgreSQL Setup Guide

Complete step-by-step guide to set up Cloud SQL PostgreSQL and connect it to your Express backend on Cloud Run.

## Prerequisites

- GCP Project with billing enabled
- gcloud CLI installed (optional, but helpful)
- Your backend already deployed to Cloud Run (or ready to deploy)

## Step 1: Enable Required APIs

Enable the Cloud SQL Admin API:

```bash
gcloud services enable sqladmin.googleapis.com
```

Or via Console:
1. Go to: https://console.cloud.google.com/apis/library
2. Search for "Cloud SQL Admin API"
3. Click "Enable"

## Step 2: Create Cloud SQL PostgreSQL Instance

### Option A: Using gcloud CLI (Recommended)

```bash
# Set your project
gcloud config set project new-react-project-483118

# Create Cloud SQL instance
gcloud sql instances create express-backend-db \
  --database-version=POSTGRES_15 \
  --tier=db-f1-micro \
  --region=us-central1 \
  --root-password=YOUR_ROOT_PASSWORD \
  --storage-type=SSD \
  --storage-size=20GB \
  --storage-auto-increase \
  --backup \
  --enable-bin-log

# Replace YOUR_ROOT_PASSWORD with a strong password
# Save this password securely!
```

**Parameters explained:**
- `--database-version=POSTGRES_15`: PostgreSQL version
- `--tier=db-f1-micro`: Smallest/cheapest instance (good for dev/testing)
- `--region=us-central1`: Should match your Cloud Run region
- `--root-password`: Root password for PostgreSQL
- `--storage-size=20GB`: Initial storage (minimum 10GB)
- `--storage-auto-increase`: Auto-increase storage when needed
- `--backup`: Enable automated backups

### Option B: Using GCP Console

1. Go to: https://console.cloud.google.com/sql/instances
2. Click **"CREATE INSTANCE"**
3. Choose **"Choose PostgreSQL"**
4. Fill in the form:
   - **Instance ID**: `express-backend-db`
   - **Password**: Set a strong root password (save it!)
   - **Database version**: PostgreSQL 15 (or latest)
   - **Region**: `us-central1` (match your Cloud Run region)
   - **Zonal availability**: Single zone (cheaper) or Multi-zone (more reliable)
5. Click **"SHOW CONFIGURATION OPTIONS"**
6. Under **Machine type**: Select `Shared core` → `db-f1-micro` (or `db-g1-small` for better performance)
7. Under **Storage**:
   - Storage type: SSD
   - Storage capacity: 20 GB
   - Enable storage autoscaling: ✓
8. Under **Backups**: Enable automated backups (recommended)
9. Click **"CREATE INSTANCE"**

⏱️ **Wait 5-10 minutes** for the instance to be created.

## Step 3: Create Database and User

### Option A: Using gcloud CLI

```bash
# Create a database
gcloud sql databases create testserver \
  --instance=express-backend-db

# Create a user (replace with your credentials)
gcloud sql users create zinpainghtet \
  --instance=express-backend-db \
  --password=YOUR_USER_PASSWORD

# Replace YOUR_USER_PASSWORD with a secure password
```

### Option B: Using GCP Console

1. Go to your SQL instance: https://console.cloud.google.com/sql/instances/express-backend-db
2. Click on the **"DATABASES"** tab
3. Click **"CREATE DATABASE"**
   - Database name: `testserver` (or your database name)
   - Click **"CREATE"**
4. Click on the **"USERS"** tab
5. Click **"ADD USER ACCOUNT"**
   - Username: `zinpainghtet` (or your username)
   - Password: Set a strong password
   - Click **"ADD"**

## Step 4: Get Connection Details

You need the **connection name** for Cloud SQL connection:

```bash
# Get connection name
gcloud sql instances describe express-backend-db \
  --format="value(connectionName)"
```

Output will look like: `new-react-project-483118:us-central1:express-backend-db`

Or from Console:
1. Go to your instance
2. Under **"Overview"**, find **"Connection name"**
3. Copy it (format: `PROJECT_ID:REGION:INSTANCE_NAME`)

## Step 5: Configure Cloud SQL Connection for Cloud Run

Your Cloud Run service needs permission to connect to Cloud SQL.

### Option A: Using gcloud CLI

```bash
# Deploy/Update your Cloud Run service with Cloud SQL connection
gcloud run services update express-backend-prod \
  --region=us-central1 \
  --add-cloudsql-instances=new-react-project-483118:us-central1:express-backend-db \
  --set-env-vars DATABASE_URL="postgresql://zinpainghtet:YOUR_USER_PASSWORD@/testserver?host=/cloudsql/new-react-project-483118:us-central1:express-backend-db"
```

**Important:** Replace:
- `YOUR_USER_PASSWORD` with the user password you created
- `express-backend-prod` with your actual service name
- Username/database names if different

### Option B: Using GCP Console

1. Go to Cloud Run: https://console.cloud.google.com/run
2. Click on your service (e.g., `express-backend-prod`)
3. Click **"EDIT & DEPLOY NEW REVISION"**
4. Under **"Connections"**:
   - Check **"Connect to a Cloud SQL instance"**
   - Select your instance: `express-backend-db`
5. Under **"Variables & Secrets"**:
   - Add environment variable:
     - **Name**: `DATABASE_URL`
     - **Value**: `postgresql://zinpainghtet:YOUR_PASSWORD@/testserver?host=/cloudsql/new-react-project-483118:us-central1:express-backend-db`
6. Click **"DEPLOY"**

### DATABASE_URL Format for Cloud SQL

For Cloud SQL connection via Unix socket (recommended):

```
postgresql://USERNAME:PASSWORD@/DATABASE_NAME?host=/cloudsql/PROJECT_ID:REGION:INSTANCE_NAME
```

**Example:**
```
postgresql://zinpainghtet:mypassword123@/testserver?host=/cloudsql/new-react-project-483118:us-central1:express-backend-db
```

## Step 6: Grant Cloud Run Service Account Permission

The Cloud Run service account needs the Cloud SQL Client role:

```bash
# Get your project number
PROJECT_NUMBER=$(gcloud projects describe new-react-project-483118 --format="value(projectNumber)")

# Get the service account email
SERVICE_ACCOUNT="${PROJECT_NUMBER}-compute@developer.gserviceaccount.com"

# Grant Cloud SQL Client role
gcloud projects add-iam-policy-binding new-react-project-483118 \
  --member="serviceAccount:${SERVICE_ACCOUNT}" \
  --role="roles/cloudsql.client"
```

Or via Console:
1. Go to: https://console.cloud.google.com/iam-admin/iam
2. Find: `PROJECT_NUMBER-compute@developer.gserviceaccount.com`
3. Click the edit icon (pencil)
4. Click **"ADD ANOTHER ROLE"**
5. Select: **Cloud SQL Client**
6. Click **"SAVE"**

## Step 7: Run Prisma Migrations

Your database schema needs to be created. You have a few options:

### Option A: Run migrations from local machine (using public IP)

**📖 See detailed guide: `RUN-MIGRATIONS-LOCAL.md`**

Quick steps:

```bash
# 1. Get your public IP
MY_IP=$(curl -s ifconfig.me)

# 2. Authorize your IP
gcloud sql instances patch express-backend-db \
  --authorized-networks=$MY_IP/32

# 3. Get Cloud SQL public IP
PUBLIC_IP=$(gcloud sql instances describe express-backend-db \
  --format="value(ipAddresses[0].ipAddress)")

# 4. Set DATABASE_URL
export DATABASE_URL="postgresql://zinpainghtet:YOUR_PASSWORD@$PUBLIC_IP:5432/testserver?sslmode=require"

# 5. Run migrations
npx prisma migrate deploy
```

### Option B: Run migrations from Cloud Shell

1. Go to: https://shell.cloud.google.com
2. Clone your repository or upload your Prisma schema
3. Set DATABASE_URL with public IP
4. Run: `npx prisma migrate deploy`

### Option C: Create a migration script in Cloud Run (Advanced)

Create a one-time job or script to run migrations on deployment.

## Step 8: Update GitHub Secrets (for CI/CD)

If you're using CI/CD, update your GitHub secret:

1. Go to GitHub → Repository → Settings → Secrets → Actions
2. Update `DATABASE_URL` secret with the Cloud SQL connection string:
   ```
   postgresql://zinpainghtet:YOUR_PASSWORD@/testserver?host=/cloudsql/new-react-project-483118:us-central1:express-backend-db
   ```

## Step 9: Test the Connection

Test your backend:

```bash
# Get your Cloud Run service URL
gcloud run services describe express-backend-prod \
  --region=us-central1 \
  --format="value(status.url)"

# Test the endpoint
curl https://YOUR-SERVICE-URL.run.app/users
```

## Instance Sizes and Pricing

### Instance Tiers:

- **db-f1-micro**: $7.67/month (1 vCPU, 0.6 GB RAM) - Development/Testing
- **db-g1-small**: $24.48/month (1 vCPU, 1.7 GB RAM) - Small production
- **db-n1-standard-1**: $50.46/month (1 vCPU, 3.75 GB RAM) - Medium production

### Storage:
- SSD: $0.17 per GB per month
- HDD: $0.09 per GB per month (not recommended for production)

### Backup:
- Automated backups: Included in storage cost
- On-demand backups: $0.08 per GB

**Estimated monthly cost for db-f1-micro with 20GB SSD: ~$11-15/month**

## Security Best Practices

1. **Use strong passwords** for database users
2. **Enable SSL connections** (default for Cloud SQL)
3. **Use private IP** for production (requires VPC setup)
4. **Restrict authorized networks** if using public IP
5. **Use connection pooling** for better performance
6. **Enable automated backups** (recommended)
7. **Rotate passwords regularly**
8. **Use secrets management** (don't hardcode passwords)

## Troubleshooting

### Connection refused
- Verify Cloud SQL instance is running
- Check connection name format
- Verify Cloud Run service has Cloud SQL connection enabled
- Check service account has Cloud SQL Client role

### Authentication failed
- Verify username and password are correct
- Check DATABASE_URL format
- Ensure user exists in the database

### Database doesn't exist
- Run Prisma migrations
- Verify database name in DATABASE_URL matches created database

### Performance issues
- Consider upgrading instance tier
- Enable connection pooling
- Check database indexes

## Useful Commands

```bash
# List all instances
gcloud sql instances list

# Describe instance
gcloud sql instances describe express-backend-db

# List databases
gcloud sql databases list --instance=express-backend-db

# List users
gcloud sql users list --instance=express-backend-db

# View logs
gcloud sql operations list --instance=express-backend-db

# Restart instance (if needed)
gcloud sql instances restart express-backend-db

# Delete instance (⚠️ destructive)
gcloud sql instances delete express-backend-db
```
