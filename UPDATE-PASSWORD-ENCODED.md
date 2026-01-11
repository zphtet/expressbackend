# Update Password with Encoding

## Your New Password

Password: `Zinpaing^215108`

The `^` character also needs to be URL-encoded! `^` becomes `%5E`

## Encoded Password

`Zinpaing^215108` → `Zinpaing%5E215108`

## Correct DATABASE_URL

```
postgresql://zinpainghtet:Zinpaing%5E215108@/testserver?host=/cloudsql/new-react-project-483118:asia-southeast1:test-postgresql
```

## Update Cloud Run Service

```bash
gcloud run services update express-backend-prod \
  --region=asia-southeast1 \
  --set-env-vars DATABASE_URL="postgresql://zinpainghtet:Zinpaing%5E215108@/testserver?host=/cloudsql/new-react-project-483118:asia-southeast1:test-postgresql"
```

Replace `express-backend-prod` with your actual service name if different.

## Update GitHub Secrets (for CI/CD)

1. Go to GitHub → Repository → Settings → Secrets → Actions
2. Update `DATABASE_URL` secret with:
   ```
   postgresql://zinpainghtet:Zinpaing%5E215108@/testserver?host=/cloudsql/new-react-project-483118:asia-southeast1:test-postgresql
   ```

## Common Special Characters That Need Encoding

- `@` → `%40`
- `^` → `%5E`
- `:` → `%3A`
- `/` → `%2F`
- `%` → `%25`
- `#` → `%23`
- `?` → `%3F`
- `&` → `%26`
- `=` → `%3D`
- ` ` (space) → `%20` or `+`

## Alternative: Use Password Without Special Characters

If you want to avoid encoding, use a password without special characters:

```bash
# Change to simple password
gcloud sql users set-password zinpainghtet \
  --instance=test-postgresql \
  --password=Zinpaing215108

# Then DATABASE_URL (no encoding needed):
postgresql://zinpainghtet:Zinpaing215108@/testserver?host=/cloudsql/new-react-project-483118:asia-southeast1:test-postgresql
```

## Verify After Update

Check Cloud Run logs:

```bash
gcloud run services logs read express-backend-prod --region=asia-southeast1 --limit=50
```
