FROM golang:1.14-alpine as builder

COPY ./ /go/src/github.com/querycap/webappserve
WORKDIR /go/src/github.com/querycap/webappserve

ENV GOPROXY="https://goproxy.cn,direct"

RUN go build -o webappserve

FROM alpine

COPY --from=builder /go/src/github.com/querycap/webappserve/webappserve /bin/webappserve
COPY ./mime.types /etc/apache2/mime.types

WORKDIR /app
COPY ./index.html /app/index.html

ENV APP_ROOT=.
ENV APP_ENV=staging
ENV APP_CONFIG=""

EXPOSE 80

CMD ["webappserve"]