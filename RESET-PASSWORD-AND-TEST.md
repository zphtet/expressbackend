# Reset Password and Test

## The Issue

The SSL error is fixed, but authentication is still failing. This means the password stored in Cloud SQL doesn't match what you're entering.

## Quick Solution

Reset the password to something simple and known:

```bash
# Reset password to something simple
gcloud sql users set-password zinpainghtet \
  --instance=test-postgresql \
  --password=Test123

# Run the migration script
./migrate-to-cloudsql.sh
```

When prompted, enter: `Test123`

## Why This Happens

Even if you think you know the password, it's possible:
1. The password was set differently when the user was created
2. The password has special characters that aren't being handled correctly
3. There was a typo when the password was originally set
4. The password was changed but you don't have the new one

## Step-by-Step

1. **Reset the password:**
   ```bash
   gcloud sql users set-password zinpainghtet \
     --instance=test-postgresql \
     --password=Test123
   ```

2. **Verify it was set:**
   ```bash
   gcloud sql users list --instance=test-postgresql
   ```
   (This won't show the password, but confirms the user exists)

3. **Run migration script:**
   ```bash
   ./migrate-to-cloudsql.sh
   ```

4. **Enter the password when prompted:** `Test123`

## After It Works

Once migrations work with the simple password, you can:
1. Change it to a more secure password if needed
2. Update your GitHub Secrets with the new DATABASE_URL
3. Continue with deployment

## Alternative: Use Postgres Root User

If you have the root password for the instance, you could also use the `postgres` user:

```bash
# Update the script's DB_USER to "postgres"
# Or create a new user with a known password
```

But the easiest is just to reset the existing user's password.
