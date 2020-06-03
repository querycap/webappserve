FROM golang:1.14-alpine as builder

ARG TARGETARCH

COPY ./ /go/src/github.com/querycap/webappserve
WORKDIR /go/src/github.com/querycap/webappserve

ENV GOPROXY="https://goproxy.cn,direct" UPX_VERSION=3.96

RUN wget https://github.com/upx/upx/releases/download/v${UPX_VERSION}/upx-${UPX_VERSION}-${TARGETARCH}_linux.tar.xz \
    && tar -xJf upx-${UPX_VERSION}-${TARGETARCH}_linux.tar.xz -C /tmp \
    && mv /tmp/upx-${UPX_VERSION}-${TARGETARCH}_linux/upx /usr/bin

RUN CGO_ENABLED=0 go build -o webappserve && upx --lzma webappserve

FROM alpine

COPY --from=builder /go/src/github.com/querycap/webappserve/webappserve /bin/webappserve
COPY ./mime.types /etc/apache2/mime.types

WORKDIR /app
COPY ./index.html /app/index.html

ENV APP_ROOT=.
ENV APP_CONFIG=""
ENV ENV=staging

EXPOSE 80

CMD ["webappserve"]