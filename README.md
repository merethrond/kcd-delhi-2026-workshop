# KCD Delhi 2026 Workshop - Istio Multi-Cluster Service Mesh

This workshop demonstrates setting up a multi-cluster service mesh using Istio across two Kind clusters with a microservices application deployed.

## Workshop Overview

Learn how to:
- Set up two Kubernetes clusters using Kind
- Configure MetalLB for LoadBalancer services
- Install and configure Istio in multi-cluster mode
- Deploy a microservices application across clusters
- Enable cross-cluster service communication

## Architecture

### Cluster Configuration

**Cluster 1** (Primary)
- Pod Subnet: 10.244.0.0/16
- Service Subnet: 10.96.0.0/16
- MetalLB IP Range: 172.17.255.1-172.17.255.100
- Istio Network: network1
- Nodes: 1 control-plane + 2 workers

**Cluster 2** (Remote)
- Pod Subnet: 10.245.0.0/16
- Service Subnet: 10.97.0.0/16
- MetalLB IP Range: 172.17.255.101-172.17.255.200
- Istio Network: network2
- Nodes: 1 control-plane + 2 workers


### Application Architecture

**Simple Buy** - E-commerce Microservices Application

Services deployed on **Cluster 1**:
- **Auth Service** - User authentication
- **Cart Service** - Shopping cart management
- **Order Service** - Order processing
- **Notification Service** - Event-driven notifications
- **Frontend** - Next.js web application
- **Infrastructure**: PostgreSQL, Redis, RabbitMQ

Services deployed on **Cluster 2**:
- **Product Service** - Product catalog (remote service)
- **Shared Infrastructure**: PostgreSQL, RabbitMQ (for Product service)

The Product service on Cluster 2 is accessed by Cart and Frontend services on Cluster 1 through Istio's service mesh.

## Prerequisites

- Docker installed and running
- kubectl CLI tool
- 8GB+ RAM available
- Linux/Mac environment (or WSL2 on Windows)

## Workshop Setup

### Step 0: Install Tools

Install Kind and istioctl:

```bash
# Install Kind
./0-install-kind.sh

# Install istioctl
./0-install-istioctl.sh
```

### Step 1: Create Kubernetes Clusters

Create two Kind clusters with custom network configuration:

```bash
./1-cluster-setup.sh
```

This script:
- Creates cluster1 and cluster2 using configs in `configs/kind/`
- Configures pod and service network CIDRs
- Sets up 3 nodes per cluster (1 control-plane, 2 workers)

**Optional**: Pre-load container images to speed up deployment:

```bash
./1.2-preload-images.sh
```

### Step 2: Install MetalLB

Install and configure MetalLB on both clusters for LoadBalancer support:

```bash
./2-install-metallb.sh
```

This script:
- Installs MetalLB on both clusters
- Configures IP address pools using configs in `configs/metallb/`
- Cluster 1: 172.17.255.1-172.17.255.100
- Cluster 2: 172.17.255.101-172.17.255.200

### Step 3: Install Istio Multi-Cluster

Set up Istio in multi-primary configuration:

```bash
./3-istio-cluster-setup.sh
```

This script:
- Installs Istio on both clusters
- Configures network topology (network1, network2)
- Installs east-west gateways for cross-cluster communication
- Enables endpoint discovery across clusters

### Step 4: Configure Istio Secrets

Set up certificates and secrets for secure communication:

```bash
./4-istio-secrets.sh
```

This script:
- Generates CA certificates (if needed)
- Configures remote secrets for cross-cluster authentication
- Enables secure service discovery between clusters

### Step 5: Deploy Sample Application

Deploy the main application to Cluster 1:

```bash
./5-deploy-app.sh
```

This script:
- Deploys all services to Cluster 1 using Kustomize
- Creates the `simple-buy` namespace with Istio injection enabled
- Deploys infrastructure (PostgreSQL, Redis, RabbitMQ)
- Deploys microservices (Auth, Cart, Order, Notification, Frontend)
- Configures Istio Gateway and VirtualService

### Step 6: Deploy Product Service to Cluster 2

Deploy the Product service to Cluster 2:

```bash
./6-deploy-product-to-cluster2.sh
```

This script:
- Deploys Product service to Cluster 2
- Deploys supporting infrastructure (PostgreSQL, RabbitMQ)
- Configures service endpoints for cross-cluster access

## Verification

### Check Cluster Status

```bash
# Check Cluster 1
kubectl get pods -n simple-buy --context=kind-cluster1

# Check Cluster 2
kubectl get pods -n simple-buy --context=kind-cluster2

# Check Istio components
kubectl get pods -n istio-system --context=kind-cluster1
kubectl get pods -n istio-system --context=kind-cluster2
```

### Test Cross-Cluster Communication

```bash
# Get the Ingress Gateway IP
export GATEWAY_IP=$(kubectl get svc istio-ingressgateway -n istio-system --context=kind-cluster1 -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

echo "Gateway IP: $GATEWAY_IP"

# Access the application
curl http://$GATEWAY_IP
```

### Access Application UI

```bash
# Port forward to access the frontend
kubectl port-forward -n istio-system svc/istio-ingressgateway 8080:80 --context=kind-cluster1

# Open browser to http://localhost:8080
```

### Check Service Mesh

```bash
# View Istio proxy status
istioctl proxy-status --context=kind-cluster1

# Verify multi-cluster configuration
kubectl get serviceentries -n simple-buy --context=kind-cluster1
```

## Troubleshooting

### Check Pod Logs

```bash
# Auth service logs
kubectl logs -n simple-buy -l app=auth --context=kind-cluster1 --tail=50

# Product service logs (on cluster2)
kubectl logs -n simple-buy -l app=product --context=kind-cluster2 --tail=50
```

### Check Istio Configuration

```bash
# Verify Istio installation
istioctl verify-install --context=kind-cluster1

# Check proxy configuration
istioctl proxy-config endpoints <pod-name> -n simple-buy --context=kind-cluster1
```

### Common Issues

1. **Pods not starting**: Check if images are loaded/available
   ```bash
   docker images | grep simple-buy
   ```

2. **Cross-cluster communication failing**: Verify east-west gateway
   ```bash
   kubectl get svc -n istio-system --context=kind-cluster1
   kubectl get svc -n istio-system --context=kind-cluster2
   ```

3. **LoadBalancer IP pending**: Check MetalLB installation
   ```bash
   kubectl get pods -n metallb-system --context=kind-cluster1
   ```

## Project Structure

```
.
├── 0-install-istioctl.sh         # Install Istio CLI tool
├── 0-install-kind.sh              # Install Kind
├── 1-cluster-setup.sh             # Create Kind clusters
├── 1.2-preload-images.sh          # Pre-load container images
├── 2-install-metallb.sh           # Install MetalLB
├── 3-istio-cluster-setup.sh       # Install Istio multi-cluster
├── 4-istio-secrets.sh             # Configure Istio secrets
├── 5-deploy-app.sh                # Deploy app to Cluster 1
├── 6-deploy-product-to-cluster2.sh # Deploy Product to Cluster 2
├── configs/
│   ├── istio/                     # Istio configurations
│   │   ├── cluster1.yaml
│   │   ├── cluster2.yaml
│   │   ├── eastwest-gateway-cluster1.yaml
│   │   ├── eastwest-gateway-cluster2.yaml
│   │   ├── expose-services.yaml
│   │   └── istio-ca-secrets.yaml
│   ├── kind/                      # Kind cluster configurations
│   │   ├── cluster1-config.yaml
│   │   └── cluster2-config.yaml
│   └── metallb/                   # MetalLB configurations
│       ├── metallb-cluster1.yaml
│       └── metallb-cluster2.yaml
└── sample-app/                    # Application manifests
    ├── kustomization.yaml
    ├── namespace.yaml
    ├── *-deployment.yaml
    ├── *-statefulset.yaml
    ├── istio-gateway.yaml
    ├── istio-virtualservice.yaml
    └── cluster2-manifests/        # Cluster 2 specific manifests
```

## Cleanup

Remove all resources and clusters:

```bash
# Delete clusters
kind delete cluster --name cluster1
kind delete cluster --name cluster2
```

## Additional Resources

- [Istio Multi-Cluster Documentation](https://istio.io/latest/docs/setup/install/multicluster/)
- [Kind Documentation](https://kind.sigs.k8s.io/)
- [MetalLB Documentation](https://metallb.universe.tf/)

## Workshop Credits

KCD Delhi 2026 - Multi-Cluster Service Mesh with Istio

