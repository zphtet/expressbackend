# Fix Authentication Error

## Status Check
✅ User `zinpainghtet` exists in Cloud SQL  
✅ Database `testserver` should exist

## The Problem
The authentication error means the **password is incorrect**. The user exists, but the password you entered doesn't match.

## Solutions

### Option 1: Reset the Password (Recommended)

Reset the password for the existing user:

```bash
# Reset the password
gcloud sql users set-password zinpainghtet \
  --instance=test-postgresql \
  --password=YOUR_NEW_PASSWORD

# Then run the migration script again with the new password
./migrate-to-cloudsql.sh
```

### Option 2: Check Current Password

If you forgot what password you set:
- Check your notes/password manager
- Or reset it using Option 1 above

### Option 3: Test Connection Manually

You can test the connection manually to verify:

```bash
# Get the public IP
PUBLIC_IP=$(gcloud sql instances describe test-postgresql --format="value(ipAddresses[0].ipAddress)")

# Test with psql (if installed)
psql "postgresql://zinpainghtet:YOUR_PASSWORD@$PUBLIC_IP:5432/testserver?sslmode=require" -c "SELECT 1;"

# Or test with a simple Node.js script
node -e "
const { Client } = require('pg');
const client = new Client({
  connectionString: 'postgresql://zinpainghtet:YOUR_PASSWORD@$PUBLIC_IP:5432/testserver?sslmode=require'
});
client.connect().then(() => {
  console.log('✅ Connection successful!');
  client.end();
}).catch(err => {
  console.error('❌ Connection failed:', err.message);
  process.exit(1);
});
"
```

## Quick Fix Steps

1. **Reset the password:**
   ```bash
   gcloud sql users set-password zinpainghtet \
     --instance=test-postgresql \
     --password=YourNewSecurePassword123
   ```

2. **Run migration script again:**
   ```bash
   ./migrate-to-cloudsql.sh
   ```
   (Enter the new password when prompted)

## Notes

- The user exists, so you just need the correct password
- If you don't remember the password, reset it (Option 1)
- Make sure to use the same password when running the migration script
