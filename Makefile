build:
	$(MAKE) go.xbuild TARGET_OS=linux TARGET_ARCH="$(TARGET_ARCH)"

install:
	$(GO_INSTALL)

serve:
	$(GO_RUN) --root ./example

include tools/mk/*.mk