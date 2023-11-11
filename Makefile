MAKEFLAGS += --silent
SHELL:=/bin/bash -o pipefail -o errexit
.ONESHELL:
.SHELLFLAGS:=-ec

BINARIES='docker' 'minikube' 'kubectl'
PLATFORM='linux/amd64'
USER=
SECRET=
IMAGE="farazf001/go-restarter"

.PHONY: requirements
requirements:
	for item in $(BINARIES) ; do \
		command -v $$item ; \
	done

.PHONY: help
help: ## Displays help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ Development

.PHONY: fmt
fmt: ## Formats the source code
	go fmt ./...

.PHONY: vet
vet: ## Validates the source code
	go vet ./...

.PHONY: build
build: requirements fmt vet ## Builds the image
	if [[ $$(uname -s) = "Darwin" ]];then \
		echo OSX ; \
		docker buildx build --platform $(PLATFORM) -t "${IMAGE}":$$(cat VERSION) . ; \
	else \
		echo Linux ; \
		docker build --platform $(PLATFORM) -t "${IMAGE}":$$(cat VERSION) . ; \
	fi
	docker tag "${IMAGE}":$$(cat VERSION) "${IMAGE}":latest

.PHONY: run
run: fmt vet ## Builds and runs the image
	$(MAKE) build
	docker run -it --rm "${IMAGE}":$$(cat VERSION)

.PHONY: artifact
artifact: ## Pushes the images to dockerhub
	docker login -u $(USER) -p $(SECRET)
	docker push "${IMAGE}":$$(cat VERSION)
	docker push "${IMAGE}":latest

.PHONY: clear
clear: ## Removes the images
	docker image rm "${IMAGE}":$$(cat VERSION)
	docker image rm "${IMAGE}":latest

.PHONY: changelog
changelog: ## Generate changelog
	if [[ $(shell command -v changelog) ]]; then \
		changelog ${NEW_VERSION} ${OLD_VERSION} . ; \
	else \
		echo 'download changelog binary and add it to your PATH (https://jfrog.devstack.vwgroup.com/artifactory/cbit-generic-snapshot)'; \
	fi

##@ Test

.PHONY: minikube
minikube: requirements ## Creates a minikube cluster
	minikube start --driver=docker

.PHONY: rm_minikube
rm_minikube: requirements ## Removes the minikube cluster
	minikube delete

.PHONY: test
test: ## Tests the restarter job
	kubectl apply -f openshift/stub.yaml
	kubectl rollout status deploy/stub
	kubectl apply -f openshift/restarter.yaml
	kubectl wait --for=condition=ContainersReady pod -l app.kubernetes.io/component=restarter
	kubectl logs -f job/cbit-restarter-job