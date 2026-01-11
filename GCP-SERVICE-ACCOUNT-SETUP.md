# How to Get GCP Service Account Key (GCP_SA_KEY)

This guide will walk you through creating a service account and generating a JSON key for GitHub Actions CI/CD.

## Step 1: Go to GCP Console

1. Open https://console.cloud.google.com
2. Select your project (or create one if you don't have one)
   - Project ID: `new-react-project-483118` (based on your workflow file)

## Step 2: Navigate to Service Accounts

1. In the left sidebar, go to **IAM & Admin** → **Service Accounts**
2. Or use this direct link: https://console.cloud.google.com/iam-admin/serviceaccounts

## Step 3: Create a New Service Account

1. Click the **"+ CREATE SERVICE ACCOUNT"** button at the top
2. Fill in the details:
   - **Service account name**: `github-actions-cloud-run` (or any name you prefer)
   - **Service account ID**: Will auto-populate (e.g., `github-actions-cloud-run`)
   - **Description**: `Service account for GitHub Actions CI/CD deployment`
3. Click **"CREATE AND CONTINUE"**

## Step 4: Grant Required Roles

Add the following roles to your service account (click "ADD ANOTHER ROLE" for each):

1. **Cloud Run Admin** (`roles/run.admin`)
   - Allows deploying and managing Cloud Run services

2. **Service Account User** (`roles/iam.serviceAccountUser`)
   - Allows the service account to act as other service accounts

3. **Artifact Registry Writer** (`roles/artifactregistry.writer`)
   - Allows pushing Docker images to Artifact Registry

4. **Storage Admin** (`roles/storage.admin`) - Optional but recommended
   - Full access to Cloud Storage (used by Artifact Registry)

After adding all roles, click **"CONTINUE"** then **"DONE"**.

## Step 5: Generate JSON Key

### Method 1: Using GCP Console (Browser)

1. Find your newly created service account in the list
2. Click on the service account email/name to open details
3. Go to the **"KEYS"** tab at the top
4. Click **"ADD KEY"** → **"Create new key"**
5. Select **JSON** format
6. Click **"CREATE"**
7. A JSON file should automatically download to your computer

**If the file doesn't download:**
- Check your browser's download settings (pop-ups might be blocked)
- Check your Downloads folder - it might have downloaded automatically
- Try a different browser (Chrome, Firefox, Safari)
- Disable browser extensions that block downloads
- Check browser console for errors (F12 → Console tab)

### Method 2: Using gcloud CLI (Recommended if browser doesn't work)

If the browser download doesn't work, use the command line instead (see "Alternative: Using gcloud CLI" section below)

## Step 6: Add to GitHub Secrets

1. Go to your GitHub repository
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Click **"New repository secret"**
4. Fill in:
   - **Name**: `GCP_SA_KEY`
   - **Value**: Open the downloaded JSON file, copy **ALL** its contents, and paste it here
5. Click **"Add secret"**

## Important Notes

⚠️ **Security Warning:**
- Never commit the JSON key file to your repository
- Keep the JSON file secure on your local machine
- If compromised, delete the service account and create a new one
- The JSON file contains sensitive credentials

## Verify the JSON Key Format

The JSON file should look like this:

```json
{
  "type": "service_account",
  "project_id": "new-react-project-483118",
  "private_key_id": "...",
  "private_key": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n",
  "client_email": "github-actions-cloud-run@new-react-project-483118.iam.gserviceaccount.com",
  "client_id": "...",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "..."
}
```

Make sure you copy the **entire** JSON content (including the opening `{` and closing `}`).

## Alternative: Using gcloud CLI (Recommended if browser download fails)

If the browser download doesn't work, use the command line instead:

```bash
# 1. Install gcloud CLI (if not already installed)
# Download from: https://cloud.google.com/sdk/docs/install

# 2. Login to GCP
gcloud auth login

# 3. Set your project
gcloud config set project new-react-project-483118

# 4. Create service account (skip if already created via console)
gcloud iam service-accounts create github-actions-cloud-run \
  --display-name="GitHub Actions CI/CD Service Account"

# 5. Get the service account email (adjust name if different)
SA_EMAIL="github-actions-cloud-run@new-react-project-483118.iam.gserviceaccount.com"

# 6. Grant required roles
gcloud projects add-iam-policy-binding new-react-project-483118 \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/run.admin"

gcloud projects add-iam-policy-binding new-react-project-483118 \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/iam.serviceAccountUser"

gcloud projects add-iam-policy-binding new-react-project-483118 \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/artifactregistry.writer"

gcloud projects add-iam-policy-binding new-react-project-483118 \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/storage.admin"

# 7. Create and save key to file
gcloud iam service-accounts keys create gcp-sa-key.json \
  --iam-account=${SA_EMAIL}

# 8. The key is now saved as gcp-sa-key.json in your current directory
# View the contents:
cat gcp-sa-key.json

# 9. Copy the entire JSON content and paste it into GitHub Secrets
```

**Note:** The `gcp-sa-key.json` file will be created in your current directory. Make sure to:
- Copy the entire file contents
- Delete the file after adding to GitHub Secrets (for security)
- Never commit this file to git

## Troubleshooting

**Issue: "Permission denied" when deploying**
- Make sure you've granted all required roles
- Wait a few minutes for IAM changes to propagate

**Issue: "Authentication failed"**
- Verify the JSON key is correctly copied (no extra spaces, complete JSON)
- Make sure the service account email matches the key

**Issue: "Artifact Registry access denied"**
- Ensure Artifact Registry API is enabled
- Verify the Artifact Registry Writer role is granted
