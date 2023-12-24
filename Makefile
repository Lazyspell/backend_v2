SHELL_PATH = /bin/zsh
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

KIND_CLUSTER    := profile-cluster
NAMESPACE       := profile-system
APP             := profile 
BASE_IMAGE_NAME := personal_project/service
SERVICE_NAME    := profile-api
VERSION         := 0.0.1
SERVICE_IMAGE   := $(BASE_IMAGE_NAME)/$(SERVICE_NAME):$(VERSION)
METRICS_IMAGE   := $(BASE_IMAGE_NAME)/$(SERVICE_NAME)-metrics:$(VERSION)

# VERSION 		:= "0.0.1-$(shell git rev-parse --short HEAD)"

all: service

service:
	docker build \ 
		-f zarf/docker/dockerfile.service \
		-t $(SERVICE_NAME) \ 
		--build-arg BUILD_REF=$(VERSION) \ 
		--build-arg BUILD_DATE=`date -u "%Y-%m-%dT%H:%M:%SZ"`
		.
	

dev-up:
	kind create cluster \
		--image $(KIND) \
		--name $(KIND_CLUSTER) \
		--config zarf/k8s/dev/kind-config.yaml

	kubectl wait --timeout=120s --namespace=local-path-storage --for=condition=Available deployment/local-path-provisioner


dev-down:
	kind delete cluster --name $(KIND_CLUSTER)

dev-status:
	kubectl get nodes -o wide
	kubectl get svc -o wide
	kubectl get pods -o wide --watch --all-namespaces

run-local:
	go run app/services/profile-api/main.go
tidy: 
	go mod tidy
	go mod vendor


