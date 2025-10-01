# CI/CD Setup Script for Postiz (PowerShell)
# This script helps set up the necessary Google Cloud resources for CI/CD

param(
    [string]$ProjectId = "postiz-mcp-20250929",
    [string]$ServiceAccountName = "postiz-cicd",
    [string]$KeyFile = "postiz-cicd-key.json"
)

# Colors for output
$Red = "Red"
$Green = "Green"
$Yellow = "Yellow"
$Blue = "Blue"

$ServiceAccountEmail = "${ServiceAccountName}@${ProjectId}.iam.gserviceaccount.com"

Write-Host "🚀 Postiz CI/CD Setup Script" -ForegroundColor $Green
Write-Host "This script will help you set up Google Cloud resources for CI/CD" -ForegroundColor $Blue
Write-Host ""

# Check if gcloud is installed
try {
    $null = Get-Command gcloud -ErrorAction Stop
} catch {
    Write-Host "❌ gcloud CLI is not installed. Please install it first:" -ForegroundColor $Red
    Write-Host "https://cloud.google.com/sdk/docs/install" -ForegroundColor $Blue
    exit 1
}

# Check if user is authenticated
try {
    $activeAccounts = gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>$null
    if (-not $activeAccounts) {
        throw "No active accounts"
    }
} catch {
    Write-Host "⚠️  You are not authenticated with gcloud. Please run:" -ForegroundColor $Yellow
    Write-Host "gcloud auth login" -ForegroundColor $Blue
    exit 1
}

Write-Host "📋 Setting up Google Cloud resources..." -ForegroundColor $Yellow

# Set the project
Write-Host "Setting project to ${ProjectId}..." -ForegroundColor $Blue
gcloud config set project $ProjectId

# Enable required APIs
Write-Host "Enabling required APIs..." -ForegroundColor $Blue
gcloud services enable cloudbuild.googleapis.com
gcloud services enable run.googleapis.com
gcloud services enable containerregistry.googleapis.com
gcloud services enable iam.googleapis.com

# Create service account
Write-Host "Creating service account..." -ForegroundColor $Blue
try {
    gcloud iam service-accounts describe $ServiceAccountEmail 2>$null
    Write-Host "Service account ${ServiceAccountEmail} already exists." -ForegroundColor $Yellow
} catch {
    gcloud iam service-accounts create $ServiceAccountName `
        --display-name="Postiz CI/CD Service Account" `
        --description="Service account for Postiz CI/CD pipeline"
    Write-Host "✅ Service account created successfully." -ForegroundColor $Green
}

# Grant required permissions
Write-Host "Granting required permissions..." -ForegroundColor $Blue

# Cloud Run Admin
gcloud projects add-iam-policy-binding $ProjectId `
    --member="serviceAccount:${ServiceAccountEmail}" `
    --role="roles/run.admin" `
    --quiet

# Storage Admin (for container registry)
gcloud projects add-iam-policy-binding $ProjectId `
    --member="serviceAccount:${ServiceAccountEmail}" `
    --role="roles/storage.admin" `
    --quiet

# Service Account User
gcloud projects add-iam-policy-binding $ProjectId `
    --member="serviceAccount:${ServiceAccountEmail}" `
    --role="roles/iam.serviceAccountUser" `
    --quiet

# Cloud Build Editor (for building images)
gcloud projects add-iam-policy-binding $ProjectId `
    --member="serviceAccount:${ServiceAccountEmail}" `
    --role="roles/cloudbuild.builds.editor" `
    --quiet

Write-Host "✅ Permissions granted successfully." -ForegroundColor $Green

# Create and download service account key
Write-Host "Creating service account key..." -ForegroundColor $Blue
if (Test-Path $KeyFile) {
    Write-Host "Key file ${KeyFile} already exists." -ForegroundColor $Yellow
    $overwrite = Read-Host "Do you want to overwrite it? (y/N)"
    if ($overwrite -notmatch "^[Yy]$") {
        Write-Host "Skipping key creation." -ForegroundColor $Yellow
    } else {
        gcloud iam service-accounts keys create $KeyFile `
            --iam-account=$ServiceAccountEmail
        Write-Host "✅ Service account key created: ${KeyFile}" -ForegroundColor $Green
    }
} else {
    gcloud iam service-accounts keys create $KeyFile `
        --iam-account=$ServiceAccountEmail
    Write-Host "✅ Service account key created: ${KeyFile}" -ForegroundColor $Green
}

# Configure Docker authentication
Write-Host "Configuring Docker authentication..." -ForegroundColor $Blue
gcloud auth configure-docker

Write-Host ""
Write-Host "🎉 Setup completed successfully!" -ForegroundColor $Green
Write-Host ""
Write-Host "📋 Next steps:" -ForegroundColor $Yellow
Write-Host ""
Write-Host "1. Add the service account key to GitHub Secrets:" -ForegroundColor $Blue
Write-Host "   - Go to your GitHub repository"
Write-Host "   - Navigate to Settings → Secrets and variables → Actions"
Write-Host "   - Add a new secret named 'GCP_SA_KEY'"
Write-Host "   - Copy the contents of ${KeyFile} as the value"
Write-Host ""
Write-Host "2. Add other required secrets:" -ForegroundColor $Blue
Write-Host "   - GITHUB_CLIENT_ID: Ov23liGW2IXy2y8G66Ej"
Write-Host "   - GITHUB_CLIENT_SECRET: a0aa109a2026596ef7a8b2be481ed81c01add68e"
Write-Host ""
Write-Host "3. Set up environment protection rules:" -ForegroundColor $Blue
Write-Host "   - Go to Settings → Environments"
Write-Host "   - Create 'staging' and 'production' environments"
Write-Host "   - Add protection rules as needed"
Write-Host ""
Write-Host "4. Test the pipeline:" -ForegroundColor $Blue
Write-Host "   - Push changes to the 'develop' branch for staging deployment"
Write-Host "   - Push changes to the 'main' branch for production deployment"
Write-Host ""
Write-Host "⚠️  Important: Keep the ${KeyFile} file secure and never commit it to version control!" -ForegroundColor $Yellow
Write-Host ""
Write-Host "🚀 Your CI/CD pipeline is ready to use!" -ForegroundColor $Green
