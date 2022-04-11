FROM --platform=$BUILDPLATFORM golang:1.18-buster AS builder

WORKDIR /go/src
COPY ./ ./

ARG TARGET_EXEC
ARG TARGET_ARCH
RUN make build TARGET_EXEC="${TARGET_EXEC}" TARGET_ARCH="${TARGET_ARCH}"

FROM gcr.io/distroless/static-debian10:latest

COPY --from=builder /go/src/cmd/webappserve/etc/mime.types /etc/apache2/mime.types

ARG TARGETARCH
COPY --from=builder /go/src/bin/webappserve-linux-${TARGETARCH} /webappserve

COPY ./example/index.html /app/index.html

ENV APP_CONFIG=""
ENV APP_ROOT=/app
ENV ENV=staging

ENTRYPOINT ["/webappserve"]


