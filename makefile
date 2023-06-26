run: 
	go run app/services/profile_api/main.go
	
tidy:
	go mod tidy 
	go mod vendor


# ==============================================================================
# Building containers

# Example: $(shell git rev-parse --short HEAD)
VERSION := 1.0

all: profile metrics

profile:
	docker build \
		-f zarf/docker/dockerfile.profile-api \
		-t profile-api:$(VERSION) \
		--build-arg BUILD_REF=$(VERSION) \
		--build-arg BUILD_DATE=`date -u +"%Y-%m-%dT%H:%M:%SZ"` \
		.

