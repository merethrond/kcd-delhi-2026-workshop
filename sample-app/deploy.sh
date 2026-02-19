#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed"
        exit 1
    fi
    log_success "Docker found"
    
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl is not installed"
        exit 1
    fi
    log_success "kubectl found"
    
    # Check if cluster is reachable
    if ! kubectl cluster-info &> /dev/null; then
        log_error "Cannot connect to Kubernetes cluster"
        exit 1
    fi
    log_success "Kubernetes cluster is reachable"
}

# Detect cluster type
detect_cluster() {
    if kubectl config current-context | grep -q "minikube"; then
        echo "minikube"
    elif kubectl config current-context | grep -q "kind"; then
        echo "kind"
    elif kubectl config current-context | grep -q "docker-desktop"; then
        echo "docker-desktop"
    else
        echo "other"
    fi
}

# Build Docker images
build_images() {
    log_info "Building Docker images..."
    
    services=("auth" "product" "cart" "order" "notification")
    
    for service in "${services[@]}"; do
        log_info "Building $service..."
        docker build -f "services/$service/Dockerfile" -t "sayedimran/simple-buy-$service:v1.0.0" . || {
            log_error "Failed to build $service"
            exit 1
        }
        log_success "$service built successfully"
    done
    
    log_info "Building frontend..."
    docker build -f "frontend/Dockerfile" -t "sayedimran/simple-buy-frontend:v1.0.0" frontend/ || {
        log_error "Failed to build frontend"
        exit 1
    }
    log_success "Frontend built successfully"
    
    log_success "All images built successfully"
}

# Load images into cluster
load_images() {
    local cluster_type=$1
    
    log_info "Loading images into $cluster_type cluster..."
    
    images=("sayedimran/simple-buy-auth:v1.0.0" "sayedimran/simple-buy-product:v1.0.0" "sayedimran/simple-buy-cart:v1.0.0" 
            "sayedimran/simple-buy-order:v1.0.0" "sayedimran/simple-buy-notification:v1.0.0" "sayedimran/simple-buy-frontend:v1.0.0")
    
    for image in "${images[@]}"; do
        log_info "Loading $image..."
        
        if [ "$cluster_type" = "minikube" ]; then
            minikube image load "$image" || {
                log_error "Failed to load $image into minikube"
                exit 1
            }
        elif [ "$cluster_type" = "kind" ]; then
            kind load docker-image "$image" || {
                log_error "Failed to load $image into kind"
                exit 1
            }
        else
            log_warning "Skipping image load for $cluster_type cluster (assuming registry access)"
        fi
        
        log_success "$image loaded"
    done
    
    log_success "All images loaded successfully"
}

# Deploy to Kubernetes
deploy_k8s() {
    log_info "Deploying to Kubernetes..."
    
    # Create namespace if doesn't exist
    if ! kubectl get namespace simple-buy &> /dev/null; then
        kubectl create namespace simple-buy
        log_success "Namespace created"
    else
        log_info "Namespace already exists"
    fi
    
    # Apply all manifests
    kubectl apply -f k8s/ || {
        log_error "Failed to apply manifests"
        exit 1
    }
    log_success "Manifests applied successfully"
    
    # Wait for rollout
    log_info "Waiting for deployments to be ready (this may take a few minutes)..."
    
    # Wait for infrastructure first
    log_info "Waiting for PostgreSQL..."
    kubectl wait --for=condition=ready pod -l app=postgres -n simple-buy --timeout=300s || log_warning "PostgreSQL timeout"
    
    log_info "Waiting for Redis..."
    kubectl wait --for=condition=ready pod -l app=redis -n simple-buy --timeout=120s || log_warning "Redis timeout"
    
    log_info "Waiting for RabbitMQ..."
    kubectl wait --for=condition=ready pod -l app=rabbitmq -n simple-buy --timeout=180s || log_warning "RabbitMQ timeout"
    
    # Wait for services
    log_info "Waiting for services..."
    kubectl wait --for=condition=ready pod -l app=auth -n simple-buy --timeout=180s || log_warning "Auth timeout"
    kubectl wait --for=condition=ready pod -l app=product -n simple-buy --timeout=180s || log_warning "Product timeout"
    kubectl wait --for=condition=ready pod -l app=cart -n simple-buy --timeout=180s || log_warning "Cart timeout"
    kubectl wait --for=condition=ready pod -l app=order -n simple-buy --timeout=180s || log_warning "Order timeout"
    kubectl wait --for=condition=ready pod -l app=notification -n simple-buy --timeout=180s || log_warning "Notification timeout"
    kubectl wait --for=condition=ready pod -l app=frontend -n simple-buy --timeout=180s || log_warning "Frontend timeout"
    kubectl wait --for=condition=ready pod -l app=nginx -n simple-buy --timeout=120s || log_warning "Nginx timeout"
    
    log_success "Deployment complete!"
}

# Show access information
show_access_info() {
    local cluster_type=$1
    
    log_info "Access Information:"
    echo ""
    
    if [ "$cluster_type" = "minikube" ]; then
        log_info "To access the application:"
        echo "  minikube service nginx -n simple-buy"
        echo ""
        log_info "Or use port-forward:"
        echo "  kubectl port-forward -n simple-buy svc/nginx 8080:80"
        echo "  Then visit: http://localhost:8080"
    elif [ "$cluster_type" = "kind" ] || [ "$cluster_type" = "docker-desktop" ]; then
        log_info "To access the application, use port-forward:"
        echo "  kubectl port-forward -n simple-buy svc/nginx 8080:80"
        echo "  Then visit: http://localhost:8080"
    else
        log_info "To get the external IP:"
        echo "  kubectl get svc nginx -n simple-buy"
    fi
    
    echo ""
    log_info "RabbitMQ Management UI:"
    echo "  kubectl port-forward -n simple-buy rabbitmq-0 15672:15672"
    echo "  Then visit: http://localhost:15672 (guest/guest)"
    
    echo ""
    log_info "Check status:"
    echo "  kubectl get all -n simple-buy"
    
    echo ""
    log_info "View logs:"
    echo "  kubectl logs -n simple-buy -l app=auth --tail=50"
    
    echo ""
    log_success "Deployment successful! 🎉"
}

# Main script
main() {
    echo ""
    echo "╔════════════════════════════════════════╗"
    echo "║   Simple Buy Kubernetes Deployment    ║"
    echo "╚════════════════════════════════════════╝"
    echo ""
    
    # Parse arguments
    SKIP_BUILD=false
    SKIP_LOAD=false
    SKIP_DEPLOY=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --skip-build)
                SKIP_BUILD=true
                shift
                ;;
            --skip-load)
                SKIP_LOAD=true
                shift
                ;;
            --skip-deploy)
                SKIP_DEPLOY=true
                shift
                ;;
            --help)
                echo "Usage: $0 [OPTIONS]"
                echo ""
                echo "Options:"
                echo "  --skip-build    Skip building Docker images"
                echo "  --skip-load     Skip loading images into cluster"
                echo "  --skip-deploy   Skip deploying to Kubernetes"
                echo "  --help          Show this help message"
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done
    
    # Check prerequisites
    check_prerequisites
    
    # Detect cluster type
    CLUSTER_TYPE=$(detect_cluster)
    log_info "Detected cluster type: $CLUSTER_TYPE"
    
    # Build images
    if [ "$SKIP_BUILD" = false ]; then
        build_images
    else
        log_warning "Skipping image build"
    fi
    
    # Load images
    if [ "$SKIP_LOAD" = false ] && [ "$CLUSTER_TYPE" != "other" ]; then
        load_images "$CLUSTER_TYPE"
    else
        [ "$SKIP_LOAD" = true ] && log_warning "Skipping image load"
    fi
    
    # Deploy
    if [ "$SKIP_DEPLOY" = false ]; then
        deploy_k8s
        show_access_info "$CLUSTER_TYPE"
    else
        log_warning "Skipping deployment"
    fi
}

# Run main function
main "$@"
