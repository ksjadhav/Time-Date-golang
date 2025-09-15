#!/bin/bash

# date-time-go Deployment Script
# This script helps deploy the application to DockerHub and Kubernetes

set -e

# Configuration
DOCKER_USERNAME=${DOCKER_USERNAME:-"your-dockerhub-username"}
IMAGE_NAME="date-time-go"
TAG=${TAG:-"latest"}
FULL_IMAGE_NAME="${DOCKER_USERNAME}/${IMAGE_NAME}:${TAG}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Functions
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if required tools are installed
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed or not in PATH"
        exit 1
    fi
    
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed or not in PATH"
        exit 1
    fi
    
    print_status "Prerequisites check passed"
}

# Build and push Docker image
build_and_push() {
    print_status "Building Docker image: ${FULL_IMAGE_NAME}"
    
    # Build the image
    docker build -t "${FULL_IMAGE_NAME}" .
    
    print_status "Docker image built successfully"
    
    # Check if user is logged in to DockerHub
    if ! docker info | grep -q "Username:"; then
        print_warning "Not logged in to DockerHub. Please run 'docker login' first"
        return 1
    fi
    
    print_status "Pushing image to DockerHub..."
    docker push "${FULL_IMAGE_NAME}"
    
    print_status "Image pushed successfully to DockerHub"
}

# Deploy to Kubernetes
deploy_k8s() {
    print_status "Deploying to Kubernetes..."
    
    # Update the image name in deployment.yaml
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        sed -i '' "s|your-dockerhub-username/date-time-go:latest|${FULL_IMAGE_NAME}|g" k8s/deployment.yaml
    else
        # Linux
        sed -i "s|your-dockerhub-username/date-time-go:latest|${FULL_IMAGE_NAME}|g" k8s/deployment.yaml
    fi
    
    # Apply Kubernetes manifests
    kubectl apply -f k8s/deployment.yaml
    kubectl apply -f k8s/service.yaml
    
    print_status "Waiting for deployment to be ready..."
    kubectl wait --for=condition=available --timeout=300s deployment/datetime-app
    
    print_status "Deployment completed successfully"
}

# Expose the application
expose_app() {
    print_status "Exposing the application..."
    
    # Option 1: LoadBalancer
    print_status "Creating LoadBalancer service..."
    kubectl apply -f k8s/loadbalancer-service.yaml
    
    print_status "Waiting for LoadBalancer to get external IP..."
    kubectl wait --for=condition=Ready --timeout=300s service/datetime-app-loadbalancer
    
    # Get external IP
    EXTERNAL_IP=$(kubectl get service datetime-app-loadbalancer -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    if [ -z "$EXTERNAL_IP" ]; then
        EXTERNAL_IP=$(kubectl get service datetime-app-loadbalancer -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
    fi
    
    if [ -n "$EXTERNAL_IP" ]; then
        print_status "Application is accessible at: http://${EXTERNAL_IP}"
    else
        print_warning "External IP not available yet. Check with: kubectl get service datetime-app-loadbalancer"
    fi
}

# Show status
show_status() {
    print_status "Current deployment status:"
    echo ""
    echo "Pods:"
    kubectl get pods -l app=datetime-app
    echo ""
    echo "Services:"
    kubectl get services -l app=datetime-app
    echo ""
    echo "Deployment:"
    kubectl get deployment datetime-app
}

# Cleanup
cleanup() {
    print_status "Cleaning up resources..."
    kubectl delete -f k8s/ --ignore-not-found=true
    print_status "Cleanup completed"
}

# Main script
main() {
    case "${1:-all}" in
        "build")
            check_prerequisites
            build_and_push
            ;;
        "deploy")
            check_prerequisites
            deploy_k8s
            ;;
        "expose")
            check_prerequisites
            expose_app
            ;;
        "status")
            show_status
            ;;
        "cleanup")
            cleanup
            ;;
        "all")
            check_prerequisites
            build_and_push
            deploy_k8s
            expose_app
            show_status
            ;;
        *)
            echo "Usage: $0 {build|deploy|expose|status|cleanup|all}"
            echo ""
            echo "Commands:"
            echo "  build   - Build and push Docker image"
            echo "  deploy  - Deploy to Kubernetes"
            echo "  expose  - Expose the application"
            echo "  status  - Show deployment status"
            echo "  cleanup - Remove all resources"
            echo "  all     - Run all steps (default)"
            echo ""
            echo "Environment variables:"
            echo "  DOCKER_USERNAME - Your DockerHub username (default: your-dockerhub-username)"
            echo "  TAG            - Image tag (default: latest)"
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
