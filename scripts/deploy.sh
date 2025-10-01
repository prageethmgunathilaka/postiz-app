#!/bin/bash
# Enhanced Deployment Script for Postiz
# Supports both manual and CI/CD deployments

set -e

# Configuration
PROJECT_ID="postiz-mcp-20250929"
REGION="us-central1"
REGISTRY="gcr.io"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
ENVIRONMENT="staging"
SERVICES="backend,frontend,workers"
IMAGE_TAG="latest"
SKIP_BUILD=false
DRY_RUN=false

# Function to display usage
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -e, --environment ENV    Environment to deploy to (staging|production) [default: staging]"
    echo "  -s, --services SERVICES  Comma-separated list of services to deploy [default: backend,frontend,workers]"
    echo "  -t, --tag TAG           Docker image tag to deploy [default: latest]"
    echo "  --skip-build            Skip building images (use existing ones)"
    echo "  --dry-run               Show what would be deployed without actually deploying"
    echo "  -h, --help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --environment production --services backend,frontend"
    echo "  $0 --environment staging --tag v1.2.3"
    echo "  $0 --dry-run --environment production"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -e|--environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        -s|--services)
            SERVICES="$2"
            shift 2
            ;;
        -t|--tag)
            IMAGE_TAG="$2"
            shift 2
            ;;
        --skip-build)
            SKIP_BUILD=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option $1"
            usage
            exit 1
            ;;
    esac
done

# Validate environment
if [[ "$ENVIRONMENT" != "staging" && "$ENVIRONMENT" != "production" ]]; then
    echo -e "${RED}❌ Invalid environment. Must be 'staging' or 'production'${NC}"
    exit 1
fi

# Convert services string to array
IFS=',' read -ra SERVICE_ARRAY <<< "$SERVICES"

# Set environment-specific configuration
if [[ "$ENVIRONMENT" == "production" ]]; then
    BACKEND_URL="https://postiz-backend-1025161041601.us-central1.run.app"
    FRONTEND_URL="https://postiz-frontend-1025161041601.us-central1.run.app"
    WORKERS_URL="https://postiz-workers-1025161041601.us-central1.run.app"
    BACKEND_SERVICE="postiz-backend"
    FRONTEND_SERVICE="postiz-frontend"
    WORKERS_SERVICE="postiz-workers"
    NODE_ENV="production"
    BACKEND_MAX_INSTANCES=10
    FRONTEND_MAX_INSTANCES=5
    WORKERS_MAX_INSTANCES=3
else
    BACKEND_URL="https://postiz-backend-staging-1025161041601.us-central1.run.app"
    FRONTEND_URL="https://postiz-frontend-staging-1025161041601.us-central1.run.app"
    WORKERS_URL="https://postiz-workers-staging-1025161041601.us-central1.run.app"
    BACKEND_SERVICE="postiz-backend-staging"
    FRONTEND_SERVICE="postiz-frontend-staging"
    WORKERS_SERVICE="postiz-workers-staging"
    NODE_ENV="staging"
    BACKEND_MAX_INSTANCES=5
    FRONTEND_MAX_INSTANCES=3
    WORKERS_MAX_INSTANCES=2
fi

echo -e "${GREEN}🚀 Postiz Deployment Script${NC}"
echo -e "${BLUE}Environment: ${ENVIRONMENT}${NC}"
echo -e "${BLUE}Services: ${SERVICES}${NC}"
echo -e "${BLUE}Image Tag: ${IMAGE_TAG}${NC}"
echo -e "${BLUE}Skip Build: ${SKIP_BUILD}${NC}"
echo -e "${BLUE}Dry Run: ${DRY_RUN}${NC}"
echo ""

if [[ "$DRY_RUN" == "true" ]]; then
    echo -e "${YELLOW}🔍 DRY RUN MODE - No actual deployment will occur${NC}"
    echo ""
fi

# Function to build and push Docker image
build_and_push() {
    local service=$1
    local image_name="${REGISTRY}/${PROJECT_ID}/postiz-${service}"
    local full_tag="${image_name}:${IMAGE_TAG}"
    
    echo -e "${YELLOW}📦 Building ${service} service...${NC}"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "${BLUE}[DRY RUN] Would build: docker build -f Dockerfile.${service} -t ${full_tag} .${NC}"
        echo -e "${BLUE}[DRY RUN] Would push: docker push ${full_tag}${NC}"
    else
        docker build -f Dockerfile.${service} -t ${full_tag} .
        docker push ${full_tag}
        echo -e "${GREEN}✅ ${service} image built and pushed successfully${NC}"
    fi
}

# Function to deploy service
deploy_service() {
    local service=$1
    local image_name="${REGISTRY}/${PROJECT_ID}/postiz-${service}"
    local full_tag="${image_name}:${IMAGE_TAG}"
    
    echo -e "${YELLOW}🚀 Deploying ${service} to ${ENVIRONMENT}...${NC}"
    
    case $service in
        backend)
            local deploy_cmd="gcloud run deploy ${BACKEND_SERVICE} \
                --image ${full_tag} \
                --region ${REGION} \
                --platform managed \
                --allow-unauthenticated \
                --port 3001 \
                --memory 1Gi \
                --cpu 1 \
                --max-instances ${BACKEND_MAX_INSTANCES} \
                --set-env-vars NODE_ENV=${NODE_ENV},PORT=3001,FRONTEND_URL=${FRONTEND_URL}"
            
            if [[ "$ENVIRONMENT" == "production" ]]; then
                deploy_cmd="${deploy_cmd},GITHUB_CLIENT_ID=Ov23liGW2IXy2y8G66Ej,GITHUB_CLIENT_SECRET=a0aa109a2026596ef7a8b2be481ed81c01add68e"
            fi
            
            deploy_cmd="${deploy_cmd} --quiet"
            ;;
        frontend)
            local deploy_cmd="gcloud run deploy ${FRONTEND_SERVICE} \
                --image ${full_tag} \
                --region ${REGION} \
                --platform managed \
                --allow-unauthenticated \
                --port 3000 \
                --memory 512Mi \
                --cpu 1 \
                --max-instances ${FRONTEND_MAX_INSTANCES} \
                --set-env-vars NODE_ENV=${NODE_ENV},PORT=3000,NEXT_PUBLIC_BACKEND_URL=${BACKEND_URL} \
                --quiet"
            ;;
        workers)
            local deploy_cmd="gcloud run deploy ${WORKERS_SERVICE} \
                --image ${full_tag} \
                --region ${REGION} \
                --platform managed \
                --allow-unauthenticated \
                --port 3003 \
                --memory 512Mi \
                --cpu 1 \
                --max-instances ${WORKERS_MAX_INSTANCES} \
                --set-env-vars NODE_ENV=${NODE_ENV},PORT=3003 \
                --quiet"
            ;;
        *)
            echo -e "${RED}❌ Unknown service: ${service}${NC}"
            return 1
            ;;
    esac
    
    if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "${BLUE}[DRY RUN] Would execute: ${deploy_cmd}${NC}"
    else
        eval $deploy_cmd
        echo -e "${GREEN}✅ ${service} deployed successfully${NC}"
    fi
}

# Main deployment logic
if [[ "$SKIP_BUILD" == "false" ]]; then
    echo -e "${YELLOW}🔨 Building Docker images...${NC}"
    for service in "${SERVICE_ARRAY[@]}"; do
        build_and_push "$service"
    done
    echo ""
fi

echo -e "${YELLOW}🚀 Deploying services...${NC}"
for service in "${SERVICE_ARRAY[@]}"; do
    deploy_service "$service"
done

if [[ "$DRY_RUN" == "false" ]]; then
    echo ""
    echo -e "${GREEN}✅ Deployment completed successfully!${NC}"
    echo -e "${GREEN}🌐 Services deployed to ${ENVIRONMENT}:${NC}"
    
    for service in "${SERVICE_ARRAY[@]}"; do
        case $service in
            backend)
                echo -e "  Backend: ${BACKEND_URL}"
                ;;
            frontend)
                echo -e "  Frontend: ${FRONTEND_URL}"
                ;;
            workers)
                echo -e "  Workers: ${WORKERS_URL}"
                ;;
        esac
    done
    
    echo ""
    echo -e "${BLUE}💡 To view logs:${NC}"
    echo "  gcloud logging read \"resource.type=cloud_run_revision\" --limit=50"
    echo ""
    echo -e "${BLUE}💡 To rollback:${NC}"
    echo "  $0 --environment ${ENVIRONMENT} --tag PREVIOUS_TAG --skip-build"
else
    echo ""
    echo -e "${YELLOW}🔍 Dry run completed. No changes were made.${NC}"
fi
