# Running Prisma Migrations from Local Machine

Step-by-step guide to run Prisma migrations to Cloud SQL from your local machine.

## Prerequisites

- gcloud CLI installed on your local machine
- Node.js and npm installed
- Your repository cloned locally
- Cloud SQL instance created

## Step 1: Get Your Local IP Address

First, find your public IP address:

```bash
# On Mac/Linux
curl ifconfig.me

# Or visit: https://whatismyipaddress.com/
```

Save this IP address - you'll need it in the next step.

## Step 2: Authorize Your IP to Access Cloud SQL

Authorize your local machine's IP address to connect to Cloud SQL:

```bash
# Replace YOUR_PUBLIC_IP with the IP from Step 1
gcloud sql instances patch express-backend-db \
  --authorized-networks=YOUR_PUBLIC_IP/32

# Example:
# gcloud sql instances patch express-backend-db \
#   --authorized-networks=123.45.67.89/32
```

**Note:** If you have a dynamic IP that changes, you'll need to repeat this step each time your IP changes.

## Step 3: Get Cloud SQL Public IP

Get the public IP address of your Cloud SQL instance:

```bash
gcloud sql instances describe express-backend-db \
  --format="value(ipAddresses[0].ipAddress)"
```

Save this IP - you'll use it in the DATABASE_URL.

## Step 4: Navigate to Your Project Directory

Make sure you're in your project directory:

```bash
cd /path/to/express-backend
# Or if you're already in the workspace:
cd /Users/Learning/express-backend
```

## Step 5: Install Dependencies (if not already installed)

```bash
npm install
```

## Step 6: Set DATABASE_URL Environment Variable

Set the DATABASE_URL using the Cloud SQL public IP:

```bash
# Replace with your actual values:
# - PUBLIC_IP: from Step 3
# - YOUR_PASSWORD: your database user password
# - testserver: your database name (if different)

export DATABASE_URL="postgresql://zinpainghtet:YOUR_PASSWORD@PUBLIC_IP:5432/testserver?sslmode=require"
```

**Example:**
```bash
export DATABASE_URL="postgresql://zinpainghtet:mypassword123@34.123.45.67:5432/testserver?sslmode=require"
```

## Step 7: Run Prisma Migrations

Now run the migrations:

```bash
# Generate Prisma Client (if needed)
npx prisma generate

# Run migrations
npx prisma migrate deploy
```

You should see output like:
```
Applying migration `20260109054838_init`
✅ Migration applied successfully
```

## Step 8: Verify Migration

Verify that tables were created:

```bash
# Option 1: Use Prisma Studio (opens in browser)
npx prisma studio

# Option 2: Connect with psql (if installed)
psql $DATABASE_URL -c "\dt"

# Option 3: Use a database GUI tool (pgAdmin, TablePlus, etc.)
# Connection details:
# - Host: PUBLIC_IP from Step 3
# - Port: 5432
# - Database: testserver
# - User: zinpainghtet
# - Password: YOUR_PASSWORD
# - SSL: Required
```

## Complete Example Script

Here's a complete script you can run locally:

```bash
#!/bin/bash

# Configuration
INSTANCE_NAME="express-backend-db"
DB_USER="zinpainghtet"
DB_PASSWORD="YOUR_PASSWORD"  # Update with your password
DB_NAME="testserver"

# Get your public IP
echo "🔍 Getting your public IP..."
MY_IP=$(curl -s ifconfig.me)
echo "✅ Your IP: $MY_IP"

# Authorize your IP
echo "🔐 Authorizing your IP to access Cloud SQL..."
gcloud sql instances patch $INSTANCE_NAME \
  --authorized-networks=$MY_IP/32

# Get Cloud SQL public IP
echo "📡 Getting Cloud SQL public IP..."
PUBLIC_IP=$(gcloud sql instances describe $INSTANCE_NAME \
  --format="value(ipAddresses[0].ipAddress)")
echo "✅ Cloud SQL IP: $PUBLIC_IP"

# Set DATABASE_URL
export DATABASE_URL="postgresql://${DB_USER}:${DB_PASSWORD}@${PUBLIC_IP}:5432/${DB_NAME}?sslmode=require"

# Run migrations
echo "🚀 Running migrations..."
npx prisma migrate deploy

echo "✅ Migrations complete!"
```

## Using .env File (Alternative)

Instead of exporting DATABASE_URL, you can use a `.env` file:

1. Create/update `.env` file:
```bash
DATABASE_URL="postgresql://zinpainghtet:YOUR_PASSWORD@PUBLIC_IP:5432/testserver?sslmode=require"
```

2. Run migrations:
```bash
npx prisma migrate deploy
```

**⚠️ Warning:** Make sure `.env` is in `.gitignore` (it already is)!

## Troubleshooting

### Error: "Connection refused" or "Timeout"

1. **Check if your IP is authorized:**
```bash
gcloud sql instances describe express-backend-db \
  --format="value(settings.ipConfiguration.authorizedNetworks)"
```

2. **Re-authorize your IP** (if it changed):
```bash
MY_IP=$(curl -s ifconfig.me)
gcloud sql instances patch express-backend-db \
  --authorized-networks=$MY_IP/32
```

3. **Check if the instance is running:**
```bash
gcloud sql instances describe express-backend-db \
  --format="value(state)"
```

Should show: `RUNNABLE`

### Error: "Authentication failed"

- Verify username and password are correct
- Check that the user exists in Cloud SQL:
```bash
gcloud sql users list --instance=express-backend-db
```

### Error: "Database does not exist"

- Make sure you created the database:
```bash
gcloud sql databases list --instance=express-backend-db
```

### Error: "SSL connection required"

- Make sure you include `?sslmode=require` in your DATABASE_URL
- Cloud SQL requires SSL connections

### Error: "Command not found: npx"

- Make sure Node.js is installed: `node --version`
- Install npm if needed
- Or use: `node_modules/.bin/prisma migrate deploy`

## Security: Remove Authorized IP After Migrations

After running migrations, you can optionally remove your IP from authorized networks for security:

```bash
# Remove all authorized networks (optional)
gcloud sql instances patch express-backend-db \
  --clear-authorized-networks

# Or remove a specific IP
gcloud sql instances patch express-backend-db \
  --remove-authorized-networks=YOUR_IP/32
```

**Note:** If you remove the authorized IP, you'll need to re-authorize it next time you want to run migrations from your local machine.

## Dynamic IP Address Issue

If your IP address changes frequently (home internet, VPN, etc.):

1. **Re-run the authorization** each time your IP changes
2. **Use Cloud Shell** instead (more stable)
3. **Set up a static IP** (advanced, requires VPN setup)
4. **Use Cloud SQL Proxy** (advanced alternative)

## Next Steps

After migrations are complete:

1. **Update Cloud Run service** to use Cloud SQL connection:
```bash
CONNECTION_NAME=$(gcloud sql instances describe express-backend-db \
  --format="value(connectionName)")

gcloud run services update express-backend-prod \
  --region=us-central1 \
  --add-cloudsql-instances=$CONNECTION_NAME \
  --set-env-vars DATABASE_URL="postgresql://zinpainghtet:YOUR_PASSWORD@/$DB_NAME?host=/cloudsql/$CONNECTION_NAME"
```

2. **Test your backend** - it should now connect to the database!

3. **Optional:** Remove your local IP from authorized networks for security
