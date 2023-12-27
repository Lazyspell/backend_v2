SHELL_PATH = /bin/bash
# ==============================================================================
# Define dependencies

GOLANG          := golang:1.21.5
ALPINE          := alpine:3.19
KIND            := kindest/node:v1.27.1
POSTGRES        := postgres:16.1
VAULT           := hashicorp/vault:1.15
GRAFANA         := grafana/grafana:10.2.0
PROMETHEUS      := prom/prometheus:v2.48.0
TEMPO           := grafana/tempo:2.3.0
LOKI            := grafana/loki:2.9.0
PROMTAIL        := grafana/promtail:2.9.0
TELEPRESENCE 	:= datawire/tel2:2.13.1

KIND_CLUSTER    := profile-cluster
NAMESPACE       := profile-system
APP             := profile 
BASE_IMAGE_NAME := personal_project/profile
SERVICE_NAME    := profile-api
VERSION         := 0.0.1
SERVICE_IMAGE   := $(BASE_IMAGE_NAME)/$(SERVICE_NAME):$(VERSION)
METRICS_IMAGE   := $(BASE_IMAGE_NAME)/$(SERVICE_NAME)-metrics:$(VERSION)

# VERSION 		:= "0.0.1-$(shell git rev-parse --short HEAD)"

all: service

dev-bil:
	kind load docker-image $(TELEPRESENCE) --name $(KIND_CLUSTER)
	telepresence --context=kind-$(KIND_CLUSTER) helm install
	telepresence --context=kind-$(KIND_CLUSTER) connect
	
service:
		docker build \
				-f zarf/docker/dockerfile.profile \
				-t $(SERVICE_IMAGE) \
				--build-arg BUILD_REF=$(VERSION) \
				--build-arg BUILD_DATE=`date -u +"%Y-%m-%dT%H:%M:%SZ"` \
				.

dev-up-local:
	kind create cluster \
		--image $(KIND) \
		--name $(KIND_CLUSTER) \
		--config zarf/k8s/dev/kind-config.yaml

	kubectl wait --timeout=120s --namespace=local-path-storage --for=condition=Available deployment/local-path-provisioner
	kind load docker-image $(TELEPRESENCE) --name $(KIND_CLUSTER)

dev-up: dev-up-local
	telepresence --context=kind-$(KIND_CLUSTER) helm install
	telepresence --context=kind-$(KIND_CLUSTER) connect


dev-down-local:
	kind delete cluster --name $(KIND_CLUSTER)

dev-down:
	telepresence quit -s
	kind delete cluster --name $(KIND_CLUSTER)

dev-load:
	cd zarf/k8s/dev/profile; kustomize edit set image profile-image=$(SERVICE_IMAGE)
	kind load docker-image $(SERVICE_IMAGE) --name $(KIND_CLUSTER)
	
	# cd zarf/k8s/dev/profile; kustomize edit set image metrics-image=$(METRICS_IMAGE)
	# kind load docker-image $(METRICS_IMAGE) --name $(KIND_CLUSTER)

dev-apply:
	kustomize build zarf/k8s/dev/profile | kubectl apply -f -
	kubectl wait pods --namespace=$(NAMESPACE) --selector app=$(APP) --for=condition=Ready

dev-update: all dev-load dev-restart

dev-update-apply: all dev-load dev-apply


dev-restart:
	kubectl rollout restart deployment $(APP) --namespace=$(NAMESPACE)

dev-status:
	kubectl get nodes -o wide
	kubectl get svc -o wide
	kubectl get pods -o wide --watch --all-namespaces

dev-logs:
	kubectl logs --namespace=$(NAMESPACE) -l app=$(APP) --all-containers=true -f --tail=100 | go run app/tooling/logfmt/main.go -service=$(SERVICE_NAME) 

dev-describe-deployment:
	kubectl describe deployment --namespace=$(NAMESPACE) $(APP)

dev-describe-profile:
	kubectl describe pod deployment --namespace=$(NAMESPACE) -l app=$(APP)

run-local:
	go run app/services/profile-api/main.go | go run app/tooling/logfmt/main.go -service=$(SERVICE_NAME)
run-local-help:
	go run app/services/profile-api/main.go --help
tidy: 
	go mod tidy
	go mod vendor

metrics-view-local-sc:
	expvarmon -ports="localhost:4000" -vars="build,request,goroutines,errors,panic,mem:memstats.Alloc"


