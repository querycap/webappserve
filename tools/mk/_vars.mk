PKG = $(shell cat go.mod | grep "^module " | sed -e "s/module //g")

GIT_REF ?= HEAD
GIT_SHA ?= $(shell git rev-parse HEAD)
GIT_SHORT_SHA ?= $(shell echo $(GIT_SHA) | cut -c1-7)

ifeq (/tags/,$(findstring /tags/,$(GIT_REF)))
  	VERSION = $(shell echo "$(GIT_REF)" | sed -e "s/refs\/tags\/v//")
endif

TARGET_EXEC ?= webappserve
TARGET_ARCH ?= $(shell go env GOARCH)
