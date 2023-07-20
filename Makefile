# Install tools locally instead of in $HOME/go/bin.
export GOBIN := $(CURDIR)/bin
export PATH := $(GOBIN):$(PATH)

# Variables related to the linter.
GOLANGCI_LINT = $(GOBIN)/golangci-lint
GOLANGCI_LINT_VERSION = v1.53.3

.PHONY: all
all: compile-proto build check

# Build all programs present in the cmd/ directory.
.PHONY: build
build:
	go mod tidy
	go build ./cmd/...

# Run all the linters and static checkers.
.PHONY: check
check: $(GOLANGCI_LINT)
	$(GOLANGCI_LINT) run

# This function will install the linter in case it does not exist.
$(GOLANGCI_LINT):
	curl -sSfL \
		https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh \
		| sh -s -- -b $(GOBIN) $(GOLANGCI_LINT_VERSION)

# Generate gRPC code from the proto/*.proto files.
.PHONY: compile-proto
compile-proto: docker-build-compile-helper $(patsubst %.proto,%.pb.go,$(wildcard proto/*.proto))

# Build the Docker image used for creating the gRPC files.
.PHONY: docker-build-compile-helper
docker-build-compile-helper:
	docker build . -f Dockerfile \
		--target=compile-helper \
		-t grpc-proto-compile-helper

# This all the .proto files found in the target above, and compiles them.
%.pb.go: %.proto
	docker run -it --rm \
		-v $(PWD):/app -w /app \
		--user $(shell id -u):$(shell id -g) \
		grpc-proto-compile-helper \
		protoc --go_out=. --go_opt=paths=source_relative $< --go-grpc_out=. --go-grpc_opt=paths=source_relative $<

.PHONY: docker-build
docker-build: build
	docker build . -f Dockerfile \
		--target=grpc-minimal-server \
		-t grpc-minimal-server
