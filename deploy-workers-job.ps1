# Cloud Run Job Deployment Script for Postiz Workers (PowerShell)
param(
    [string]$ProjectId = "postiz-473617",
    [string]$Region = "us-central1",
    [string]$Registry = "gcr.io"
)

Write-Host "🚀 Starting Postiz Workers Job Deployment" -ForegroundColor Green

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

Write-Host "✅ Workers job deployment completed successfully!" -ForegroundColor Green
Write-Host "📋 Job details:" -ForegroundColor Green
Write-Host "  Job Name: postiz-workers" -ForegroundColor White
Write-Host "  Region: $Region" -ForegroundColor White
Write-Host "  Parallelism: 3" -ForegroundColor White
Write-Host "  Memory: 512Mi" -ForegroundColor White
Write-Host "  CPU: 1000m" -ForegroundColor White
