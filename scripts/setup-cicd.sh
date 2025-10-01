#!/bin/bash
# CI/CD Setup Script for Postiz
# This script helps set up the necessary Google Cloud resources for CI/CD

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_ID="postiz-mcp-20250929"
SERVICE_ACCOUNT_NAME="postiz-cicd"
SERVICE_ACCOUNT_EMAIL="${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
KEY_FILE="postiz-cicd-key.json"

echo -e "${GREEN}🚀 Postiz CI/CD Setup Script${NC}"
echo -e "${BLUE}This script will help you set up Google Cloud resources for CI/CD${NC}"
echo ""

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo -e "${RED}❌ gcloud CLI is not installed. Please install it first:${NC}"
    echo "https://cloud.google.com/sdk/docs/install"
    exit 1
fi

# Check if user is authenticated
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
    echo -e "${YELLOW}⚠️  You are not authenticated with gcloud. Please run:${NC}"
    echo "gcloud auth login"
    exit 1
fi

echo -e "${YELLOW}📋 Setting up Google Cloud resources...${NC}"

# Set the project
echo -e "${BLUE}Setting project to ${PROJECT_ID}...${NC}"
gcloud config set project ${PROJECT_ID}

# Enable required APIs
echo -e "${BLUE}Enabling required APIs...${NC}"
gcloud services enable cloudbuild.googleapis.com
gcloud services enable run.googleapis.com
gcloud services enable containerregistry.googleapis.com
gcloud services enable iam.googleapis.com

# Create service account
echo -e "${BLUE}Creating service account...${NC}"
if gcloud iam service-accounts describe ${SERVICE_ACCOUNT_EMAIL} &> /dev/null; then
    echo -e "${YELLOW}Service account ${SERVICE_ACCOUNT_EMAIL} already exists.${NC}"
else
    gcloud iam service-accounts create ${SERVICE_ACCOUNT_NAME} \
        --display-name="Postiz CI/CD Service Account" \
        --description="Service account for Postiz CI/CD pipeline"
    echo -e "${GREEN}✅ Service account created successfully.${NC}"
fi

# Grant required permissions
echo -e "${BLUE}Granting required permissions...${NC}"

# Cloud Run Admin
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member="serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
    --role="roles/run.admin" \
    --quiet

# Storage Admin (for container registry)
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member="serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
    --role="roles/storage.admin" \
    --quiet

# Service Account User
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member="serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
    --role="roles/iam.serviceAccountUser" \
    --quiet

# Cloud Build Editor (for building images)
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member="serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
    --role="roles/cloudbuild.builds.editor" \
    --quiet

echo -e "${GREEN}✅ Permissions granted successfully.${NC}"

# Create and download service account key
echo -e "${BLUE}Creating service account key...${NC}"
if [ -f "${KEY_FILE}" ]; then
    echo -e "${YELLOW}Key file ${KEY_FILE} already exists.${NC}"
    read -p "Do you want to overwrite it? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Skipping key creation.${NC}"
    else
        gcloud iam service-accounts keys create ${KEY_FILE} \
            --iam-account=${SERVICE_ACCOUNT_EMAIL}
        echo -e "${GREEN}✅ Service account key created: ${KEY_FILE}${NC}"
    fi
else
    gcloud iam service-accounts keys create ${KEY_FILE} \
        --iam-account=${SERVICE_ACCOUNT_EMAIL}
    echo -e "${GREEN}✅ Service account key created: ${KEY_FILE}${NC}"
fi

# Configure Docker authentication
echo -e "${BLUE}Configuring Docker authentication...${NC}"
gcloud auth configure-docker

echo ""
echo -e "${GREEN}🎉 Setup completed successfully!${NC}"
echo ""
echo -e "${YELLOW}📋 Next steps:${NC}"
echo ""
echo -e "${BLUE}1. Add the service account key to GitHub Secrets:${NC}"
echo "   - Go to your GitHub repository"
echo "   - Navigate to Settings → Secrets and variables → Actions"
echo "   - Add a new secret named 'GCP_SA_KEY'"
echo "   - Copy the contents of ${KEY_FILE} as the value"
echo ""
echo -e "${BLUE}2. Add other required secrets:${NC}"
echo "   - GITHUB_CLIENT_ID: Ov23liGW2IXy2y8G66Ej"
echo "   - GITHUB_CLIENT_SECRET: a0aa109a2026596ef7a8b2be481ed81c01add68e"
echo ""
echo -e "${BLUE}3. Set up environment protection rules:${NC}"
echo "   - Go to Settings → Environments"
echo "   - Create 'staging' and 'production' environments"
echo "   - Add protection rules as needed"
echo ""
echo -e "${BLUE}4. Test the pipeline:${NC}"
echo "   - Push changes to the 'develop' branch for staging deployment"
echo "   - Push changes to the 'main' branch for production deployment"
echo ""
echo -e "${YELLOW}⚠️  Important: Keep the ${KEY_FILE} file secure and never commit it to version control!${NC}"
echo ""
echo -e "${GREEN}🚀 Your CI/CD pipeline is ready to use!${NC}"
