FROM golang:1.14-buster as builder

ARG TARGETARCH

COPY ./ /go/src/github.com/querycap/webappserve
WORKDIR /go/src/github.com/querycap/webappserve

ENV GOPROXY="https://goproxy.cn,direct"

RUN make build

FROM debian:buster-slim

COPY --from=builder /go/src/github.com/querycap/webappserve/webappserve /bin/webappserve
COPY ./mime.types /etc/apache2/mime.types

WORKDIR /app
COPY ./index.html /app/index.html

ENV APP_ROOT=.
ENV APP_CONFIG=""
ENV ENV=staging

EXPOSE 80

CMD ["webappserve"]