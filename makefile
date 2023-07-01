run: 
	go run app/services/profile_api/main.go | go run app/tooling/logfmt/main.go
	
run-help: 
	go run app/services/profile_api/main.go  --help
	
tidy:
	go mod tidy 
	go mod vendor


# ==============================================================================
# Building containers

# Example: $(shell git rev-parse --short HEAD)
VERSION := 1.0

all: profile 

profile:
	docker build \
		-f zarf/docker/dockerfile.profile-api \
		-t profile-api:$(VERSION) \
		--build-arg BUILD_REF=$(VERSION) \
		--build-arg BUILD_DATE=`date -u +"%Y-%m-%dT%H:%M:%SZ"` \
		.


# ==============================================================================
# Running from within k8s/kind
KIND_CLUSTER := jeremy-profile-cluster

dev-up:
	kind create cluster \
		--image kindest/node:v1.26.3@sha256:61b92f38dff6ccc29969e7aa154d34e38b89443af1a2c14e6cfbd2df6419c66f \
		--name $(KIND_CLUSTER) \
		--config zarf/k8s/dev/kind-config.yaml
	
	kubectl wait --timeout=120s --namespace=local-path-storage --for=condition=Available deployment/local-path-provisioner

dev-down:
	telepresence quit -s
	kind delete cluster --name $(KIND_CLUSTER)

dev-status:
	kubectl get nodes -o wide
	kubectl get svc -o wide
	kubectl get pods -o wide --watch --all-namespaces


dev-load:
	kind load docker-image profile-api:$(VERSION) --name $(KIND_CLUSTER)

dev-apply:
	kustomize build zarf/k8s/dev/profile | kubectl apply -f -
	kubectl wait --timeout=120s --namespace=profile-system --for=condition=Available deployment/profile

dev-restart:
	kubectl rollout restart deployment profile --namespace=profile-system

dev-logs:
	kubectl logs --namespace=profile-system -l app=profile --all-containers=true -f --tail=100 --max-log-requests=6 | go run app/tooling/logfmt/main.go -service=PROFILE-API 

dev-describe:
	kubectl describe nodes
	kubectl describe svc

dev-describe-deployment:
	kubectl describe deployment --namespace=profile-system profile 

dev-describe-profile:
	kubectl describe pod --namespace=profile-system -l app=profile


dev-update: all dev-load dev-restart

dev-update-apply: all dev-load dev-apply

