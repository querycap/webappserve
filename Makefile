start: build
	docker run -p=80:80 querycap/webappserve:latest

build:
	docker buildx build --platform linux/amd64,linux/arm64 --push -t querycap/webappserve:latest .