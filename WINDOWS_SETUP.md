# Windows Setup Guide for date-time-go

This guide provides step-by-step instructions for setting up and deploying the date-time-go application on Windows.

## Prerequisites

### 1. Install Go
1. Download Go from https://golang.org/dl/
2. Run the installer and follow the setup wizard
3. Verify installation:
   ```cmd
   go version
   ```

### 2. Install Docker Desktop
1. Download Docker Desktop from https://www.docker.com/products/docker-desktop/
2. Install and restart your computer
3. Start Docker Desktop
4. Verify installation:
   ```cmd
   docker --version
   docker-compose --version
   ```

### 3. Enable Kubernetes in Docker Desktop
1. Open Docker Desktop
2. Click the gear icon (Settings)
3. Go to "Kubernetes" in the left sidebar
4. Check "Enable Kubernetes"
5. Click "Apply & Restart"
6. Wait for Kubernetes to start (green indicator)

### 4. Install kubectl (if not included with Docker Desktop)
1. Download kubectl from https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/
2. Add to your PATH or place in a directory in your PATH
3. Verify installation:
   ```cmd
   kubectl version --client
   ```

### 5. Enable PowerShell Script Execution
1. Open PowerShell as Administrator
2. Run:
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```
3. Type "Y" when prompted

## Quick Start

### Option 1: Using PowerShell Scripts (Recommended)

1. **Test the Go application:**
   ```powershell
   .\test-local.ps1
   ```

2. **Test with Docker:**
   ```powershell
   .\test-docker.ps1
   ```

3. **Deploy everything:**
   ```powershell
   # Set your DockerHub username
   $env:DOCKER_USERNAME = "your-dockerhub-username"
   
   # Deploy everything
   .\deploy.ps1 -DockerUsername "your-dockerhub-username" -Action all
   ```

### Option 2: Using Command Prompt

1. **Test the Go application:**
   ```cmd
   test-local.bat
   ```

2. **Test with Docker:**
   ```cmd
   test-docker.bat
   ```

3. **Deploy everything:**
   ```cmd
   REM Set your DockerHub username
   set DOCKER_USERNAME=your-dockerhub-username
   
   REM Deploy everything
   deploy.bat all your-dockerhub-username
   ```

## Step-by-Step Manual Deployment

### Step 1: Test and Build

1. **Test Go application:**
   ```cmd
   go run main.go
   ```
   Open http://localhost:8080 in your browser

2. **Build Docker image:**
   ```cmd
   docker build -t your-dockerhub-username/date-time-go:latest .
   ```

3. **Test Docker image:**
   ```cmd
   docker run -p 8080:8080 your-dockerhub-username/date-time-go:latest
   ```

4. **Login to DockerHub:**
   ```cmd
   docker login
   ```

5. **Push to DockerHub:**
   ```cmd
   docker push your-dockerhub-username/date-time-go:latest
   ```

### Step 2: Deploy to Kubernetes

1. **Update deployment.yaml:**
   - Open `k8s\deployment.yaml`
   - Replace `your-dockerhub-username/date-time-go:latest` with your actual image

2. **Deploy to Kubernetes:**
   ```cmd
   kubectl apply -f k8s\deployment.yaml
   kubectl apply -f k8s\service.yaml
   ```

3. **Verify deployment:**
   ```cmd
   kubectl get pods
   kubectl get services
   ```

4. **Test locally:**
   ```cmd
   kubectl port-forward service/datetime-app-service 8080:80
   ```
   Open http://localhost:8080 in your browser

### Step 3: Expose to Internet

1. **Using LoadBalancer:**
   ```cmd
   kubectl apply -f k8s\loadbalancer-service.yaml
   kubectl get service datetime-app-loadbalancer
   ```

2. **Using NodePort (for testing):**
   ```cmd
   kubectl expose deployment datetime-app --type=NodePort --port=80 --name=datetime-app-nodeport
   kubectl get service datetime-app-nodeport
   ```

## Troubleshooting

### Common Issues

1. **PowerShell execution policy error:**
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

2. **Docker not running:**
   - Start Docker Desktop
   - Wait for it to fully start (green indicator)

3. **Kubernetes not enabled:**
   - Go to Docker Desktop Settings → Kubernetes
   - Enable Kubernetes and restart

4. **kubectl not found:**
   - Add kubectl to your PATH
   - Or use the full path to kubectl.exe

5. **Port already in use:**
   ```cmd
   netstat -ano | findstr :8080
   taskkill /PID <PID> /F
   ```

### Useful Commands

```cmd
# Check Docker status
docker info

# Check Kubernetes status
kubectl cluster-info

# Check running pods
kubectl get pods

# Check services
kubectl get services

# View logs
kubectl logs -l app=datetime-app

# Delete everything
kubectl delete -f k8s\
```

## File Structure

```
date-time-go/
├── main.go                    # Go web application
├── go.mod                     # Go module file
├── go.sum                     # Go dependencies
├── Dockerfile                 # Docker configuration
├── docker-compose.yml         # Local development setup
├── .dockerignore             # Docker ignore file
├── .gitignore                # Git ignore file
├── deploy.ps1                # PowerShell deployment script
├── deploy.bat                # Command Prompt deployment script
├── deploy.sh                 # Linux/Mac deployment script
├── test-local.ps1            # PowerShell test script
├── test-local.bat            # Command Prompt test script
├── test-docker.ps1           # PowerShell Docker test script
├── test-docker.bat           # Command Prompt Docker test script
├── README.md                 # Main documentation
├── WINDOWS_SETUP.md          # This file
└── k8s/                      # Kubernetes manifests
    ├── deployment.yaml       # K8s deployment (2 replicas)
    ├── service.yaml          # K8s ClusterIP service
    ├── loadbalancer-service.yaml # K8s LoadBalancer service
    └── ingress.yaml          # K8s Ingress for external access
```

## Next Steps

1. **Push to GitHub:**
   ```cmd
   git init
   git add .
   git commit -m "Initial commit"
   git remote add origin https://github.com/yourusername/pg-room-finder.git
   git push -u origin main
   ```

2. **Set up CI/CD** (optional):
   - GitHub Actions
   - Azure DevOps
   - GitLab CI

3. **Monitor your application:**
   - Use `kubectl get pods` to check status
   - Use `kubectl logs` to view logs
   - Set up monitoring with Prometheus/Grafana

## Support

If you encounter issues:
1. Check the troubleshooting section above
2. Verify all prerequisites are installed
3. Check Docker Desktop is running
4. Ensure Kubernetes is enabled in Docker Desktop
5. Check the logs with `kubectl logs -l app=datetime-app`
