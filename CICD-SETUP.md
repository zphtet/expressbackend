# CI/CD Setup Instructions

## GitHub Secrets Required

Before the CI/CD workflow can run, you need to set up the following secrets in your GitHub repository:

1. Go to your repository → **Settings** → **Secrets and variables** → **Actions**

2. Add the following secrets:

   - **`GCP_SA_KEY`**: Service Account JSON key for GCP authentication
     - Go to GCP Console → IAM & Admin → Service Accounts
     - Create a service account (or use existing)
     - Grant roles: `Cloud Run Admin`, `Service Account User`, `Storage Admin` (for Artifact Registry)
     - Create and download JSON key
     - Copy the entire JSON content and paste it as the secret value

   - **`DATABASE_URL`**: Your PostgreSQL database connection string
     - Format: `postgresql://user:password@host:port/database?schema=public`
     - For Cloud SQL: `postgresql://user:password@/database?host=/cloudsql/PROJECT_ID:REGION:INSTANCE_NAME`

## Artifact Registry Setup

Make sure you have an Artifact Registry repository set up:

```bash
gcloud artifacts repositories create docker-repo \
  --repository-format=docker \
  --location=us-central1 \
  --description="Docker repository for CI/CD"
```

## Service Account Permissions

The service account used in `GCP_SA_KEY` needs these roles:
- `Cloud Run Admin` - to deploy services
- `Service Account User` - to run Cloud Run services
- `Artifact Registry Writer` - to push Docker images
- `Storage Admin` - for Artifact Registry access

## Workflow Behavior

- **Push to `dev` branch**: Deploys to `express-backend-dev` service with `dev` image tag
- **Push to `main` branch**: Deploys to `express-backend-prod` service with `prod` image tag

## Differences from Frontend Workflow

- No build step (TypeScript runs directly with `tsx`)
- Includes Prisma client generation step for validation
- Port set to 3005 (matching your backend)
- DATABASE_URL passed as environment variable

## Testing the Workflow

1. Push to `dev` or `main` branch
2. Check the **Actions** tab in GitHub to see the workflow run
3. After successful deployment, your service will be available at:
   - Dev: `https://express-backend-dev-xxxxx-uc.a.run.app`
   - Prod: `https://express-backend-prod-xxxxx-uc.a.run.app`
