# Kubernetes Deployment for Simple Buy

This directory contains Kubernetes manifests for deploying the Simple Buy microservices application.

## Architecture Overview

The application consists of:
- **5 Backend Microservices**: Auth, Product, Cart, Order, Notification
- **1 Frontend**: Next.js application
- **1 API Gateway**: Nginx reverse proxy
- **Infrastructure**: PostgreSQL, Redis, RabbitMQ

## Prerequisites

1. **Kubernetes Cluster** (v1.20+)
   - Local: Minikube, Kind, Docker Desktop Kubernetes
   - Cloud: GKE, EKS, AKS, or any managed Kubernetes service

2. **kubectl** CLI tool installed and configured

3. **Docker Images** built and available:
   ```bash
   # Build all service images
   docker build -f services/auth/Dockerfile -t sayedimran/simple-buy-auth:v1.0.0 .
   docker build -f services/product/Dockerfile -t sayedimran/simple-buy-product:v1.0.0 .
   docker build -f services/cart/Dockerfile -t sayedimran/simple-buy-cart:v1.0.0 .
   docker build -f services/order/Dockerfile -t sayedimran/simple-buy-order:v1.0.0 .
   docker build -f services/notification/Dockerfile -t sayedimran/simple-buy-notification:v1.0.0 .
   docker build -f frontend/Dockerfile -t sayedimran/simple-buy-frontend:v1.0.0 frontend/
   
   # Or build multi-arch images (AMD64 + ARM64) and push to registry
   docker buildx create --use --name multiarch-builder 2>/dev/null || docker buildx use multiarch-builder
   docker buildx build --platform linux/amd64,linux/arm64 -f services/auth/Dockerfile -t sayedimran/simple-buy-auth:v1.0.0 --push .
   docker buildx build --platform linux/amd64,linux/arm64 -f services/product/Dockerfile -t sayedimran/simple-buy-product:v1.0.0 --push .
   docker buildx build --platform linux/amd64,linux/arm64 -f services/cart/Dockerfile -t sayedimran/simple-buy-cart:v1.0.0 --push .
   docker buildx build --platform linux/amd64,linux/arm64 -f services/order/Dockerfile -t sayedimran/simple-buy-order:v1.0.0 --push .
   docker buildx build --platform linux/amd64,linux/arm64 -f services/notification/Dockerfile -t sayedimran/simple-buy-notification:v1.0.0 --push .
   docker buildx build --platform linux/amd64,linux/arm64 -f frontend/Dockerfile -t sayedimran/simple-buy-frontend:v1.0.0 --push frontend/
   ```

4. **Load images into your cluster** (for local development):
   
   > **Note**: If you pushed multi-arch images to Docker Hub, you can skip this step and Kubernetes will pull them automatically.
   
   ```bash
   # For Minikube
   minikube image load sayedimran/simple-buy-auth:v1.0.0
   minikube image load sayedimran/simple-buy-product:v1.0.0
   minikube image load sayedimran/simple-buy-cart:v1.0.0
   minikube image load sayedimran/simple-buy-order:v1.0.0
   minikube image load sayedimran/simple-buy-notification:v1.0.0
   minikube image load sayedimran/simple-buy-frontend:v1.0.0
   
   # For Kind
   kind load docker-image sayedimran/simple-buy-auth:v1.0.0
   kind load docker-image sayedimran/simple-buy-product:v1.0.0
   kind load docker-image sayedimran/simple-buy-cart:v1.0.0
   kind load docker-image sayedimran/simple-buy-order:v1.0.0
   kind load docker-image sayedimran/simple-buy-notification:v1.0.0
   kind load docker-image sayedimran/simple-buy-frontend:v1.0.0
   ```

## Quick Start

### Option 1: Using kubectl

```bash
# Deploy all resources
kubectl apply -f k8s/

# Check deployment status
kubectl get all -n simple-buy

# Wait for all pods to be ready
kubectl wait --for=condition=ready pod --all -n simple-buy --timeout=300s
```

### Option 2: Using Kustomize

```bash
# Deploy with kustomize
kubectl apply -k k8s/

# Check deployment status
kubectl get all -n simple-buy
```

## Accessing the Application

### Using LoadBalancer (Cloud Environments)

```bash
# Get the external IP
kubectl get svc nginx -n simple-buy

# Access the application
curl http://<EXTERNAL-IP>
```

### Using NodePort (Local Development)

If LoadBalancer is not available, change the nginx service type to NodePort:

```bash
kubectl patch svc nginx -n simple-buy -p '{"spec":{"type":"NodePort"}}'

# Get the NodePort
kubectl get svc nginx -n simple-buy

# Access via Minikube
minikube service nginx -n simple-buy
```

### Using Port-Forward

```bash
# Port-forward to nginx service
kubectl port-forward -n simple-buy svc/nginx 8080:80

# Access the application
open http://localhost:8080
```

### Using Ingress (Optional)

If you have an Ingress controller installed:

```bash
# Uncomment ingress.yaml in kustomization.yaml or apply directly
kubectl apply -f k8s/ingress.yaml

# Add to /etc/hosts
echo "127.0.0.1 simple-buy.local" | sudo tee -a /etc/hosts

# Access via domain
open http://simple-buy.local
```

## Manifest Files

| File | Description |
|------|-------------|
| `namespace.yaml` | Creates the `simple-buy` namespace |
| `configmap.yaml` | Application configuration |
| `secrets.yaml` | Sensitive credentials (change in production!) |
| `postgres-init-configmap.yaml` | Database initialization scripts |
| `postgres-pvc.yaml` | Persistent volume claim for PostgreSQL |
| `postgres-statefulset.yaml` | PostgreSQL database |
| `redis-statefulset.yaml` | Redis cache |
| `rabbitmq-statefulset.yaml` | RabbitMQ message broker |
| `auth-deployment.yaml` | Auth service deployment + service |
| `product-deployment.yaml` | Product service deployment + service |
| `cart-deployment.yaml` | Cart service deployment + service |
| `order-deployment.yaml` | Order service deployment + service |
| `notification-deployment.yaml` | Notification service deployment + service |
| `frontend-deployment.yaml` | Frontend deployment + service |
| `nginx-configmap.yaml` | Nginx configuration |
| `nginx-deployment.yaml` | Nginx API gateway deployment + service |
| `ingress.yaml` | Optional Ingress resource |
| `kustomization.yaml` | Kustomize configuration |

## Resource Scaling

### Scale Microservices

```bash
# Scale a specific service
kubectl scale deployment auth -n simple-buy --replicas=3

# Scale all services at once
kubectl scale deployment -n simple-buy --all --replicas=3
```

### Scale Infrastructure

```bash
# Scale Redis (requires StatefulSet modification)
kubectl scale statefulset redis -n simple-buy --replicas=3

# Scale RabbitMQ cluster
kubectl scale statefulset rabbitmq -n simple-buy --replicas=3
```

## Monitoring and Debugging

### Check Pod Status

```bash
# Get all pods
kubectl get pods -n simple-buy

# Get pod details
kubectl describe pod <pod-name> -n simple-buy

# View pod logs
kubectl logs <pod-name> -n simple-buy

# Follow logs
kubectl logs -f <pod-name> -n simple-buy

# View logs for a specific container in a pod
kubectl logs <pod-name> -n simple-buy -c <container-name>
```

### Check Service Connectivity

```bash
# Test internal service connectivity
kubectl run -it --rm debug --image=alpine --restart=Never -n simple-buy -- sh

# Inside the pod:
apk add curl postgresql-client redis
curl http://auth:8081/health
curl http://product:8082/health
psql -h postgres -U simplebuy -d auth_db
redis-cli -h redis ping
```

### Database Operations

```bash
# Connect to PostgreSQL
kubectl exec -it postgres-0 -n simple-buy -- psql -U simplebuy -d auth_db

# Run migrations (if needed)
kubectl exec -it <auth-pod> -n simple-buy -- /app/migrations/migrate.sh
```

### View Events

```bash
# Namespace events
kubectl get events -n simple-buy --sort-by='.lastTimestamp'
```

## Production Considerations

### 1. **Update Secrets**

⚠️ **CRITICAL**: Replace default secrets in `secrets.yaml` before deploying to production!

```bash
# Generate a secure JWT secret
JWT_SECRET=$(openssl rand -base64 32)

# Update the secret
kubectl create secret generic simple-buy-secrets \
  --from-literal=JWT_SECRET="$JWT_SECRET" \
  --from-literal=POSTGRES_PASSWORD="$(openssl rand -base64 20)" \
  --dry-run=client -o yaml | kubectl apply -n simple-buy -f -
```

### 2. **Configure StorageClass**

Update `storageClassName` in PVC and StatefulSet manifests to match your cluster's available storage classes:

```bash
# List available storage classes
kubectl get storageclass

# Update manifests with the appropriate storage class
```

### 3. **Resource Limits**

Adjust resource requests and limits based on your workload:

```yaml
resources:
  requests:
    memory: "256Mi"
    cpu: "200m"
  limits:
    memory: "1Gi"
    cpu: "1000m"
```

### 4. **High Availability**

- Run multiple replicas of each service (default: 2)
- Use Pod Disruption Budgets
- Configure Pod Anti-Affinity for better distribution

```bash
# Set minimum available pods
kubectl apply -f - <<EOF
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: auth-pdb
  namespace: simple-buy
spec:
  minAvailable: 1
  selector:
    matchLabels:
      app: auth
EOF
```

### 5. **Database Backups**

Set up regular PostgreSQL backups:

```bash
# Manual backup
kubectl exec postgres-0 -n simple-buy -- pg_dumpall -U simplebuy > backup.sql

# Restore
kubectl exec -i postgres-0 -n simple-buy -- psql -U simplebuy < backup.sql
```

### 6. **Monitoring and Observability**

Consider adding:
- Prometheus for metrics collection
- Grafana for visualization
- Jaeger/Zipkin for distributed tracing
- ELK/EFK stack for log aggregation

### 7. **TLS/SSL**

Enable HTTPS using cert-manager and Let's Encrypt:

```bash
# Install cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

# Configure Ingress with TLS
```

### 8. **Network Policies**

Implement network policies to restrict traffic between services:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: auth-network-policy
  namespace: simple-buy
spec:
  podSelector:
    matchLabels:
      app: auth
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: nginx
```

## Cleanup

```bash
# Delete all resources
kubectl delete namespace simple-buy

# Or if using kustomize
kubectl delete -k k8s/
```

## Troubleshooting

### Pods stuck in Pending

```bash
# Check if it's a resource issue
kubectl describe pod <pod-name> -n simple-buy

# Check if PVCs are bound
kubectl get pvc -n simple-buy
```

### CrashLoopBackOff

```bash
# Check logs
kubectl logs <pod-name> -n simple-buy --previous

# Check readiness/liveness probes
kubectl describe pod <pod-name> -n simple-buy
```

### ImagePullBackOff

```bash
# For local clusters, ensure images are loaded
minikube image ls | grep simple-buy
kind load docker-image simple-buy/*:latest

# Set imagePullPolicy to IfNotPresent in deployments
```

### Database Connection Issues

```bash
# Ensure postgres is ready
kubectl get pods -n simple-buy | grep postgres

# Check if databases were created
kubectl exec -it postgres-0 -n simple-buy -- psql -U simplebuy -c "\l"
```

## Development Workflow

### Local Development with Skaffold (Optional)

Create a `skaffold.yaml` for continuous development:

```yaml
apiVersion: skaffold/v4beta6
kind: Config
build:
  artifacts:
  - image: simple-buy/auth
    context: .
    docker:
      dockerfile: services/auth/Dockerfile
deploy:
  kubectl:
    manifests:
    - k8s/*.yaml
```

Run:
```bash
skaffold dev
```

### Hot Reload with Tilt (Optional)

Create a `Tiltfile` for enhanced development experience with live updates.

## Support

For issues or questions, refer to the main [README.md](../README.md) in the project root.
