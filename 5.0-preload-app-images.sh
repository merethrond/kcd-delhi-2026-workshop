#!/bin/bash
set -e

echo "=========================================="
echo "Pre-loading sample app images into kind clusters"
echo "=========================================="

# List of sample application images
APP_IMAGES=(
    # Database and messaging
    "redis:7-alpine"
    "rabbitmq:3-management-alpine"
    "postgres:16-alpine"
    # Microservices
    "sayedimran/simple-buy-frontend:v1.0.1"
    "sayedimran/simple-buy-auth:v1.0.0"
    "sayedimran/simple-buy-cart:v1.0.0"
    "sayedimran/simple-buy-order:v1.0.0"
    "sayedimran/simple-buy-product:v1.0.0"
    "sayedimran/simple-buy-notification:v1.0.0"
)

CLUSTERS=("cluster1")

# Pull all images locally
echo ""
echo "Step 1: Checking and pulling images locally..."
for image in "${APP_IMAGES[@]}"; do
    if docker image inspect "$image" &>/dev/null; then
        echo "  ✓ $image already exists locally"
    else
        echo "  Pulling $image..."
        docker pull "$image" || echo "  Warning: Failed to pull $image"
    fi
done

# Load images into each kind cluster
echo ""
echo "Step 2: Loading images into kind clusters..."
for cluster in "${CLUSTERS[@]}"; do
    echo ""
    echo "  Loading images into $cluster..."
    for image in "${APP_IMAGES[@]}"; do
        echo "    Loading $image into $cluster..."
        kind load docker-image "$image" --name "$cluster" || echo "    Warning: Failed to load $image into $cluster"
    done
done

echo ""
echo "=========================================="
echo "Sample app image preloading completed!"
echo "=========================================="
echo ""
echo "To verify images on nodes, run:"
echo "  docker exec cluster1-control-plane crictl images | grep -E 'redis|rabbitmq|postgres|simple-buy'"
echo "  docker exec cluster2-control-plane crictl images | grep -E 'redis|rabbitmq|postgres|simple-buy'"
