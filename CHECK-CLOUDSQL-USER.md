# Troubleshooting Cloud SQL Authentication Error

## Error: Authentication failed

This means the database user `zinpainghtet` either:
1. Doesn't exist in your Cloud SQL instance
2. Has a different password than what you entered
3. Doesn't have access to the `testserver` database

## How to Check/Create the User

### Option 1: Using gcloud CLI (Recommended)

```bash
# List all users in your Cloud SQL instance
gcloud sql users list --instance=test-postgresql

# If the user doesn't exist, create it:
gcloud sql users create zinpainghtet \
  --instance=test-postgresql \
  --password=YOUR_PASSWORD

# If the user exists but password is wrong, reset it:
gcloud sql users set-password zinpainghtet \
  --instance=test-postgresql \
  --password=YOUR_NEW_PASSWORD
```

### Option 2: Using GCP Console

1. Go to: https://console.cloud.google.com/sql/instances/test-postgresql
2. Click on the **"USERS"** tab
3. Check if `zinpainghtet` user exists
4. If not, click **"ADD USER ACCOUNT"**:
   - Username: `zinpainghtet`
   - Password: Enter a password
   - Click **"ADD"**
5. If it exists, you can click on it and reset the password

## Verify Database Access

The user should automatically have access to all databases, but you can verify:

```bash
# Connect to the database using the postgres user (if you have the root password)
# Or verify the user exists and can connect
```

## Common Issues

1. **User doesn't exist** - Create it using the commands above
2. **Wrong password** - Reset the password
3. **User exists but typo in username** - Double-check the username in the script
4. **Database doesn't exist** - Verify database exists: `gcloud sql databases list --instance=test-postgresql`

## Quick Fix Script

Run this to check and create the user if needed:

```bash
# Check if user exists
if gcloud sql users list --instance=test-postgresql --format="value(name)" | grep -q "^zinpainghtet$"; then
    echo "✅ User exists"
    echo "If password is wrong, reset it with:"
    echo "gcloud sql users set-password zinpainghtet --instance=test-postgresql --password=YOUR_PASSWORD"
else
    echo "❌ User doesn't exist. Create it with:"
    echo "gcloud sql users create zinpainghtet --instance=test-postgresql --password=YOUR_PASSWORD"
fi
```
