build:
	GOOS=linux go build -o webappserve
	docker build -t querycap/webappserve:latest .