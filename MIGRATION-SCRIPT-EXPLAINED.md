# Migration Script Explanation

## What does `migrate-to-cloudsql.sh` do?

This script automates the process of running Prisma migrations to your Cloud SQL PostgreSQL database from your local machine.

## Step-by-Step Breakdown

### 1. **Prerequisites Check** (Lines 26-43)
   - Checks if `gcloud` CLI is installed
   - Checks if Node.js is installed
   - Checks if you're logged into Google Cloud
   - Sets your GCP project

### 2. **Verify Cloud SQL Instance** (Lines 49-72)
   - Checks if your instance `test-postgresql` exists
   - Verifies the instance is running (state = RUNNABLE)
   - Waits for the instance if it's starting up

### 3. **Get Cloud SQL Public IP** (Lines 74-85)
   - Gets the public IP address of your Cloud SQL instance
   - This IP is needed to connect from your local machine

### 4. **Authorize Your Local IP** (Lines 87-109)
   - Automatically detects your local machine's public IP
   - Authorizes your IP to access Cloud SQL
   - Cloud SQL requires authorized IPs for security
   - Skips if your IP is already authorized

### 5. **Database Password** (Lines 111-120)
   - Prompts you to enter your database user password
   - Password is entered securely (won't show on screen)

### 6. **Verify Database** (Lines 122-130)
   - Checks if database `testserver` exists
   - Creates it if it doesn't exist (safety check)

### 7. **Install Dependencies** (Lines 132-136)
   - Checks if `node_modules` exists
   - Runs `npm install` if needed

### 8. **Run Migrations** (Lines 138-149)
   - Sets up DATABASE_URL environment variable
   - Generates Prisma Client
   - Runs `npx prisma migrate deploy` to apply migrations

### 9. **Success Message** (Lines 151-166)
   - Shows connection details
   - Provides next steps

## Configuration Variables

At the top of the script, these are pre-configured:

```bash
INSTANCE_NAME="test-postgresql"    # Your Cloud SQL instance name
DATABASE_NAME="testserver"         # Your database name
DB_USER="zinpainghtet"             # Database username
PROJECT_ID="new-react-project-483118"  # Your GCP project ID
```

**You may need to update:**
- `DB_USER`: Only if your database username is different from `zinpainghtet`

## How to Use

### Simple: Just Run It!

```bash
./migrate-to-cloudsql.sh
```

That's it! The script will:
1. ✅ Check everything automatically
2. ✅ Authorize your IP
3. ✅ Prompt you for the password (once)
4. ✅ Run the migrations

### What You Need Before Running:

1. **Cloud SQL instance created** ✅ (You already have `test-postgresql`)
2. **Database created** ✅ (You already have `testserver`)
3. **Database user created** (Make sure `zinpainghtet` user exists, or update the script)
4. **Know the database password** (You'll be prompted)

### Example Run:

```bash
$ ./migrate-to-cloudsql.sh

🚀 Prisma Migration to Cloud SQL
================================

📁 Setting project to: new-react-project-483118
🔍 Checking Cloud SQL instance...
📡 Getting Cloud SQL public IP...
✅ Cloud SQL IP: 34.123.45.67\
🔐 Authorizing local IP address...
   Your IP: 123.45.67.89
   Authorizing IP...
✅ IP authorized

🔑 Enter database password for user 'zinpainghtet': [hidden input]

💾 Checking database 'testserver'...
✅ Database exists
🔨 Generating Prisma Client...
🚀 Running Prisma migrations...
==================================
Applying migration `20260109054838_init`
✅ Migrations completed successfully!

📋 Connection Details:
================================
Instance: test-postgresql
Database: testserver
User: zinpainghtet
Host: 34.123.45.67

⚠️  Next Steps:
1. Update your Cloud Run service to use Cloud SQL connection
2. Update DATABASE_URL in GitHub Secrets for CI/CD
...
```

## Common Questions

### Q: Do I need to do anything before running?
**A:** Just make sure:
- You have the database user password ready
- Your Cloud SQL instance is running
- You're logged into gcloud (`gcloud auth login`)

### Q: Will it ask for my password every time?
**A:** Yes, for security. The script doesn't store passwords.

### Q: What if my IP changes?
**A:** The script will automatically detect your new IP and authorize it.

### Q: Can I run it multiple times?
**A:** Yes! Prisma migrations are idempotent - running them multiple times is safe.

### Q: What if I get an error?
**A:** The script will show you what went wrong. Common issues:
- Instance not found → Check instance name
- Wrong password → Re-run with correct password
- Network error → Check if instance has public IP enabled

## Safety Features

✅ **Error handling**: Script stops if any step fails  
✅ **No hardcoded passwords**: Password is prompted securely  
✅ **Idempotent**: Safe to run multiple times  
✅ **Automatic checks**: Verifies everything before proceeding  
✅ **Clear output**: Color-coded messages show progress  

## That's It!

Yes, you just need to run:
```bash
./migrate-to-cloudsql.sh
```

The script handles everything else! 🚀
