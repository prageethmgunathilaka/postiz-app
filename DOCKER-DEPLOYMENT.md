# 🐳 Docker Deployment for Postiz

Simple CI/CD pipeline that builds and deploys Docker containers to Google Cloud Run.

## 🚀 Quick Setup

### 1. Run Setup Script

```bash
# Linux/macOS
./scripts/setup-cicd.sh

# Windows PowerShell
.\scripts\setup-cicd.ps1
```

### 2. Add GitHub Secrets

Go to your GitHub repository → Settings → Secrets and variables → Actions

Add these secrets:
- `GCP_SA_KEY` - Contents of the service account key file
- `GITHUB_CLIENT_ID` - `Ov23liGW2IXy2y8G66Ej`
- `GITHUB_CLIENT_SECRET` - `a0aa109a2026596ef7a8b2be481ed81c01add68e`

### 3. Deploy

**Automatic:**
- Push to `develop` branch → Deploys to staging
- Push to `main` branch → Deploys to production

**Manual:**
- Go to Actions tab → "Docker Deployment" → "Run workflow"
- Select environment (staging/production)

## 📋 What It Does

1. **Builds Docker images** for backend, frontend, and workers
2. **Pushes to Google Container Registry**
3. **Deploys to Cloud Run** with appropriate environment settings
4. **Shows deployment URLs** in the GitHub Actions summary

## 🔧 Manual Deployment

```bash
# Deploy to staging
./scripts/deploy.sh --environment staging

# Deploy to production  
./scripts/deploy.sh --environment production

# Deploy specific services
./scripts/deploy.sh --environment staging --services backend,frontend
```

## 🌐 Service URLs

**Staging:**
- Backend: https://postiz-backend-staging-1025161041601.us-central1.run.app
- Frontend: https://postiz-frontend-staging-1025161041601.us-central1.run.app
- Workers: https://postiz-workers-staging-1025161041601.us-central1.run.app

**Production:**
- Backend: https://postiz-backend-1025161041601.us-central1.run.app
- Frontend: https://postiz-frontend-1025161041601.us-central1.run.app
- Workers: https://postiz-workers-1025161041601.us-central1.run.app

## 🚨 Troubleshooting

**Check deployment status:**
```bash
gcloud run services list --region=us-central1
```

**View logs:**
```bash
gcloud logging read "resource.type=cloud_run_revision" --limit=50
```

**Rollback:**
```bash
./scripts/deploy.sh --environment production --tag PREVIOUS_SHA --skip-build
```

That's it! Your Docker deployment pipeline is ready. 🎉
