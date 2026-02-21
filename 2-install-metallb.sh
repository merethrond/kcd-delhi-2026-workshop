#!/bin/bash
set -e

echo "Detecting kind network IP range..."

# Get the kind network subnet (IPv4 only)
KIND_NETWORK=$(docker network inspect kind | jq -r '.[0].IPAM.Config[] | select(.Subnet | contains(":") | not) | .Subnet' | head -n1)

if [ -z "$KIND_NETWORK" ] || [ "$KIND_NETWORK" == "null" ]; then
    echo "Error: Could not detect kind network. Make sure kind clusters are created first."
    exit 1
fi

echo "Kind network detected: $KIND_NETWORK"

# Extract the first two octets and calculate IP ranges
FIRST_TWO_OCTETS=$(echo "$KIND_NETWORK" | cut -d'.' -f1-2)
echo "Using IP prefix: $FIRST_TWO_OCTETS"

# Define IP ranges for MetalLB (using high range to avoid conflicts)
CLUSTER1_START="${FIRST_TWO_OCTETS}.255.1"
CLUSTER1_END="${FIRST_TWO_OCTETS}.255.100"
CLUSTER2_START="${FIRST_TWO_OCTETS}.255.101"
CLUSTER2_END="${FIRST_TWO_OCTETS}.255.200"

echo ""
echo "Updating MetalLB IP ranges:"
echo "  Cluster1: ${CLUSTER1_START}-${CLUSTER1_END}"
echo "  Cluster2: ${CLUSTER2_START}-${CLUSTER2_END}"
echo ""

# Update metallb-cluster1.yaml
echo "Updating metallb-cluster1.yaml..."
# Remove existing IP address lines
sed -i '/^    - [0-9]/d' configs/metallb/metallb-cluster1.yaml
# Add new IP range after addresses:
sed -i "/addresses:/a\    - ${CLUSTER1_START}-${CLUSTER1_END}" configs/metallb/metallb-cluster1.yaml

# Update metallb-cluster2.yaml
echo "Updating metallb-cluster2.yaml..."
# Remove existing IP address lines
sed -i '/^    - [0-9]/d' configs/metallb/metallb-cluster2.yaml
# Add new IP range after addresses:
sed -i "/addresses:/a\    - ${CLUSTER2_START}-${CLUSTER2_END}" configs/metallb/metallb-cluster2.yaml

echo ""
echo "Installing MetalLB on cluster1..."
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.9/config/manifests/metallb-native.yaml --context kind-cluster1

echo "Installing MetalLB on cluster2..."
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.9/config/manifests/metallb-native.yaml --context kind-cluster2
echo "Waiting for MetalLB pods to be ready on cluster1..."
kubectl wait --namespace metallb-system --for=condition=ready pod --selector=app=metallb --timeout=90s --context kind-cluster1
sleep 5
kubectl apply -f configs/metallb/metallb-cluster1.yaml --context kind-cluster1

echo "Waiting for MetalLB pods to be ready on cluster2..."
kubectl wait --namespace metallb-system --for=condition=ready pod --selector=app=metallb --timeout=90s --context kind-cluster2
sleep 5
kubectl apply -f configs/metallb/metallb-cluster2.yaml --context kind-cluster2

echo ""
echo "✅ Setup complete!"
echo ""
echo "MetalLB IP ranges configured:"
echo "  Cluster1: ${CLUSTER1_START}-${CLUSTER1_END}"
echo "  Cluster2: ${CLUSTER2_START}-${CLUSTER2_END}"
