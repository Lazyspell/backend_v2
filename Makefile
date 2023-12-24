SHELL_PATH = /bin/zsh

run-local:
	go run app/services/profile-api/main.go
tidy: 
	go mod tidy
	go mod vendor
