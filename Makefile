PKG = $(shell cat go.mod | grep "^module " | sed -e "s/module //g")
VERSION = v$(shell cat .version)
COMMIT_SHA ?= $(shell git describe --always)-devel

GOOS ?= $(shell go env GOOS)
GOARCH ?= $(shell go env GOARCH)
GOBUILD=CGO_ENABLED=0 go build -ldflags "-X ${PKG}/version.Version=${VERSION}+sha.${COMMIT_SHA}"

build:
	$(GOBUILD) .

start:
	docker run -p=80:80 querycap/webappserve:latest

test:
	go test -v -race ./...

cover:
	go test -v -race -coverprofile=coverage.txt -covermode=atomic ./...

install:
	go install -v

release:
	git push
	git push origin $(git describe --tags --abbrev=0)

dockerx:
	docker buildx build --build-arg=GOPROXY=${GOPROXY} --platform linux/amd64,linux/arm64 --push -t querycap/webappserve:${VERSION} .