# date-time-go - Date & Time Web Application

A simple GoLang web application that displays the current date and time, containerized with Docker and deployed on Kubernetes.

## Features

- 🕐 Real-time date and time display
- 🎨 Beautiful, responsive web interface
- 🐳 Docker containerized
- ☸️ Kubernetes deployment ready
- 🔄 Auto-refresh every 5 seconds
- 🏥 Health check endpoints
- 🔒 Security best practices (non-root user, read-only filesystem)

## Project Structure

```
.
├── main.go                    # Go web application
├── go.mod                     # Go module file
├── go.sum                     # Go dependencies
├── Dockerfile                 # Docker configuration
├── docker-compose.yml         # Local development setup
├── .dockerignore             # Docker ignore file
├── k8s/                      # Kubernetes manifests
│   ├── deployment.yaml       # K8s deployment (2 replicas)
│   ├── service.yaml          # K8s ClusterIP service
│   ├── loadbalancer-service.yaml # K8s LoadBalancer service
│   └── ingress.yaml          # K8s Ingress for external access
└── README.md                 # This file
```

## Prerequisites

- Go 1.21+
- Docker Desktop for Windows
- Docker Hub account
- Kubernetes cluster (Docker Desktop includes Kubernetes)
- kubectl configured
- PowerShell 5.1+ or Windows Command Prompt

## Windows Setup Instructions

### Enable PowerShell Script Execution
```powershell
# Run PowerShell as Administrator
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Enable Kubernetes in Docker Desktop
1. Open Docker Desktop
2. Go to Settings → Kubernetes
3. Check "Enable Kubernetes"
4. Click "Apply & Restart"

## Step 1: Create GoLang Program and Push to DockerHub

### 1.1 Test the Go Application Locally

**PowerShell:**
```powershell
# Run the application locally
go run main.go

# Test in browser: http://localhost:8080
# Test health endpoint: Invoke-WebRequest http://localhost:8080/health
```

**Command Prompt:**
```cmd
REM Run the application locally
go run main.go

REM Test in browser: http://localhost:8080
REM Test health endpoint: curl http://localhost:8080/health
```

### 1.2 Build Docker Image

**PowerShell/Command Prompt:**
```powershell
# Build the Docker image
docker build -t your-dockerhub-username/date-time-go:latest .

# Test the Docker image locally
docker run -p 8080:8080 your-dockerhub-username/date-time-go:latest
```

### 1.3 Push to DockerHub

**PowerShell/Command Prompt:**
```powershell
# Login to DockerHub
docker login

# Push the image to DockerHub
docker push your-dockerhub-username/date-time-go:latest
```

### 1.4 Test with Docker Compose

**PowerShell/Command Prompt:**
```powershell
# Start the application
docker-compose up -d

# Check logs
docker-compose logs -f

# Access the application at http://localhost:8080

# Stop the application
docker-compose down
```

## Step 2: Deploy to Kubernetes with 2 Replicas

### 2.1 Update Docker Image Reference

Edit `k8s/deployment.yaml` and replace `your-dockerhub-username/date-time-go:latest` with your actual DockerHub image.

### 2.2 Deploy to Kubernetes

**PowerShell/Command Prompt:**
```powershell
# Deploy the application with 2 replicas
kubectl apply -f k8s\deployment.yaml
kubectl apply -f k8s\service.yaml

# Verify deployment
kubectl get deployments
kubectl get pods
kubectl get services

# Check that you have 2 replicas running
kubectl get pods -l app=datetime-app
```

### 2.3 Verify the Deployment

**PowerShell/Command Prompt:**
```powershell
# Port forward to test locally
kubectl port-forward service/datetime-app-service 8080:80

# Access the application at http://localhost:8080
```

## Step 3: Expose the App to Internet (WAN)

### Option A: Using LoadBalancer Service (Recommended for Cloud)

**PowerShell/Command Prompt:**
```powershell
# Apply LoadBalancer service
kubectl apply -f k8s\loadbalancer-service.yaml

# Get external IP
kubectl get service datetime-app-loadbalancer

# Wait for external IP assignment
kubectl wait --for=condition=Ready --timeout=300s service/datetime-app-loadbalancer

# Access via external IP: http://<EXTERNAL-IP>
```

### Option B: Using Ingress (For Production with Domain)

#### Prerequisites:
- NGINX Ingress Controller installed
- Domain name configured

**PowerShell/Command Prompt:**
```powershell
# Install NGINX Ingress Controller (if not already installed)
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/cloud/deploy.yaml

# Update ingress.yaml with your domain
# Edit k8s\ingress.yaml and change 'datetime-app.local' to your domain

# Apply ingress
kubectl apply -f k8s\ingress.yaml

# Check ingress status
kubectl get ingress

# Access via your domain: http://your-domain.com
```

### Option C: Using NodePort (For Testing)

**PowerShell/Command Prompt:**
```powershell
# Create NodePort service
kubectl expose deployment datetime-app --type=NodePort --port=80 --name=datetime-app-nodeport

# Get NodePort
kubectl get service datetime-app-nodeport

# Access via <NODE-IP>:<NODE-PORT>
```

## Quick Deployment Scripts

### Windows PowerShell (Recommended)
```powershell
# Set your DockerHub username
$env:DOCKER_USERNAME = "your-dockerhub-username"

# Run complete deployment
.\deploy.ps1 -DockerUsername "your-dockerhub-username" -Action all

# Or run individual steps
.\deploy.ps1 -Action build
.\deploy.ps1 -Action deploy
.\deploy.ps1 -Action expose
.\deploy.ps1 -Action status
```

### Windows Command Prompt
```cmd
REM Set your DockerHub username
set DOCKER_USERNAME=your-dockerhub-username

REM Run complete deployment
deploy.bat all your-dockerhub-username

REM Or run individual steps
deploy.bat build your-dockerhub-username
deploy.bat deploy
deploy.bat expose
deploy.bat status
```

### Linux/Mac Bash
```bash
# Set your DockerHub username
export DOCKER_USERNAME="your-dockerhub-username"

# Run complete deployment
./deploy.sh all

# Or run individual steps
./deploy.sh build
./deploy.sh deploy
./deploy.sh expose
./deploy.sh status
```

## Monitoring and Health Checks

The application includes health check endpoints:

- **Health Check**: `GET /health` - Returns 200 OK
- **Main Page**: `GET /` - Displays current date and time

## Scaling

```bash
# Scale to more replicas
kubectl scale deployment datetime-app --replicas=5

# Check scaling status
kubectl get deployment datetime-app
```

## Troubleshooting

### Check Pod Status
```bash
kubectl get pods -l app=datetime-app
kubectl describe pod <pod-name>
```

### Check Logs
```bash
kubectl logs -l app=datetime-app
kubectl logs -l app=datetime-app --previous
```

### Check Events
```bash
kubectl get events --sort-by=.metadata.creationTimestamp
```

### Debug Pod
```bash
kubectl exec -it <pod-name> -- /bin/sh
```

## Security Features

- Non-root user execution
- Read-only root filesystem
- Dropped capabilities
- Resource limits
- Health checks
- Security context

## Development

### Local Development

```bash
# Run locally with Go
go run main.go

# Run with Docker
docker-compose up

# Build and test
go build -o datetime-app main.go
./datetime-app
```

### Testing

```bash
# Test health endpoint
curl http://localhost:8080/health

# Test main endpoint
curl http://localhost:8080/
```

## Cleanup

```bash
# Remove from Kubernetes
kubectl delete -f k8s/

# Remove Docker containers
docker-compose down

# Remove Docker images
docker rmi your-dockerhub-username/date-time-go:latest
```

## Summary

This project demonstrates:

1. ✅ **GoLang Program**: Web application displaying current date & time
2. ✅ **Docker**: Containerized application pushed to DockerHub
3. ✅ **Kubernetes**: Declarative deployment with 2 replicas
4. ✅ **Internet Access**: Multiple options for exposing the app to WAN

The application is production-ready with security best practices, health checks, and proper resource management.
