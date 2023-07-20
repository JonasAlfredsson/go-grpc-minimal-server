FROM golang:1.20-bullseye AS compile-helper

# Install all components needed in order to successfully build the gRPC Go files.
RUN apt-get update && \
    apt-get install -y \
        protobuf-compiler=3.12.4* \
    && \
    go install google.golang.org/protobuf/cmd/protoc-gen-go@v1.28.1 && \
    go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@v1.2.0
