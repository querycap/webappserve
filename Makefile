PKG = $(shell cat go.mod | grep "^module " | sed -e "s/module //g")
VERSION = v$(shell cat .version)
COMMIT_SHA ?= $(shell git describe --always)-devel

GOOS ?= $(shell go env GOOS)
GOARCH ?= $(shell go env GOARCH)
GOBUILD=CGO_ENABLED=0 go build -buildmode=pie -ldflags "-X ${PKG}/version.Version=${VERSION}+sha.${COMMIT_SHA}"

build:
	$(GOBUILD) .

start:
	docker run -p=80:80 querycap/webappserve:latest

dockerx:
	docker buildx build --platform linux/amd64,linux/arm64 --push -t querycap/webappserve:${VERSION} .