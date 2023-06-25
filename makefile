run: 
	go run app/services/profile_api/main.go
	
tidy:
	go mod tidy 
	go mod vendor
