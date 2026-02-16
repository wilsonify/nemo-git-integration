# GPG Signing Setup for Releases

This guide explains how to set up GPG signing for nemo-git-integration releases, allowing users to verify that builds are authentically from you.

## Overview

When you create a tagged release (e.g., `v1.0.0`), the CI pipeline will:

1. Build `.deb` packages on Ubuntu 22.04 and 24.04
2. Sign each package with your GPG key
3. Create signed SHA256 checksums
4. Publish everything to GitHub Releases

## Step 1: Generate a GPG Key (if you don't have one)

```bash
# Generate a new GPG key
gpg --full-generate-key
```

Choose these options:

- **Kind**: RSA and RSA (default)
- **Key size**: 4096 bits
- **Validity**: 2 years (or your preference)
- **Real name**: Your Name
- **Email**: <your-email@example.com> (use your GitHub email)
- **Passphrase**: Choose a strong passphrase

## Step 2: Find Your Key ID

```bash
# List your keys
gpg --list-secret-keys --keyid-format=long

# Output will look like:
# sec   rsa4096/ABCD1234EFGH5678 2024-01-01 [SC] [expires: 2026-01-01]
#       FULL_KEY_FINGERPRINT_HERE
# uid           [ultimate] Your Name <your-email@example.com>
# ssb   rsa4096/WXYZ9876IJKL5432 2024-01-01 [E] [expires: 2026-01-01]
```

Your **Key ID** is the part after `rsa4096/` (e.g., `ABCD1234EFGH5678`).

## Step 3: Export Your Private Key

```bash
# Export the private key (keep this SECRET!)
gpg --armor --export-secret-keys YOUR_KEY_ID > private-key.asc

# View the contents (you'll need this for GitHub Secrets)
cat private-key.asc
```

⚠️ **IMPORTANT**: Delete `private-key.asc` after adding it to GitHub Secrets!

## Step 4: Add Secrets to GitHub Repository

Go to your repository → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**

Add these three secrets:

| Secret Name | Value |
|-------------|-------|
| `GPG_PRIVATE_KEY` | The entire contents of `private-key.asc` (including BEGIN/END lines) |
| `GPG_PASSPHRASE` | Your GPG key passphrase |
| `GPG_KEY_ID` | Your key ID (e.g., `ABCD1234EFGH5678`) |

## Step 5: Publish Your Public Key

Users need your public key to verify signatures.

### Option A: Upload to a keyserver

```bash
gpg --keyserver keyserver.ubuntu.com --send-keys YOUR_KEY_ID
gpg --keyserver keys.openpgp.org --send-keys YOUR_KEY_ID
```

### Option B: Export and add to your repository

```bash
# Export public key
gpg --armor --export YOUR_KEY_ID > public-key.asc
```

Add this file to your repository root or `docs/` folder.

### Option C: Add to GitHub profile

Go to GitHub → Settings → SSH and GPG keys → New GPG key, then paste your public key.

## Step 6: Create a Release

```bash
# Tag a version
git tag -s v1.0.0 -m "Release v1.0.0"

# Push the tag
git push origin v1.0.0
```

The CI pipeline will automatically:

1. Run all tests
2. Build packages for Ubuntu 22.04 and 24.04
3. Sign packages with your GPG key
4. Create checksums and sign them
5. Publish to GitHub Releases

## For Users: Verifying Downloads

### Step 1: Import the maintainer's public key

```bash
# From keyserver
gpg --keyserver keyserver.ubuntu.com --recv-keys MAINTAINER_KEY_ID

# Or from file
gpg --import public-key.asc
```

### Step 2: Verify the package signature

```bash
# Download the .deb and .deb.asc files
gpg --verify nemo-git-integration_1.0.0_all.deb.asc nemo-git-integration_1.0.0_all.deb
```

Expected output:

```
gpg: Signature made [date]
gpg:                using RSA key [KEY_ID]
gpg: Good signature from "Maintainer Name <email>"
```

### Step 3: Verify checksums

```bash
# Verify the signed checksum file
gpg --verify SHA256SUMS.gpg

# Check the package checksum
sha256sum -c SHA256SUMS
```

## Troubleshooting

### "gpg: signing failed: No secret key"

- Ensure `GPG_PRIVATE_KEY` secret contains the full private key including headers
- Verify `GPG_KEY_ID` matches your key

### "gpg: signing failed: Inappropriate ioctl for device"

- This is handled by the `--pinentry-mode loopback` flag in the workflow

### Key expired

- Generate a new key or extend your existing key's expiration
- Update the GitHub secrets with the new key

## Security Best Practices

1. **Use a dedicated signing key** - Don't use your personal GPG key
2. **Strong passphrase** - Use a unique, strong passphrase for the signing key
3. **Rotate keys** - Consider rotating keys every 1-2 years
4. **Backup securely** - Keep an encrypted backup of your private key offline
5. **Revocation certificate** - Generate and store a revocation certificate:

   ```bash
   gpg --gen-revoke YOUR_KEY_ID > revoke.asc
   ```

## Quick Reference

```bash
# Generate key
gpg --full-generate-key

# List keys
gpg --list-secret-keys --keyid-format=long

# Export private (for GitHub secret)
gpg --armor --export-secret-keys KEY_ID

# Export public (for users)
gpg --armor --export KEY_ID > public-key.asc

# Create signed tag
git tag -s v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0
```
