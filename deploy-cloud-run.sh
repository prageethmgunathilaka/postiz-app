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
echo -e "${YELLOW}📦 Building workers job...${NC}"
docker build -f Dockerfile.workers -t $REGISTRY/$PROJECT_ID/postiz-workers .
docker push $REGISTRY/$PROJECT_ID/postiz-workers

# Deploy workers as Cloud Run Job
echo -e "${YELLOW}🚀 Deploying workers as Cloud Run Job...${NC}"
gcloud run jobs replace --region $REGION - <<EOF
apiVersion: run.googleapis.com/v1
kind: Job
metadata:
  name: postiz-workers
  namespace: '$PROJECT_ID'
spec:
  spec:
    template:
      spec:
        template:
          spec:
            containers:
            - image: $REGISTRY/$PROJECT_ID/postiz-workers
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
EOF

# Execute the job
echo -e "${YELLOW}🚀 Starting workers job execution...${NC}"
gcloud run jobs execute postiz-workers --region $REGION --wait

echo -e "${GREEN}✅ Deployment completed successfully!${NC}"
echo -e "${GREEN}🌐 Services deployed:${NC}"
echo -e "  Backend: https://postiz-backend-[hash]-uc.a.run.app"
echo -e "  Frontend: https://postiz-frontend-[hash]-uc.a.run.app"
echo -e "  Workers: Cloud Run Job (postiz-workers)"
