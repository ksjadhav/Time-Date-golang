# date-time-go Deployment Script for Windows PowerShell
# This script helps deploy the application to DockerHub and Kubernetes

param(
    [string]$DockerUsername = "your-dockerhub-username",
    [string]$Tag = "latest",
    [string]$Action = "all"
)

# Configuration
$ImageName = "date-time-go"
$FullImageName = "${DockerUsername}/${ImageName}:${Tag}"

# Functions
function Write-Status {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

# Check if required tools are installed
function Test-Prerequisites {
    Write-Status "Checking prerequisites..."
    
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        Write-Error "Docker is not installed or not in PATH"
        exit 1
    }
    
    if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
        Write-Error "kubectl is not installed or not in PATH"
        exit 1
    }
    
    Write-Status "Prerequisites check passed"
}

# Build and push Docker image
function Build-AndPush {
    Write-Status "Building Docker image: $FullImageName"
    
    # Build the image
    docker build -t $FullImageName .
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Docker build failed"
        exit 1
    }
    
    Write-Status "Docker image built successfully"
    
    # Check if user is logged in to DockerHub
    $dockerInfo = docker info 2>&1
    if ($dockerInfo -notmatch "Username:") {
        Write-Warning "Not logged in to DockerHub. Please run 'docker login' first"
        return $false
    }
    
    Write-Status "Pushing image to DockerHub..."
    docker push $FullImageName
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Docker push failed"
        exit 1
    }
    
    Write-Status "Image pushed successfully to DockerHub"
    return $true
}

# Deploy to Kubernetes
function Deploy-K8s {
    Write-Status "Deploying to Kubernetes..."
    
    # Update the image name in deployment.yaml
    $deploymentFile = "k8s\deployment.yaml"
    $content = Get-Content $deploymentFile -Raw
    $content = $content -replace "your-dockerhub-username/date-time-go:latest", $FullImageName
    Set-Content -Path $deploymentFile -Value $content
    
    # Apply Kubernetes manifests
    kubectl apply -f k8s\deployment.yaml
    kubectl apply -f k8s\service.yaml
    
    Write-Status "Waiting for deployment to be ready..."
    kubectl wait --for=condition=available --timeout=300s deployment/datetime-app
    
    Write-Status "Deployment completed successfully"
}

# Expose the application
function Expose-App {
    Write-Status "Exposing the application..."
    
    # Option 1: LoadBalancer
    Write-Status "Creating LoadBalancer service..."
    kubectl apply -f k8s\loadbalancer-service.yaml
    
    Write-Status "Waiting for LoadBalancer to get external IP..."
    kubectl wait --for=condition=Ready --timeout=300s service/datetime-app-loadbalancer
    
    # Get external IP
    $externalIP = kubectl get service datetime-app-loadbalancer -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
    if ([string]::IsNullOrEmpty($externalIP)) {
        $externalIP = kubectl get service datetime-app-loadbalancer -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
    }
    
    if (-not [string]::IsNullOrEmpty($externalIP)) {
        Write-Status "Application is accessible at: http://$externalIP"
    } else {
        Write-Warning "External IP not available yet. Check with: kubectl get service datetime-app-loadbalancer"
    }
}

# Show status
function Show-Status {
    Write-Status "Current deployment status:"
    Write-Host ""
    Write-Host "Pods:"
    kubectl get pods -l app=datetime-app
    Write-Host ""
    Write-Host "Services:"
    kubectl get services -l app=datetime-app
    Write-Host ""
    Write-Host "Deployment:"
    kubectl get deployment datetime-app
}

# Cleanup
function Remove-Resources {
    Write-Status "Cleaning up resources..."
    kubectl delete -f k8s\ --ignore-not-found=true
    Write-Status "Cleanup completed"
}

# Main script logic
switch ($Action.ToLower()) {
    "build" {
        Test-Prerequisites
        Build-AndPush
    }
    "deploy" {
        Test-Prerequisites
        Deploy-K8s
    }
    "expose" {
        Test-Prerequisites
        Expose-App
    }
    "status" {
        Show-Status
    }
    "cleanup" {
        Remove-Resources
    }
    "all" {
        Test-Prerequisites
        $buildSuccess = Build-AndPush
        if ($buildSuccess) {
            Deploy-K8s
            Expose-App
            Show-Status
        }
    }
    default {
        Write-Host "Usage: .\deploy.ps1 [-DockerUsername <username>] [-Tag <tag>] [-Action <action>]"
        Write-Host ""
        Write-Host "Actions:"
        Write-Host "  build   - Build and push Docker image"
        Write-Host "  deploy  - Deploy to Kubernetes"
        Write-Host "  expose  - Expose the application"
        Write-Host "  status  - Show deployment status"
        Write-Host "  cleanup - Remove all resources"
        Write-Host "  all     - Run all steps (default)"
        Write-Host ""
        Write-Host "Parameters:"
        Write-Host "  -DockerUsername - Your DockerHub username (default: your-dockerhub-username)"
        Write-Host "  -Tag           - Image tag (default: latest)"
        Write-Host "  -Action        - Action to perform (default: all)"
        Write-Host ""
        Write-Host "Examples:"
        Write-Host "  .\deploy.ps1 -DockerUsername myusername -Action all"
        Write-Host "  .\deploy.ps1 -Action build"
        Write-Host "  .\deploy.ps1 -Action status"
        exit 1
    }
}
