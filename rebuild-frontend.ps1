# Rebuild and redeploy frontend script
Write-Host "🔧 Rebuilding frontend with fixed Dockerfile..." -ForegroundColor Yellow

# Build the Docker image
Write-Host "📦 Building Docker image..." -ForegroundColor Yellow
docker build -f Dockerfile.frontend -t gcr.io/postiz-473617/postiz-frontend .

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Docker build successful!" -ForegroundColor Green
    
    # Push the image
    Write-Host "📤 Pushing image to registry..." -ForegroundColor Yellow
    docker push gcr.io/postiz-473617/postiz-frontend
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Image pushed successfully!" -ForegroundColor Green
        
        # Deploy to Cloud Run
        Write-Host "🚀 Deploying to Cloud Run..." -ForegroundColor Yellow
        gcloud run deploy postiz-frontend --image gcr.io/postiz-473617/postiz-frontend --region us-central1 --platform managed --allow-unauthenticated --port 3000 --memory 512Mi --cpu 1 --max-instances 5 --set-env-vars NODE_ENV=production,PORT=3000
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Frontend deployment completed successfully!" -ForegroundColor Green
            Write-Host "🌐 Frontend URL: https://postiz-frontend-1025161041601.us-central1.run.app" -ForegroundColor Cyan
        } else {
            Write-Host "❌ Cloud Run deployment failed!" -ForegroundColor Red
        }
    } else {
        Write-Host "❌ Docker push failed!" -ForegroundColor Red
    }
} else {
    Write-Host "❌ Docker build failed!" -ForegroundColor Red
}
