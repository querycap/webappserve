FROM gcr.io/distroless/static-debian10:latest

WORKDIR /app

ARG TARGETARCH
COPY ./bin/webappserve_linux_${TARGETARCH}/webappserve /bin/webappserve
COPY ./cmd/webappserve/etc/mime.types /etc/apache2/mime.types

COPY ./example/index.html /app/index.html

ENV APP_CONFIG=""
ENV APP_ROOT=/app
ENV ENV=staging

ENTRYPOINT ["/bin/webappserve"]