#!/bin/bash
# Cloud Run Deployment Script for Postiz

set -e

# Configuration
PROJECT_ID="postiz-473617"
REGION="us-central1"
REGISTRY="gcr.io"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Starting Postiz Cloud Run Deployment${NC}"

# Build and push backend
echo -e "${YELLOW}📦 Building backend service...${NC}"
docker build -f Dockerfile.backend -t $REGISTRY/$PROJECT_ID/postiz-backend .
docker push $REGISTRY/$PROJECT_ID/postiz-backend

# Deploy backend to Cloud Run
echo -e "${YELLOW}🚀 Deploying backend to Cloud Run...${NC}"
gcloud run deploy postiz-backend \
  --image $REGISTRY/$PROJECT_ID/postiz-backend \
  --region $REGION \
  --platform managed \
  --allow-unauthenticated \
  --port 3001 \
  --memory 1Gi \
  --cpu 1 \
  --max-instances 10 \
  --set-env-vars NODE_ENV=production,PORT=3001,FRONTEND_URL=https://postiz-frontend-1025161041601.us-central1.run.app,GITHUB_CLIENT_ID=Ov23liGW2IXy2y8G66Ej,GITHUB_CLIENT_SECRET=a0aa109a2026596ef7a8b2be481ed81c01add68e

# Build and push frontend
echo -e "${YELLOW}📦 Building frontend service...${NC}"
docker build -f Dockerfile.frontend -t $REGISTRY/$PROJECT_ID/postiz-frontend .
docker push $REGISTRY/$PROJECT_ID/postiz-frontend

# Deploy frontend to Cloud Run
echo -e "${YELLOW}🚀 Deploying frontend to Cloud Run...${NC}"
gcloud run deploy postiz-frontend \
  --image $REGISTRY/$PROJECT_ID/postiz-frontend \
  --region $REGION \
  --platform managed \
  --allow-unauthenticated \
  --port 3000 \
  --memory 512Mi \
  --cpu 1 \
  --max-instances 5 \
  --set-env-vars NODE_ENV=production,PORT=3000

# Build and push workers
echo -e "${YELLOW}📦 Building workers service...${NC}"
docker build -f Dockerfile.workers -t $REGISTRY/$PROJECT_ID/postiz-workers .
docker push $REGISTRY/$PROJECT_ID/postiz-workers

# Deploy workers to Cloud Run
echo -e "${YELLOW}🚀 Deploying workers to Cloud Run...${NC}"
gcloud run deploy postiz-workers \
  --image $REGISTRY/$PROJECT_ID/postiz-workers \
  --region $REGION \
  --platform managed \
  --allow-unauthenticated \
  --port 3003 \
  --memory 512Mi \
  --cpu 1 \
  --max-instances 3 \
  --set-env-vars NODE_ENV=production,PORT=3003

echo -e "${GREEN}✅ Deployment completed successfully!${NC}"
echo -e "${GREEN}🌐 Services deployed:${NC}"
echo -e "  Backend: https://postiz-backend-[hash]-uc.a.run.app"
echo -e "  Frontend: https://postiz-frontend-[hash]-uc.a.run.app"
echo -e "  Workers: https://postiz-workers-[hash]-uc.a.run.app"
