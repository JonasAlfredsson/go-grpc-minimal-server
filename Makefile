# Install tools locally instead of in $HOME/go/bin.
export GOBIN := $(CURDIR)/bin
export PATH := $(GOBIN):$(PATH)

# Variables related to the linter.
GOLANGCI_LINT = $(GOBIN)/golangci-lint
GOLANGCI_LINT_VERSION = v1.53.3

.PHONY: all
all: build check

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
