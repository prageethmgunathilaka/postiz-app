# Cloud Run Deployment Script for Postiz (PowerShell)
param(
    [string]$ProjectId = "postiz-473617",
    [string]$Region = "us-central1",
    [string]$Registry = "gcr.io"
)

Write-Host "🚀 Starting Postiz Cloud Run Deployment" -ForegroundColor Green

# Build and push backend
Write-Host "📦 Building backend service..." -ForegroundColor Yellow
docker build -f Dockerfile.backend -t "$Registry/$ProjectId/postiz-backend" .
docker push "$Registry/$ProjectId/postiz-backend"

# Deploy backend to Cloud Run
Write-Host "🚀 Deploying backend to Cloud Run..." -ForegroundColor Yellow
gcloud run deploy postiz-backend `
  --image "$Registry/$ProjectId/postiz-backend" `
  --region $Region `
  --platform managed `
  --allow-unauthenticated `
  --port 3001 `
  --memory 1Gi `
  --cpu 1 `
  --max-instances 10 `
  --set-env-vars NODE_ENV=production,PORT=3001,FRONTEND_URL=https://postiz-frontend-1025161041601.us-central1.run.app,GITHUB_CLIENT_ID=Ov23liGW2IXy2y8G66Ej,GITHUB_CLIENT_SECRET=a0aa109a2026596ef7a8b2be481ed81c01add68e

# Build and push frontend
Write-Host "📦 Building frontend service..." -ForegroundColor Yellow
docker build -f Dockerfile.frontend -t "$Registry/$ProjectId/postiz-frontend" .
docker push "$Registry/$ProjectId/postiz-frontend"

# Deploy frontend to Cloud Run
Write-Host "🚀 Deploying frontend to Cloud Run..." -ForegroundColor Yellow
gcloud run deploy postiz-frontend `
  --image "$Registry/$ProjectId/postiz-frontend" `
  --region $Region `
  --platform managed `
  --allow-unauthenticated `
  --port 3000 `
  --memory 512Mi `
  --cpu 1 `
  --max-instances 5 `
  --set-env-vars NODE_ENV=production,PORT=3000

# Build and push workers
Write-Host "📦 Building workers service..." -ForegroundColor Yellow
docker build -f Dockerfile.workers -t "$Registry/$ProjectId/postiz-workers" .
docker push "$Registry/$ProjectId/postiz-workers"

# Deploy workers to Cloud Run
Write-Host "🚀 Deploying workers to Cloud Run..." -ForegroundColor Yellow
gcloud run deploy postiz-workers `
  --image "$Registry/$ProjectId/postiz-workers" `
  --region $Region `
  --platform managed `
  --allow-unauthenticated `
  --port 3003 `
  --memory 512Mi `
  --cpu 1 `
  --max-instances 3 `
  --set-env-vars NODE_ENV=production,PORT=3003

Write-Host "✅ Deployment completed successfully!" -ForegroundColor Green
Write-Host "🌐 Services deployed:" -ForegroundColor Green
Write-Host "  Backend: https://postiz-backend-[hash]-uc.a.run.app"
Write-Host "  Frontend: https://postiz-frontend-[hash]-uc.a.run.app"
Write-Host "  Workers: https://postiz-workers-[hash]-uc.a.run.app"
