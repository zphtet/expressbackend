#!/bin/bash

# Quick test script to verify database connection
# This helps debug authentication issues

set -e

INSTANCE_NAME="test-postgresql"
DATABASE_NAME="testserver"
DB_USER="zinpainghtet"
PROJECT_ID="new-react-project-483118"

echo "🔍 Testing Cloud SQL Connection"
echo "================================"
echo ""

# Get public IP
PUBLIC_IP=$(gcloud sql instances describe ${INSTANCE_NAME} --format="value(ipAddresses[0].ipAddress)")
echo "📡 Cloud SQL IP: ${PUBLIC_IP}"
echo ""

# Prompt for password
read -sp "🔑 Enter password for user '${DB_USER}': " DB_PASSWORD
echo ""
echo ""

# Test 1: Show the connection string (without password)
echo "📋 Connection String (password hidden):"
echo "postgresql://${DB_USER}:***@${PUBLIC_IP}:5432/${DATABASE_NAME}?sslmode=no-verify"
echo ""

# Test 2: Try with URL encoding
echo "🔨 Testing URL encoding..."
ENCODED_PASSWORD=$(python3 -c "import urllib.parse, sys; print(urllib.parse.quote(sys.argv[1], safe=''))" "$DB_PASSWORD")
ENCODED_USER=$(python3 -c "import urllib.parse, sys; print(urllib.parse.quote(sys.argv[1], safe=''))" "$DB_USER")

echo "Original password length: ${#DB_PASSWORD}"
echo "Encoded password length: ${#ENCODED_PASSWORD}"
echo ""

# Test 3: Try connecting with Node.js/pg
echo "🔌 Testing connection..."
export DATABASE_URL="postgresql://${ENCODED_USER}:${ENCODED_PASSWORD}@${PUBLIC_IP}:5432/${DATABASE_NAME}?sslmode=no-verify"

# Check if pg is available
if npm list pg &> /dev/null || [ -d "node_modules/pg" ]; then
    node -e "
    const { Client } = require('pg');
    const client = new Client({
      connectionString: process.env.DATABASE_URL
    });
    client.connect()
      .then(() => {
        console.log('✅ Connection successful!');
        return client.query('SELECT version()');
      })
      .then(result => {
        console.log('📊 PostgreSQL version:', result.rows[0].version.split(',')[0]);
        client.end();
        process.exit(0);
      })
      .catch(err => {
        console.error('❌ Connection failed!');
        console.error('Error:', err.message);
        process.exit(1);
      });
    " 2>&1
else
    echo "⚠️  pg module not found. Installing..."
    npm install pg --no-save
    node -e "
    const { Client } = require('pg');
    const client = new Client({
      connectionString: process.env.DATABASE_URL
    });
    client.connect()
      .then(() => {
        console.log('✅ Connection successful!');
        client.end();
        process.exit(0);
      })
      .catch(err => {
        console.error('❌ Connection failed!');
        console.error('Error:', err.message);
        process.exit(1);
      });
    " 2>&1
fi

echo ""
echo "💡 If connection failed, try:"
echo "1. Verify the password is correct"
echo "2. Reset the password: gcloud sql users set-password ${DB_USER} --instance=${INSTANCE_NAME} --password=NEW_PASSWORD"
echo "3. Check if user has proper permissions"
