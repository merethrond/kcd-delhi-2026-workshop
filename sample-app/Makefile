# Kubernetes Operations Makefile
.PHONY: help deploy delete status logs shell build-images load-images clean port-forward scale rollout

help: ## Show this help message
	@echo "Kubernetes Operations for Simple Buy"
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-20s %s\n", $$1, $$2}'

# Build Docker images
build-images: ## Build all Docker images
	@echo "Building Docker images..."
	docker build -f services/auth/Dockerfile -t sayedimran/simple-buy-auth:v1.0.0 .
	docker build -f services/product/Dockerfile -t sayedimran/simple-buy-product:v1.0.0 .
	docker build -f services/cart/Dockerfile -t sayedimran/simple-buy-cart:v1.0.0 .
	docker build -f services/order/Dockerfile -t sayedimran/simple-buy-order:v1.0.0 .
	docker build -f services/notification/Dockerfile -t sayedimran/simple-buy-notification:v1.0.0 .
	docker build -f frontend/Dockerfile -t sayedimran/simple-buy-frontend:v1.0.0 frontend/

# Build multi-arch Docker images
build-images-multiarch: ## Build and push multi-arch Docker images (AMD64 + ARM64)
	@echo "Building multi-arch Docker images..."
	docker buildx create --use --name multiarch-builder 2>/dev/null || docker buildx use multiarch-builder
	docker buildx build --platform linux/amd64,linux/arm64 -f services/auth/Dockerfile -t sayedimran/simple-buy-auth:v1.0.0 --push .
	docker buildx build --platform linux/amd64,linux/arm64 -f services/product/Dockerfile -t sayedimran/simple-buy-product:v1.0.0 --push .
	docker buildx build --platform linux/amd64,linux/arm64 -f services/cart/Dockerfile -t sayedimran/simple-buy-cart:v1.0.0 --push .
	docker buildx build --platform linux/amd64,linux/arm64 -f services/order/Dockerfile -t sayedimran/simple-buy-order:v1.0.0 --push .
	docker buildx build --platform linux/amd64,linux/arm64 -f services/notification/Dockerfile -t sayedimran/simple-buy-notification:v1.0.0 --push .
	docker buildx build --platform linux/amd64,linux/arm64 -f frontend/Dockerfile -t sayedimran/simple-buy-frontend:v1.0.0 --push frontend/

# Load images into Minikube
load-images-minikube: ## Load images into Minikube
	@echo "Loading images into Minikube..."
	minikube image load sayedimran/simple-buy-auth:v1.0.0
	minikube image load sayedimran/simple-buy-product:v1.0.0
	minikube image load sayedimran/simple-buy-cart:v1.0.0
	minikube image load sayedimran/simple-buy-order:v1.0.0
	minikube image load sayedimran/simple-buy-notification:v1.0.0
	minikube image load sayedimran/simple-buy-frontend:v1.0.0

# Load images into Kind
load-images-kind: ## Load images into Kind
	@echo "Loading images into Kind..."
	kind load docker-image sayedimran/simple-buy-auth:v1.0.0
	kind load docker-image sayedimran/simple-buy-product:v1.0.0
	kind load docker-image sayedimran/simple-buy-cart:v1.0.0
	kind load docker-image sayedimran/simple-buy-order:v1.0.0
	kind load docker-image sayedimran/simple-buy-notification:v1.0.0
	kind load docker-image sayedimran/simple-buy-frontend:v1.0.0

# Deploy using kubectl
deploy: ## Deploy all resources to Kubernetes
	@echo "Deploying to Kubernetes..."
	kubectl apply -f k8s/
	@echo "Waiting for deployments to be ready..."
	kubectl wait --for=condition=ready pod --all -n simple-buy --timeout=300s || true

# Deploy using kustomize
deploy-kustomize: ## Deploy using kustomize
	@echo "Deploying with kustomize..."
	kubectl apply -k k8s/
	@echo "Waiting for deployments to be ready..."
	kubectl wait --for=condition=ready pod --all -n simple-buy --timeout=300s || true

# Deploy with HPA
deploy-with-hpa: deploy ## Deploy with Horizontal Pod Autoscalers
	@echo "Applying HPA configurations..."
	kubectl apply -f k8s/hpa.yaml

# Delete all resources
delete: ## Delete all Kubernetes resources
	@echo "Deleting all resources..."
	kubectl delete namespace simple-buy || true

# Clean and redeploy
clean-deploy: delete deploy ## Clean delete and redeploy everything

# Check status
status: ## Check status of all resources
	@echo "=== Namespace ==="
	kubectl get namespace simple-buy || echo "Namespace not found"
	@echo ""
	@echo "=== Pods ==="
	kubectl get pods -n simple-buy
	@echo ""
	@echo "=== Services ==="
	kubectl get svc -n simple-buy
	@echo ""
	@echo "=== Deployments ==="
	kubectl get deployments -n simple-buy
	@echo ""
	@echo "=== StatefulSets ==="
	kubectl get statefulsets -n simple-buy
	@echo ""
	@echo "=== PVCs ==="
	kubectl get pvc -n simple-buy

# View logs
logs-auth: ## View logs for auth service
	kubectl logs -n simple-buy -l app=auth --tail=100 -f

logs-product: ## View logs for product service
	kubectl logs -n simple-buy -l app=product --tail=100 -f

logs-cart: ## View logs for cart service
	kubectl logs -n simple-buy -l app=cart --tail=100 -f

logs-order: ## View logs for order service
	kubectl logs -n simple-buy -l app=order --tail=100 -f

logs-notification: ## View logs for notification service
	kubectl logs -n simple-buy -l app=notification --tail=100 -f

logs-frontend: ## View logs for frontend
	kubectl logs -n simple-buy -l app=frontend --tail=100 -f

logs-nginx: ## View logs for nginx
	kubectl logs -n simple-buy -l app=nginx --tail=100 -f

logs-postgres: ## View logs for PostgreSQL
	kubectl logs -n simple-buy postgres-0 --tail=100 -f

logs-redis: ## View logs for Redis
	kubectl logs -n simple-buy redis-0 --tail=100 -f

logs-rabbitmq: ## View logs for RabbitMQ
	kubectl logs -n simple-buy rabbitmq-0 --tail=100 -f

# Shell into pods
shell-auth: ## Shell into auth pod
	kubectl exec -it -n simple-buy $$(kubectl get pod -n simple-buy -l app=auth -o jsonpath='{.items[0].metadata.name}') -- sh

shell-postgres: ## Shell into PostgreSQL pod
	kubectl exec -it -n simple-buy postgres-0 -- psql -U simplebuy -d auth_db

shell-redis: ## Shell into Redis pod
	kubectl exec -it -n simple-buy redis-0 -- redis-cli

# Port forwarding
port-forward-nginx: ## Port forward nginx to localhost:8080
	@echo "Forwarding nginx to localhost:8080..."
	kubectl port-forward -n simple-buy svc/nginx 8080:80

port-forward-auth: ## Port forward auth service to localhost:8081
	@echo "Forwarding auth to localhost:8081..."
	kubectl port-forward -n simple-buy svc/auth 8081:8081

port-forward-rabbitmq: ## Port forward RabbitMQ management to localhost:15672
	@echo "Forwarding RabbitMQ management to localhost:15672..."
	kubectl port-forward -n simple-buy rabbitmq-0 15672:15672

port-forward-postgres: ## Port forward PostgreSQL to localhost:5432
	@echo "Forwarding PostgreSQL to localhost:5432..."
	kubectl port-forward -n simple-buy postgres-0 5432:5432

# Scale deployments
scale-up: ## Scale all deployments to 3 replicas
	@echo "Scaling deployments to 3 replicas..."
	kubectl scale deployment -n simple-buy --all --replicas=3

scale-down: ## Scale all deployments to 1 replica
	@echo "Scaling deployments to 1 replica..."
	kubectl scale deployment -n simple-buy --all --replicas=1

# Restart deployments
restart-all: ## Restart all deployments
	@echo "Restarting all deployments..."
	kubectl rollout restart deployment -n simple-buy --all

restart-auth: ## Restart auth deployment
	kubectl rollout restart deployment auth -n simple-buy

restart-product: ## Restart product deployment
	kubectl rollout restart deployment product -n simple-buy

restart-cart: ## Restart cart deployment
	kubectl rollout restart deployment cart -n simple-buy

restart-order: ## Restart order deployment
	kubectl rollout restart deployment order -n simple-buy

restart-notification: ## Restart notification deployment
	kubectl rollout restart deployment notification -n simple-buy

restart-frontend: ## Restart frontend deployment
	kubectl rollout restart deployment frontend -n simple-buy

restart-nginx: ## Restart nginx deployment
	kubectl rollout restart deployment nginx -n simple-buy

# Rollout status
rollout-status: ## Check rollout status of all deployments
	@echo "Checking rollout status..."
	kubectl rollout status deployment -n simple-buy --watch=false

# Events
events: ## View recent events
	kubectl get events -n simple-buy --sort-by='.lastTimestamp'

# Describe resources
describe-pods: ## Describe all pods
	kubectl describe pods -n simple-buy

describe-svc: ## Describe all services
	kubectl describe svc -n simple-buy

# Database operations
db-migrate-auth: ## Run auth service migrations
	kubectl exec -it -n simple-buy $$(kubectl get pod -n simple-buy -l app=auth -o jsonpath='{.items[0].metadata.name}') -- /app/migrate -path /app/migrations -database "$$DATABASE_URL" up

db-reset-auth: ## Reset auth database (WARNING: destructive)
	kubectl exec -it -n simple-buy postgres-0 -- psql -U simplebuy -d auth_db -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"

# Backup and restore
backup-postgres: ## Backup PostgreSQL databases
	@echo "Backing up PostgreSQL..."
	kubectl exec -n simple-buy postgres-0 -- pg_dumpall -U simplebuy > backup-$$(date +%Y%m%d-%H%M%S).sql
	@echo "Backup completed: backup-$$(date +%Y%m%d-%H%M%S).sql"

restore-postgres: ## Restore PostgreSQL from backup (provide BACKUP_FILE=path)
	@if [ -z "$(BACKUP_FILE)" ]; then echo "Please provide BACKUP_FILE=path"; exit 1; fi
	@echo "Restoring PostgreSQL from $(BACKUP_FILE)..."
	kubectl exec -i -n simple-buy postgres-0 -- psql -U simplebuy < $(BACKUP_FILE)

# Debug
debug: ## Run a debug pod
	kubectl run -it --rm debug --image=alpine --restart=Never -n simple-buy -- sh

# Test connectivity
test-connectivity: ## Test internal service connectivity
	@echo "Testing connectivity..."
	kubectl run -it --rm test --image=curlimages/curl --restart=Never -n simple-buy -- sh -c "\
		curl -s http://auth:8081/health && echo 'Auth: OK' || echo 'Auth: FAIL'; \
		curl -s http://product:8082/health && echo 'Product: OK' || echo 'Product: FAIL'; \
		curl -s http://cart:8083/health && echo 'Cart: OK' || echo 'Cart: FAIL'; \
		curl -s http://order:8084/health && echo 'Order: OK' || echo 'Order: FAIL'; \
		curl -s http://notification:8085/health && echo 'Notification: OK' || echo 'Notification: FAIL'; \
	"

# Complete workflow for local development
dev-minikube: build-images load-images-minikube deploy port-forward-nginx ## Complete dev setup for Minikube

dev-kind: build-images load-images-kind deploy port-forward-nginx ## Complete dev setup for Kind

# Production deployment helpers
prod-check: ## Check production readiness
	@echo "Checking production readiness..."
	@echo "1. Checking secrets..."
	@kubectl get secret simple-buy-secrets -n simple-buy -o jsonpath='{.data.JWT_SECRET}' | base64 -d | grep -q "super-secret-dev-key" && echo "  WARNING: Using default JWT secret!" || echo "  ✓ JWT secret is customized"
	@echo "2. Checking resource limits..."
	@kubectl get pods -n simple-buy -o json | jq -r '.items[] | select(.spec.containers[].resources.limits == null) | .metadata.name' | grep -q . && echo "  WARNING: Some pods missing resource limits" || echo "  ✓ All pods have resource limits"
	@echo "3. Checking replicas..."
	@kubectl get deployments -n simple-buy -o json | jq -r '.items[] | select(.spec.replicas < 2) | .metadata.name' | grep -q . && echo "  WARNING: Some deployments have < 2 replicas" || echo "  ✓ All deployments have 2+ replicas"
