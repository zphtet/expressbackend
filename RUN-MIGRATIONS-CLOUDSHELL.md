# Running Prisma Migrations from Cloud Shell

Step-by-step guide to run Prisma migrations using Google Cloud Shell.

## Step 1: Access Cloud Shell

1. Go to: https://shell.cloud.google.com
2. Or click the Cloud Shell icon (terminal icon) in the top right of GCP Console
3. Cloud Shell will open in a browser terminal

## Step 2: Clone Your Repository

You have a few options to get your code:

### Option A: Clone from GitHub (Recommended)

If your repository is on GitHub:

```bash
# Clone your repository
git clone https://github.com/YOUR_USERNAME/express-backend.git

# Replace YOUR_USERNAME with your GitHub username
# Example: git clone https://github.com/zphtet/expressbackend.git

# Navigate to the project directory
cd express-backend
```

**If your repo is private**, you'll need to authenticate:
- GitHub will prompt you to authenticate
- Or use a personal access token: `git clone https://TOKEN@github.com/username/repo.git`

### Option B: Upload Files Manually

If you can't clone (or repo is private and you don't have access set up):

1. In Cloud Shell, create a directory:
```bash
mkdir express-backend
cd express-backend
```

2. Use the Cloud Shell Editor:
   - Click the "Open Editor" button (pencil icon) in Cloud Shell
   - Create files and folders as needed
   - Upload your `prisma/` folder and `package.json`

3. Or use `curl` to download specific files:
```bash
# Download package.json (if public)
curl -O https://raw.githubusercontent.com/YOUR_USERNAME/express-backend/main/package.json

# Download prisma schema (if public)
mkdir -p prisma
curl -O https://raw.githubusercontent.com/YOUR_USERNAME/express-backend/main/prisma/schema.prisma
```

## Step 3: Get Your Cloud SQL Public IP

First, authorize Cloud Shell's IP and get your database public IP:

```bash
# Get your current IP (Cloud Shell's IP)
MY_IP=$(curl -s ifconfig.me)
echo "Your Cloud Shell IP: $MY_IP"

# Authorize Cloud Shell's IP to access Cloud SQL
gcloud sql instances patch express-backend-db \
  --authorized-networks=$MY_IP/32

# Get the public IP of your Cloud SQL instance
PUBLIC_IP=$(gcloud sql instances describe express-backend-db \
  --format="value(ipAddresses[0].ipAddress)")

echo "Cloud SQL Public IP: $PUBLIC_IP"
```

## Step 4: Set Up Node.js and Install Dependencies

Cloud Shell comes with Node.js, but verify and install dependencies:

```bash
# Check Node.js version (should be installed)
node --version

# Install dependencies
npm install
```

## Step 5: Set DATABASE_URL Environment Variable

Set the DATABASE_URL using the public IP:

```bash
# Set DATABASE_URL (replace with your actual credentials)
export DATABASE_URL="postgresql://zinpainghtet:YOUR_PASSWORD@$PUBLIC_IP:5432/testserver?sslmode=require"

# Replace:
# - zinpainghtet with your database username
# - YOUR_PASSWORD with your database user password
# - testserver with your database name
```

**Example:**
```bash
export DATABASE_URL="postgresql://zinpainghtet:mypassword123@34.123.45.67:5432/testserver?sslmode=require"
```

## Step 6: Run Prisma Migrations

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
```

## Step 7: Verify Migration

Verify that tables were created:

```bash
# Connect to the database and list tables
npx prisma studio

# Or use psql (if installed in Cloud Shell)
# psql $DATABASE_URL -c "\dt"
```

## Alternative: Using psql Directly

If you prefer using `psql` directly:

```bash
# Install PostgreSQL client (if not installed)
sudo apt-get update
sudo apt-get install -y postgresql-client

# Connect to database
psql "postgresql://zinpainghtet:YOUR_PASSWORD@$PUBLIC_IP:5432/testserver?sslmode=require"

# Once connected, you can run SQL commands:
# \dt  (list tables)
# \q   (quit)
```

## Complete Example Script

Here's a complete script you can run in Cloud Shell:

```bash
#!/bin/bash

# Configuration
GITHUB_REPO="https://github.com/zphtet/expressbackend.git"  # Update with your repo
DB_USER="zinpainghtet"
DB_PASSWORD="YOUR_PASSWORD"  # Update with your password
DB_NAME="testserver"
INSTANCE_NAME="express-backend-db"

# Clone repository
echo "📥 Cloning repository..."
git clone $GITHUB_REPO
cd express-backend  # or expressbackend, adjust based on your repo name

# Get Cloud SQL public IP
echo "🔍 Getting Cloud SQL public IP..."
MY_IP=$(curl -s ifconfig.me)
gcloud sql instances patch $INSTANCE_NAME --authorized-networks=$MY_IP/32

PUBLIC_IP=$(gcloud sql instances describe $INSTANCE_NAME \
  --format="value(ipAddresses[0].ipAddress)")

echo "✅ Cloud SQL IP: $PUBLIC_IP"

# Install dependencies
echo "📦 Installing dependencies..."
npm install

# Set DATABASE_URL
export DATABASE_URL="postgresql://${DB_USER}:${DB_PASSWORD}@${PUBLIC_IP}:5432/${DB_NAME}?sslmode=require"

# Run migrations
echo "🚀 Running migrations..."
npx prisma migrate deploy

echo "✅ Migrations complete!"
```

## Troubleshooting

### Error: "Connection refused"
- Make sure you authorized Cloud Shell's IP (Step 3)
- Verify the Cloud SQL instance is running
- Check firewall rules

### Error: "Authentication failed"
- Verify username and password are correct
- Check that the user exists in Cloud SQL

### Error: "Database does not exist"
- Make sure you created the database in Cloud SQL
- Verify the database name in DATABASE_URL

### Error: "Command not found: npx"
- Run: `npm install -g npm@latest`
- Or use: `node_modules/.bin/prisma migrate deploy`

### Private Repository Issues
- Use a GitHub personal access token
- Or upload files manually using Cloud Shell Editor

## After Migrations

Once migrations are complete:

1. **Remove authorized IP** (optional, for security):
```bash
gcloud sql instances patch express-backend-db \
  --clear-authorized-networks
```

2. **Update Cloud Run service** to use the Cloud SQL connection:
```bash
CONNECTION_NAME=$(gcloud sql instances describe express-backend-db \
  --format="value(connectionName)")

gcloud run services update express-backend-prod \
  --region=us-central1 \
  --add-cloudsql-instances=$CONNECTION_NAME \
  --set-env-vars DATABASE_URL="postgresql://zinpainghtet:YOUR_PASSWORD@/$DB_NAME?host=/cloudsql/$CONNECTION_NAME"
```

3. **Test your backend** - it should now connect to the database!
