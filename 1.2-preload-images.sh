#!/bin/bash
set -e

echo "====================================="
echo "Pre-loading images into kind clusters"
echo "====================================="

# List of images to preload
IMAGES=(
    "docker.io/istio/pilot:1.28.3"
    "docker.io/istio/proxyv2:1.28.3"
    "quay.io/metallb/controller:v0.14.9"
    "quay.io/metallb/speaker:v0.14.9"
)

CLUSTERS=("cluster1" "cluster2")

# Pull all images locally
echo ""
echo "Step 1: Checking and pulling images locally..."
for image in "${IMAGES[@]}"; do
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
    for image in "${IMAGES[@]}"; do
        echo "    Loading $image into $cluster..."
        kind load docker-image "$image" --name "$cluster" || echo "    Warning: Failed to load $image into $cluster"
    done
done

echo ""
echo "====================================="
echo "Image preloading completed!"
echo "====================================="
echo ""
echo "To verify images on nodes, run:"
echo "  docker exec cluster1-control-plane crictl images"
echo "  docker exec cluster2-control-plane crictl images"
