#!/bin/bash

# Seed script for initial test data
# Creates 10 users, 10 posts, and 10 books

echo "Starting database seeding..."

# Check if DATABASE_URL is set
if [ -z "$DATABASE_URL" ]; then
  echo "Error: DATABASE_URL environment variable is not set"
  echo "Please set it in your .env file or export it before running this script"
  exit 1
fi

# Run the TypeScript seed file using tsx
npx tsx seed.ts

if [ $? -eq 0 ]; then
  echo "✅ Seeding completed successfully!"
else
  echo "❌ Seeding failed!"
  exit 1
fi
