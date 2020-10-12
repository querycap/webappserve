# syntax=docker/dockerfile:experimental

FROM golang:1.15-buster as builder

ARG TARGETARCH
ARG GOPROXY

COPY ./ /go/src
WORKDIR /go/src

RUN --mount=type=cache,id=gomod,target=/go/pkg/mod make build

FROM querycapdistroless/static-debian10:latest

COPY --from=builder /go/src/webappserve /bin/webappserve
COPY ./mime.types /etc/apache2/mime.types

WORKDIR /app
COPY ./index.html /app/index.html

ENV APP_ROOT=.
ENV APP_CONFIG=""
ENV ENV=staging

EXPOSE 80

ENTRYPOINT ["/bin/webappserve"]