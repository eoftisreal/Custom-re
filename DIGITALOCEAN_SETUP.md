# DigitalOcean Droplet Setup Guide for CoinOS Builds

This guide walks you through provisioning a DigitalOcean Droplet, registering it
as a GitHub Actions self-hosted runner, and configuring DigitalOcean Spaces for
artifact storage — so you can build CoinOS without the disk-space constraints of
GitHub-hosted runners.

---

## Table of Contents

1. [Recommended Droplet Specifications](#1-recommended-droplet-specifications)
2. [Create the Droplet](#2-create-the-droplet)
3. [Initialize the Build Environment](#3-initialize-the-build-environment)
4. [Register as a GitHub Actions Self-Hosted Runner](#4-register-as-a-github-actions-self-hosted-runner)
5. [Configure DigitalOcean Spaces (Artifact Storage)](#5-configure-digitalocean-spaces-artifact-storage)
6. [Set GitHub Actions Secrets](#6-set-github-actions-secrets)
7. [Trigger a Build](#7-trigger-a-build)
8. [Storage Management](#8-storage-management)
9. [Cost Estimates](#9-cost-estimates)
10. [Troubleshooting](#10-troubleshooting)

---

## 1. Recommended Droplet Specifications

| Resource | Minimum | Recommended |
|----------|---------|-------------|
| vCPU     | 4       | **8**       |
| RAM      | 8 GB    | **16 GB**   |
| Disk     | 100 GB  | **200 GB**  |
| OS       | Ubuntu 22.04 LTS | Ubuntu 22.04 LTS |
| Region   | Nearest to you | `sfo3` / `nyc3` |

**DigitalOcean slug:** `s-8vcpu-16gb` (~$96/month on-demand, ~$0.143/hour)

> **Tip:** Use a Droplet Snapshot to save the configured state. You can destroy the
> Droplet after a build run and restore from the snapshot next time to save costs
> when builds are infrequent.

---

## 2. Create the Droplet

### Using the DigitalOcean CLI (`doctl`)

```bash
# Install doctl if needed
# https://docs.digitalocean.com/reference/doctl/how-to/install/

# Authenticate
doctl auth init

# Create the Droplet (replace YOUR_SSH_KEY_ID with your key fingerprint)
doctl compute droplet create coinos-builder \
  --region sfo3 \
  --size s-8vcpu-16gb \
  --image ubuntu-22-04-x64 \
  --ssh-keys YOUR_SSH_KEY_ID \
  --tag-names coinos-ci \
  --wait

# Get the Droplet IP
doctl compute droplet get coinos-builder --format PublicIPv4
```

### Using the DigitalOcean Web Console

1. Go to **Create → Droplets**
2. Choose **Ubuntu 22.04 (LTS) x64**
3. Select plan: **Basic → Premium Intel → 8 vCPU / 16 GB / 200 GB NVMe SSD**
4. Choose a datacenter region
5. Add your SSH key
6. Click **Create Droplet**

---

## 3. Initialize the Build Environment

SSH into the new Droplet as `root` and run the initialization script:

```bash
ssh root@<DROPLET_IP>

# Option A — Run directly from the repository
curl -fL https://raw.githubusercontent.com/eoftisreal/Custom-re/main/scripts/do-build-init.sh | bash

# Option B — Clone the repo first then run the script
git clone https://github.com/eoftisreal/Custom-re.git /tmp/custom-re
bash /tmp/custom-re/scripts/do-build-init.sh
```

The script will:

- Update system packages
- Install all Android build dependencies (OpenJDK 11, ccache, repo, s3cmd, etc.)
- Create a dedicated `builder` system user
- Create the workspace at `/opt/coinos-build/workspace`
- Configure ccache with a 100 GB cache
- Generate an SSH key for GitHub access
- Print the public key for you to add to GitHub

### Add the SSH Public Key to GitHub

After the script finishes, copy the printed public key and add it:

1. GitHub → **Settings → SSH and GPG keys → New SSH key**
2. Title: `coinos-do-runner`
3. Paste the key → **Add SSH key**

---

## 4. Register as a GitHub Actions Self-Hosted Runner

1. In your GitHub repository, go to **Settings → Actions → Runners → New self-hosted runner**
2. Select **Linux** / **x64**
3. Follow the displayed commands on the Droplet (as the `builder` user):

```bash
# Switch to builder user
su - builder

# Download the runner
# Note: check https://github.com/actions/runner/releases for the latest version
mkdir -p ~/actions-runner && cd ~/actions-runner
curl -o actions-runner-linux-x64.tar.gz -L \
  https://github.com/actions/runner/releases/download/v2.317.0/actions-runner-linux-x64-2.317.0.tar.gz
tar xzf actions-runner-linux-x64.tar.gz

# Configure the runner (use the token shown on GitHub)
./config.sh \
  --url https://github.com/eoftisreal/Custom-re \
  --token <YOUR_REGISTRATION_TOKEN> \
  --name coinos-do-runner \
  --labels self-hosted,linux,x64,digitalocean \
  --work /opt/coinos-build/runner-work \
  --unattended

# Install and start the runner service
sudo ./svc.sh install builder
sudo ./svc.sh start
```

Verify the runner is online: GitHub → **Settings → Actions → Runners** — you should see
`coinos-do-runner` with a green **Idle** status.

---

## 5. Configure DigitalOcean Spaces (Artifact Storage)

Spaces is DigitalOcean's S3-compatible object storage. Build artifacts are uploaded
there by the workflow so they persist independently of the Droplet.

### Create a Space

```bash
# Via doctl
doctl spaces create coinos-builds --region nyc3

# Or via the web console:
# Create → Spaces → name: coinos-builds, region: nyc3
```

### Create API Keys for Spaces Access

1. Go to **API → Spaces Keys → Generate New Key**
2. Name: `coinos-ci`
3. Note the **Access Key** and **Secret Key** — you will need them in step 6

---

## 6. Set GitHub Actions Secrets

In your repository: **Settings → Secrets and variables → Actions → New repository secret**

| Secret name           | Description                                      | Required |
|-----------------------|--------------------------------------------------|----------|
| `DO_SPACES_KEY`       | DigitalOcean Spaces access key                   | Optional |
| `DO_SPACES_SECRET`    | DigitalOcean Spaces secret key                   | Optional |
| `DO_SPACES_BUCKET`    | Spaces bucket name (e.g. `coinos-builds`)        | Optional |
| `DO_SPACES_REGION`    | Spaces region (e.g. `nyc3`)                      | Optional |
| `SLACK_WEBHOOK_URL`   | Slack incoming webhook URL for notifications     | Optional |
| `NOTIFY_EMAIL`        | Destination email for build completion emails    | Optional |
| `SENDGRID_API_KEY`    | SendGrid API key for email delivery              | Optional |

Artifact upload to Spaces is silently skipped if `DO_SPACES_KEY` / `DO_SPACES_SECRET`
are not set — builds still succeed and artifacts are uploaded to GitHub.

---

## 7. Trigger a Build

### Via GitHub Actions UI

1. Go to **Actions → Build CoinOS for Samsung Galaxy J7 (j7xelte) — DigitalOcean**
2. Click **Run workflow**
3. Optionally enable Slack/email notifications or a clean build

### Via GitHub CLI

```bash
# Trigger with defaults
gh workflow run build-coinos-digitalocean.yml

# Trigger a clean build with Slack notification
gh workflow run build-coinos-digitalocean.yml \
  -f clean_build=true \
  -f notify_slack=true
```

---

## 8. Storage Management

Build ZIPs accumulate over time. Use the cleanup script to manage disk space:

```bash
# Preview what would be deleted (dry run)
DRY_RUN=true bash /path/to/scripts/cleanup-old-builds.sh

# Delete builds older than 30 days, keep latest 3
bash /path/to/scripts/cleanup-old-builds.sh

# Archive to Spaces before deleting, keep latest 5, delete after 14 days
DO_SPACES_KEY=<key> DO_SPACES_SECRET=<secret> \
MAX_AGE_DAYS=14 KEEP_LATEST=5 \
bash /path/to/scripts/cleanup-old-builds.sh
```

### Automated Cleanup (cron)

Add to `builder`'s crontab to run every Sunday at midnight:

```cron
0 0 * * 0 bash /opt/coinos-build/scripts/cleanup-old-builds.sh >> /var/log/coinos-cleanup.log 2>&1
```

---

## 9. Cost Estimates

| Resource | Size | Est. monthly cost |
|----------|------|------------------|
| Droplet (on-demand) | s-8vcpu-16gb | ~$96 |
| Spaces storage | 100 GB | ~$5 |
| Spaces bandwidth | 1 TB included | $0 |
| **Total** | | **~$101 / month** |

**Cost-saving tip:** Take a Droplet Snapshot (~$0.06/GB/month) and destroy the
Droplet between builds. Restore from snapshot when needed to pay only for compute
time you actually use.

---

## 10. Troubleshooting

### Runner shows "Offline" in GitHub

```bash
# Check runner service status
sudo systemctl status actions.runner.*.service

# Restart runner
sudo ./svc.sh stop && sudo ./svc.sh start
```

### repo sync fails

```bash
# Check available disk space
df -h /opt/coinos-build

# Remove stale lock files and retry
find /opt/coinos-build/workspace -name "*.lock" -delete
cd /opt/coinos-build/workspace && repo sync -c -j8 --force-sync
```

### ccache not being used

```bash
# Verify environment variables
echo $USE_CCACHE $CCACHE_DIR

# Check ccache stats
ccache -s
```

### Spaces upload fails

```bash
# Test credentials manually
s3cmd --access_key=<key> --secret_key=<secret> \
  --host=nyc3.digitaloceanspaces.com \
  --host-bucket='%(bucket)s.nyc3.digitaloceanspaces.com' \
  ls s3://coinos-builds/
```

### Out of disk space during build

```bash
# Immediate cleanup
bash /opt/coinos-build/scripts/cleanup-old-builds.sh

# Check ccache size
ccache -s | grep "Cache size"

# Reduce ccache if needed
ccache -M 50G
```
