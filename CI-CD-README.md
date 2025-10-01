# 🚀 Postiz CI/CD Pipeline

This repository now includes a comprehensive CI/CD pipeline that automates testing, building, and deploying Postiz to Google Cloud Run.

## ✨ Features

- **🔄 Automated Testing**: Runs linting, type checking, security audits, and tests on every PR
- **🐳 Multi-Service Builds**: Builds Docker images for backend, frontend, and workers in parallel
- **🌍 Environment Management**: Separate staging and production deployments
- **🚀 One-Click Deployment**: Manual deployment triggers with environment selection
- **📊 Health Checks**: Post-deployment verification and monitoring
- **🔒 Security**: Secure secret management and service account permissions

## 🏗️ Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   GitHub Push   │───▶│  GitHub Actions  │───▶│  Google Cloud   │
│                 │    │                  │    │     Run         │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                              │
                              ▼
                       ┌──────────────────┐
                       │   Docker Build   │
                       │   & Registry     │
                       └──────────────────┘
```

## 🚦 Pipeline Flow

### 1. **Quality Checks** (Every PR)
- ✅ Install dependencies with caching
- ✅ Run ESLint for code quality
- ✅ TypeScript type checking
- ✅ Security audit with pnpm
- ✅ Jest test suite with coverage
- ✅ Upload test artifacts

### 2. **Build Images** (Push to main/develop)
- 🐳 Build Docker images for all services
- 📦 Push to Google Container Registry
- 🏷️ Tag with commit SHA and latest

### 3. **Deploy Staging** (Push to develop)
- 🚀 Deploy all services to staging environment
- 🔧 Configure staging-specific environment variables
- 🌐 Set up staging service URLs

### 4. **Deploy Production** (Push to main)
- 🚀 Deploy all services to production environment
- 🔐 Use production secrets and configuration
- 🌐 Set up production service URLs

### 5. **Health Checks** (Post-deployment)
- 🔍 Verify all services are responding
- 📊 Report deployment status
- 📝 Generate deployment summary

## 🛠️ Quick Start

### Prerequisites

1. **Google Cloud Project**: `postiz-mcp-20250929`
2. **GitHub Repository**: With Actions enabled
3. **gcloud CLI**: Installed and authenticated

### Setup Steps

1. **Run the setup script**:
   ```bash
   # Linux/macOS
   ./scripts/setup-cicd.sh
   
   # Windows PowerShell
   .\scripts\setup-cicd.ps1
   ```

2. **Add GitHub Secrets**:
   - Go to Repository Settings → Secrets and variables → Actions
   - Add `GCP_SA_KEY` with the service account key content
   - Add `GITHUB_CLIENT_ID` and `GITHUB_CLIENT_SECRET`

3. **Set up Environments**:
   - Go to Settings → Environments
   - Create `staging` and `production` environments
   - Add protection rules as needed

4. **Test the pipeline**:
   - Push to `develop` branch for staging deployment
   - Push to `main` branch for production deployment

## 📋 Manual Deployment

### Using GitHub Actions

1. Go to **Actions** tab in GitHub
2. Select **CI/CD Pipeline**
3. Click **Run workflow**
4. Choose environment and services
5. Click **Run workflow**

### Using Scripts

```bash
# Deploy to staging
./scripts/deploy.sh --environment staging

# Deploy to production
./scripts/deploy.sh --environment production

# Deploy specific services
./scripts/deploy.sh --environment staging --services backend,frontend

# Deploy with specific tag
./scripts/deploy.sh --environment production --tag v1.2.3

# Dry run (see what would be deployed)
./scripts/deploy.sh --dry-run --environment production
```

## 🔧 Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `NODE_VERSION` | Node.js version | `20.17.0` |
| `PNPM_VERSION` | pnpm version | `10.6.1` |
| `PROJECT_ID` | Google Cloud Project ID | `postiz-mcp-20250929` |
| `REGION` | Google Cloud region | `us-central1` |
| `REGISTRY` | Container registry | `gcr.io` |

### Service Configuration

| Service | Memory | CPU | Max Instances | Port |
|---------|--------|-----|---------------|------|
| Backend | 1Gi | 1 | 10 (prod) / 5 (staging) | 3001 |
| Frontend | 512Mi | 1 | 5 (prod) / 3 (staging) | 3000 |
| Workers | 512Mi | 1 | 3 (prod) / 2 (staging) | 3003 |

## 🔍 Monitoring

### View Pipeline Status

- **GitHub Actions**: Repository → Actions tab
- **Cloud Run**: Google Cloud Console → Cloud Run
- **Logs**: `gcloud logging read "resource.type=cloud_run_revision" --limit=50`

### Health Check URLs

**Staging:**
- Backend: https://postiz-backend-staging-1025161041601.us-central1.run.app
- Frontend: https://postiz-frontend-staging-1025161041601.us-central1.run.app
- Workers: https://postiz-workers-staging-1025161041601.us-central1.run.app

**Production:**
- Backend: https://postiz-backend-1025161041601.us-central1.run.app
- Frontend: https://postiz-frontend-1025161041601.us-central1.run.app
- Workers: https://postiz-workers-1025161041601.us-central1.run.app

## 🚨 Troubleshooting

### Common Issues

1. **Service Account Permissions**:
   ```bash
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

### Rollback Procedures

```bash
# Quick rollback to previous version
./scripts/deploy.sh --environment production --tag PREVIOUS_SHA --skip-build

# Or manually via gcloud
gcloud run deploy postiz-backend \
  --image gcr.io/postiz-mcp-20250929/postiz-backend:PREVIOUS_SHA \
  --region us-central1
```

## 🔒 Security

- **Secrets Management**: All sensitive data stored in GitHub Secrets
- **Service Account**: Minimal required permissions
- **Environment Isolation**: Separate staging and production environments
- **Security Audits**: Automated vulnerability scanning

## 📈 Best Practices

### Branch Strategy
- **`main`**: Production-ready code
- **`develop`**: Integration branch for staging
- **Feature branches**: Individual features

### Deployment Strategy
- **Staging First**: Always test in staging before production
- **Rollback Plan**: Keep previous image tags for quick rollback
- **Health Checks**: Verify deployments before marking complete

### Code Quality
- **Linting**: ESLint with strict rules
- **Type Safety**: TypeScript strict mode
- **Testing**: Comprehensive test coverage
- **Security**: Regular dependency audits

## 📚 Additional Resources

- [Detailed Setup Guide](./docs/CI-CD-SETUP.md)
- [Google Cloud Run Documentation](https://cloud.google.com/run/docs)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)

## 🤝 Contributing

When contributing to this project:

1. **Create a feature branch** from `develop`
2. **Make your changes** and ensure tests pass
3. **Create a pull request** to `develop`
4. **Wait for CI checks** to pass
5. **Merge to develop** for staging deployment
6. **Merge to main** for production deployment

## 📞 Support

For issues with the CI/CD pipeline:

1. Check GitHub Actions logs for detailed error messages
2. Review Cloud Run logs for deployment issues
3. Verify secrets and permissions are correctly configured
4. Test locally with the same Docker commands

---

**🎉 Your CI/CD pipeline is now ready! Push to `develop` or `main` to see it in action.**
