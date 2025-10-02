#!/bin/bash
# Cloud Run Job Deployment Script for Postiz Workers

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

echo -e "${GREEN}🚀 Starting Postiz Workers Job Deployment${NC}"

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

echo -e "${GREEN}✅ Workers job deployment completed successfully!${NC}"
echo -e "${GREEN}📋 Job details:${NC}"
echo -e "  Job Name: postiz-workers"
echo -e "  Region: $REGION"
echo -e "  Parallelism: 3"
echo -e "  Memory: 512Mi"
echo -e "  CPU: 1000m"
