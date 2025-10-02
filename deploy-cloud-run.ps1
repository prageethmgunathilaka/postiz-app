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
Write-Host "📦 Building workers job..." -ForegroundColor Yellow
docker build -f Dockerfile.workers -t "$Registry/$ProjectId/postiz-workers" .
docker push "$Registry/$ProjectId/postiz-workers"

# Deploy workers as Cloud Run Job
Write-Host "🚀 Deploying workers as Cloud Run Job..." -ForegroundColor Yellow
$jobYaml = @"
apiVersion: run.googleapis.com/v1
kind: Job
metadata:
  name: postiz-workers
  namespace: '$ProjectId'
spec:
  spec:
    template:
      spec:
        template:
          spec:
            containers:
            - image: $Registry/$ProjectId/postiz-workers
              name: postiz-workers
              resources:
                limits:
                  cpu: 1000m
                  memory: 512Mi
              env:
              - name: NODE_ENV
                value: "production"
              - name: DATABASE_URL
                value: "postgresql://postiz-user:PostizMCP2025!@34.58.7.151:5432/postiz-db"
              - name: REDIS_URL
                value: "redis://10.169.95.155:6379"
              - name: FRONTEND_URL
                value: "https://postiz-frontend-1025161041601.us-central1.run.app"
            restartPolicy: OnFailure
        parallelism: 3
        completions: null
        backoffLimit: 3
"@

$jobYaml | gcloud run jobs replace --region $Region -

# Execute the job
Write-Host "🚀 Starting workers job execution..." -ForegroundColor Yellow
gcloud run jobs execute postiz-workers --region $Region --wait

Write-Host "✅ Deployment completed successfully!" -ForegroundColor Green
Write-Host "🌐 Services deployed:" -ForegroundColor Green
Write-Host "  Backend: https://postiz-backend-[hash]-uc.a.run.app"
Write-Host "  Frontend: https://postiz-frontend-[hash]-uc.a.run.app"
Write-Host "  Workers: Cloud Run Job (postiz-workers)"
