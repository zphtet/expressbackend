# Fix: Removing GCP Service Account Key from Git History

GitHub blocked your push because `gcp-sa-key.json` (your GCP service account key) was committed to git. Here's how to fix it:

## Option 1: Remove from Last Commit (If only in the last commit)

If the file was only added in the last commit and you haven't pushed successfully yet:

```bash
# Remove the file from the last commit but keep it locally
git reset --soft HEAD~1
git reset HEAD gcp-sa-key.json
git commit -m "your commit message"
```

## Option 2: Remove from Multiple Commits (Using git filter-branch)

If the file is in multiple commits:

```bash
# Remove the file from all commits
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch gcp-sa-key.json" \
  --prune-empty --tag-name-filter cat -- --all

# Force push (WARNING: This rewrites history)
git push origin --force --all
```

## Option 3: Use BFG Repo-Cleaner (Recommended for cleaner history)

1. Install BFG: https://rtyley.github.io/bfg-repo-cleaner/
2. Run:
```bash
bfg --delete-files gcp-sa-key.json
git reflog expire --expire=now --all
git gc --prune=now --aggressive
```

## Important: Rotate Your Service Account Key

⚠️ **SECURITY ALERT**: Since the key was in your git history (even if not pushed), you should:

1. **Delete the old service account key** in GCP Console
2. **Create a new key** using the steps in `GCP-SERVICE-ACCOUNT-SETUP.md`
3. **Update GitHub Secrets** with the new key

## After Fixing:

1. Make sure `gcp-sa-key.json` is in `.gitignore` (it already is)
2. Remove the file from git history (use one of the options above)
3. Create a new service account key (old one should be considered compromised)
4. Update GitHub Secrets with the new key
5. Push again
