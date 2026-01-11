# Fix Cloud Run DATABASE_URL

## The Problem

Your DATABASE_URL has a password with `@` character:
```
postgresql://zinpainghtet:Zinpaing@215108@/testserver?host=/cloudsql/...
```

The `@` in the password (`Zinpaing@215108`) is being interpreted as the URL separator, breaking the connection string!

## The Solution

URL-encode the password. The `@` character should be `%40`.

### Current (Broken):
```
postgresql://zinpainghtet:Zinpaing@215108@/testserver?host=/cloudsql/new-react-project-483118:asia-southeast1:test-postgresql
```

### Fixed (Correct):
```
postgresql://zinpainghtet:Zinpaing%40215108@/testserver?host=/cloudsql/new-react-project-483118:asia-southeast1:test-postgresql
```

## How to URL-Encode the Password

### Option 1: Use Python (Quick)
```bash
python3 -c "import urllib.parse; print(urllib.parse.quote('Zinpaing@215108', safe=''))"
# Output: Zinpaing%40215108
```

### Option 2: Manual Encoding
- `@` → `%40`
- `:` → `%3A`
- `/` → `%2F`
- `%` → `%25`
- etc.

## Update Cloud Run Service

Update your Cloud Run service with the encoded password:

```bash
gcloud run services update express-backend-prod \
  --region=asia-southeast1 \
  --set-env-vars DATABASE_URL="postgresql://zinpainghtet:Zinpaing%40215108@/testserver?host=/cloudsql/new-react-project-483118:asia-southeast1:test-postgresql"
```

Or if using a different service name:
```bash
gcloud run services update YOUR_SERVICE_NAME \
  --region=asia-southeast1 \
  --set-env-vars DATABASE_URL="postgresql://zinpainghtet:Zinpaing%40215108@/testserver?host=/cloudsql/new-react-project-483118:asia-southeast1:test-postgresql"
```

## Update GitHub Secrets (for CI/CD)

If you're using CI/CD, also update the GitHub secret:

1. Go to GitHub → Repository → Settings → Secrets → Actions
2. Update `DATABASE_URL` secret with:
   ```
   postgresql://zinpainghtet:Zinpaing%40215108@/testserver?host=/cloudsql/new-react-project-483118:asia-southeast1:test-postgresql
   ```

## Verify Connection

After updating, check the Cloud Run logs:

```bash
gcloud run services logs read express-backend-prod --region=asia-southeast1 --limit=50
```

## Alternative: Change Password (No Special Characters)

If you want to avoid URL encoding, change the password to one without special characters:

```bash
# Change password to something without @
gcloud sql users set-password zinpainghtet \
  --instance=test-postgresql \
  --password=Zinpaing215108

# Then use in DATABASE_URL (no encoding needed):
postgresql://zinpainghtet:Zinpaing215108@/testserver?host=/cloudsql/new-react-project-483118:asia-southeast1:test-postgresql
```

## Complete Connection String Format

For Cloud Run with Cloud SQL Unix socket:
```
postgresql://USERNAME:ENCODED_PASSWORD@/DATABASE_NAME?host=/cloudsql/PROJECT_ID:REGION:INSTANCE_NAME
```

Notes:
- Password must be URL-encoded if it contains special characters
- No port number (Unix socket)
- No IP address (Unix socket)
- `host=/cloudsql/...` is the Unix socket path

## Quick Check

To verify your connection string is valid, you can test it:

```bash
# Set the URL
export DATABASE_URL="postgresql://zinpainghtet:Zinpaing%40215108@/testserver?host=/cloudsql/new-react-project-483118:asia-southeast1:test-postgresql"

# Test with psql (if installed and Cloud SQL proxy is set up)
# Or test from within Cloud Run by checking logs
```
