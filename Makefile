PKG = $(shell cat go.mod | grep "^module " | sed -e "s/module //g")
VERSION = $(shell cat internal/version/version)
COMMIT_SHA ?= $(shell git describe --always)-devel

GOOS ?= $(shell go env GOOS)
GOARCH ?= $(shell go env GOARCH)

build:
	goreleaser build --snapshot --rm-dist

up:
	ENV=dev APP_ROOT=./example APP_CONFIG__A=a APP_CONFIG__B=b go run ./cmd/webappserve

test:
	go test -v -race ./...

cover:
	go test -v -race -coverprofile=coverage.txt -covermode=atomic ./...

dep:
	go get -u ./...

install:
	go install ./cmd/webappserve

dockerx: build
	docker buildx build \
		--push \
		--platform linux/amd64,linux/arm64 \
		--tag querycap/webappserve:$(VERSION) \
		--file ./cmd/webappserve/Dockerfile \
		.