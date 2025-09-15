@echo off
REM date-time-go Deployment Script for Windows Command Prompt
REM This script helps deploy the application to DockerHub and Kubernetes

setlocal enabledelayedexpansion

REM Configuration
if "%DOCKER_USERNAME%"=="" set DOCKER_USERNAME=your-dockerhub-username
if "%TAG%"=="" set TAG=latest
if "%ACTION%"=="" set ACTION=all

set IMAGE_NAME=date-time-go
set FULL_IMAGE_NAME=%DOCKER_USERNAME%/%IMAGE_NAME%:%TAG%

REM Functions
:print_status
echo [INFO] %~1
goto :eof

:print_warning
echo [WARNING] %~1
goto :eof

:print_error
echo [ERROR] %~1
goto :eof

REM Check if required tools are installed
:check_prerequisites
call :print_status "Checking prerequisites..."

docker --version >nul 2>&1
if errorlevel 1 (
    call :print_error "Docker is not installed or not in PATH"
    exit /b 1
)

kubectl version --client >nul 2>&1
if errorlevel 1 (
    call :print_error "kubectl is not installed or not in PATH"
    exit /b 1
)

call :print_status "Prerequisites check passed"
goto :eof

REM Build and push Docker image
:build_and_push
call :print_status "Building Docker image: %FULL_IMAGE_NAME%"

docker build -t %FULL_IMAGE_NAME% .
if errorlevel 1 (
    call :print_error "Docker build failed"
    exit /b 1
)

call :print_status "Docker image built successfully"

REM Check if user is logged in to DockerHub
docker info | findstr "Username:" >nul
if errorlevel 1 (
    call :print_warning "Not logged in to DockerHub. Please run 'docker login' first"
    exit /b 1
)

call :print_status "Pushing image to DockerHub..."
docker push %FULL_IMAGE_NAME%
if errorlevel 1 (
    call :print_error "Docker push failed"
    exit /b 1
)

call :print_status "Image pushed successfully to DockerHub"
goto :eof

REM Deploy to Kubernetes
:deploy_k8s
call :print_status "Deploying to Kubernetes..."

REM Update the image name in deployment.yaml
powershell -Command "(Get-Content 'k8s\deployment.yaml') -replace 'your-dockerhub-username/date-time-go:latest', '%FULL_IMAGE_NAME%' | Set-Content 'k8s\deployment.yaml'"

REM Apply Kubernetes manifests
kubectl apply -f k8s\deployment.yaml
kubectl apply -f k8s\service.yaml

call :print_status "Waiting for deployment to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/datetime-app

call :print_status "Deployment completed successfully"
goto :eof

REM Expose the application
:expose_app
call :print_status "Exposing the application..."

call :print_status "Creating LoadBalancer service..."
kubectl apply -f k8s\loadbalancer-service.yaml

call :print_status "Waiting for LoadBalancer to get external IP..."
kubectl wait --for=condition=Ready --timeout=300s service/datetime-app-loadbalancer

REM Get external IP
for /f "tokens=*" %%i in ('kubectl get service datetime-app-loadbalancer -o jsonpath="{.status.loadBalancer.ingress[0].ip}"') do set EXTERNAL_IP=%%i

if "%EXTERNAL_IP%"=="" (
    for /f "tokens=*" %%i in ('kubectl get service datetime-app-loadbalancer -o jsonpath="{.status.loadBalancer.ingress[0].hostname}"') do set EXTERNAL_IP=%%i
)

if not "%EXTERNAL_IP%"=="" (
    call :print_status "Application is accessible at: http://%EXTERNAL_IP%"
) else (
    call :print_warning "External IP not available yet. Check with: kubectl get service datetime-app-loadbalancer"
)
goto :eof

REM Show status
:show_status
call :print_status "Current deployment status:"
echo.
echo Pods:
kubectl get pods -l app=datetime-app
echo.
echo Services:
kubectl get services -l app=datetime-app
echo.
echo Deployment:
kubectl get deployment datetime-app
goto :eof

REM Cleanup
:cleanup
call :print_status "Cleaning up resources..."
kubectl delete -f k8s\ --ignore-not-found=true
call :print_status "Cleanup completed"
goto :eof

REM Main script logic
if "%ACTION%"=="build" (
    call :check_prerequisites
    call :build_and_push
) else if "%ACTION%"=="deploy" (
    call :check_prerequisites
    call :deploy_k8s
) else if "%ACTION%"=="expose" (
    call :check_prerequisites
    call :expose_app
) else if "%ACTION%"=="status" (
    call :show_status
) else if "%ACTION%"=="cleanup" (
    call :cleanup
) else if "%ACTION%"=="all" (
    call :check_prerequisites
    call :build_and_push
    if not errorlevel 1 (
        call :deploy_k8s
        call :expose_app
        call :show_status
    )
) else (
    echo Usage: deploy.bat [ACTION] [DOCKER_USERNAME] [TAG]
    echo.
    echo Actions:
    echo   build   - Build and push Docker image
    echo   deploy  - Deploy to Kubernetes
    echo   expose  - Expose the application
    echo   status  - Show deployment status
    echo   cleanup - Remove all resources
    echo   all     - Run all steps (default)
    echo.
    echo Environment variables:
    echo   DOCKER_USERNAME - Your DockerHub username (default: your-dockerhub-username)
    echo   TAG            - Image tag (default: latest)
    echo   ACTION         - Action to perform (default: all)
    echo.
    echo Examples:
    echo   deploy.bat all myusername
    echo   deploy.bat build myusername latest
    echo   set DOCKER_USERNAME=myusername && deploy.bat all
    exit /b 1
)
