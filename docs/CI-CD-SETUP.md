# CI/CD Setup Guide for Postiz

This guide explains how to set up and use the automated CI/CD pipeline for Postiz using GitHub Actions and Google Cloud Run.

## 🚀 Overview

The CI/CD pipeline automates:
- **Quality Checks**: Linting, type checking, and testing
- **Docker Image Building**: Multi-service container builds
- **Automated Deployment**: Staging and production deployments
- **Health Checks**: Post-deployment verification

## 📋 Prerequisites

### 1. Google Cloud Setup

1. **Create a Google Cloud Project** (if not already done):
   ```bash
   gcloud projects create postiz-mcp-20250929 --name="Postiz MCP"
   ```

2. **Enable Required APIs**:
   ```bash
   gcloud services enable cloudbuild.googleapis.com
   gcloud services enable run.googleapis.com
   gcloud services enable containerregistry.googleapis.com
   ```

3. **Create a Service Account**:
   ```bash
   gcloud iam service-accounts create postiz-cicd \
     --display-name="Postiz CI/CD Service Account"
   ```

4. **Grant Required Permissions**:
   ```bash
   gcloud projects add-iam-policy-binding postiz-mcp-20250929 \
     --member="serviceAccount:postiz-cicd@postiz-mcp-20250929.iam.gserviceaccount.com" \
     --role="roles/run.admin"
   
   gcloud projects add-iam-policy-binding postiz-mcp-20250929 \
     --member="serviceAccount:postiz-cicd@postiz-cicd@postiz-mcp-20250929.iam.gserviceaccount.com" \
     --role="roles/storage.admin"
   
   gcloud projects add-iam-policy-binding postiz-mcp-20250929 \
     --member="serviceAccount:postiz-cicd@postiz-mcp-20250929.iam.gserviceaccount.com" \
     --role="roles/iam.serviceAccountUser"
   ```

5. **Create and Download Service Account Key**:
   ```bash
   gcloud iam service-accounts keys create postiz-cicd-key.json \
     --iam-account=postiz-cicd@postiz-mcp-20250929.iam.gserviceaccount.com
   ```

### 2. GitHub Repository Setup

1. **Go to Repository Settings** → **Secrets and variables** → **Actions**

2. **Add the following secrets**:

   | Secret Name | Description | Value |
   |-------------|-------------|-------|
   | `GCP_SA_KEY` | Google Cloud Service Account Key | Contents of `postiz-cicd-key.json` |
   | `GITHUB_CLIENT_ID` | GitHub OAuth Client ID | `Ov23liGW2IXy2y8G66Ej` |
   | `GITHUB_CLIENT_SECRET` | GitHub OAuth Client Secret | `a0aa109a2026596ef7a8b2be481ed81c01add68e` |

3. **Set up Environment Protection Rules**:
   - Go to **Settings** → **Environments**
   - Create `staging` environment
   - Create `production` environment
   - Add protection rules as needed (required reviewers, etc.)

## 🔧 Configuration

### Environment Variables

The pipeline uses these environment variables (configured in the workflow file):

```yaml
env:
  NODE_VERSION: '20.17.0'
  PNPM_VERSION: '10.6.1'
  REGISTRY: gcr.io
  PROJECT_ID: postiz-mcp-20250929
  REGION: us-central1
```

### Service Configuration

Each service is configured with specific resource allocations:

| Service | Memory | CPU | Max Instances | Port |
|---------|--------|-----|---------------|------|
| Backend | 1Gi | 1 | 10 (prod) / 5 (staging) | 3001 |
| Frontend | 512Mi | 1 | 5 (prod) / 3 (staging) | 3000 |
| Workers | 512Mi | 1 | 3 (prod) / 2 (staging) | 3003 |

## 🚦 Pipeline Triggers

### Automatic Triggers

1. **Push to `main` branch**: Deploys to production
2. **Push to `develop` branch**: Deploys to staging
3. **Pull Requests**: Runs quality checks only

### Manual Triggers

Use the **Actions** tab in GitHub to manually trigger deployments:

1. Go to **Actions** → **CI/CD Pipeline**
2. Click **Run workflow**
3. Select:
   - **Environment**: `staging` or `production`
   - **Services**: Comma-separated list (e.g., `backend,frontend,workers`)

## 📊 Pipeline Stages

### 1. Quality Checks
- **Dependencies**: Installs pnpm dependencies with caching
- **Linting**: Code quality checks (if configured)
- **Type Checking**: TypeScript validation (if configured)
- **Testing**: Runs Jest test suite
- **Artifacts**: Uploads test results

### 2. Build Images
- **Matrix Strategy**: Builds all three services in parallel
- **Docker Build**: Creates optimized production images
- **Registry Push**: Pushes to Google Container Registry
- **Tagging**: Tags with commit SHA and `latest`

### 3. Deploy Staging
- **Trigger**: Push to `develop` branch
- **Services**: Deploys all services to staging environment
- **Environment**: Sets `NODE_ENV=staging`
- **URLs**: Uses staging-specific URLs

### 4. Deploy Production
- **Trigger**: Push to `main` branch
- **Services**: Deploys all services to production environment
- **Environment**: Sets `NODE_ENV=production`
- **Secrets**: Uses production secrets from GitHub

### 5. Health Check
- **Verification**: Tests deployed services
- **Status**: Reports deployment success/failure

## 🔍 Monitoring and Debugging

### Viewing Pipeline Status

1. **GitHub Actions Tab**: View all pipeline runs
2. **Individual Jobs**: Click on specific jobs for detailed logs
3. **Artifacts**: Download test results and build artifacts

### Common Issues

1. **Service Account Permissions**:
   ```bash
   # Verify permissions
   gcloud projects get-iam-policy postiz-mcp-20250929
   ```

2. **Docker Build Failures**:
   - Check Dockerfile syntax
   - Verify dependencies in package.json
   - Review build logs in GitHub Actions

3. **Deployment Failures**:
   - Check Cloud Run service logs
   - Verify environment variables
   - Review service account permissions

### Logs and Debugging

1. **GitHub Actions Logs**: Available in the Actions tab
2. **Cloud Run Logs**: 
   ```bash
   gcloud logging read "resource.type=cloud_run_revision" --limit=50
   ```
3. **Service Health**: Check service URLs manually

## 🛠️ Customization

### Adding New Services

1. **Create Dockerfile**: Add `Dockerfile.newservice`
2. **Update Matrix**: Add service to build matrix
3. **Add Deployment**: Include in deploy stages
4. **Update Documentation**: Document new service

### Environment-Specific Configuration

Modify the workflow file to add environment-specific settings:

```yaml
- name: Deploy Custom Service
  run: |
    gcloud run deploy postiz-custom \
      --image ${{ env.REGISTRY }}/${{ env.PROJECT_ID }}/postiz-custom:${{ github.sha }} \
      --region ${{ env.REGION }} \
      --platform managed \
      --set-env-vars CUSTOM_VAR=${{ secrets.CUSTOM_SECRET }}
```

### Adding Quality Gates

Add additional checks before deployment:

```yaml
- name: Security Scan
  run: pnpm audit --audit-level moderate

- name: Performance Test
  run: pnpm run test:performance
```

## 📈 Best Practices

### Branch Strategy

- **`main`**: Production-ready code
- **`develop`**: Integration branch for staging
- **Feature branches**: Individual features

### Deployment Strategy

- **Staging First**: Always test in staging before production
- **Rollback Plan**: Keep previous image tags for quick rollback
- **Health Checks**: Verify deployments before marking complete

### Security

- **Secrets Management**: Use GitHub Secrets for sensitive data
- **Service Accounts**: Minimal required permissions
- **Image Scanning**: Consider adding vulnerability scanning

## 🔄 Rollback Procedures

### Quick Rollback

1. **Find Previous Image**:
   ```bash
   gcloud container images list-tags gcr.io/postiz-mcp-20250929/postiz-backend
   ```

2. **Redeploy Previous Version**:
   ```bash
   gcloud run deploy postiz-backend \
     --image gcr.io/postiz-mcp-20250929/postiz-backend:PREVIOUS_SHA \
     --region us-central1
   ```

### Automated Rollback

Add rollback job to the workflow:

```yaml
rollback:
  name: Rollback Deployment
  runs-on: ubuntu-latest
  if: failure()
  steps:
    - name: Rollback to Previous Version
      run: |
        # Rollback logic here
```

## 📞 Support

For issues with the CI/CD pipeline:

1. **Check GitHub Actions logs** for detailed error messages
2. **Review Cloud Run logs** for deployment issues
3. **Verify secrets and permissions** are correctly configured
4. **Test locally** with the same Docker commands

## 🔗 Related Documentation

- [Google Cloud Run Documentation](https://cloud.google.com/run/docs)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Postiz Deployment Script](./deploy-cloud-run.sh)
