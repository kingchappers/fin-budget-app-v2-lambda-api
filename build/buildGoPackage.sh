cd ./createIncome
GOOS=linux GOARCH=arm64 go get "github.com/aws/aws-lambda-go/lambda"
GOOS=linux GOARCH=arm64 go get "github.com/aws/aws-sdk-go-v2/aws"
GOOS=linux GOARCH=arm64 go get "github.com/aws/aws-sdk-go-v2/config"
GOOS=linux GOARCH=arm64 go get "github.com/aws/aws-sdk-go-v2/service/dynamodb"
GOOS=linux GOARCH=arm64 go get "github.com/aws/aws-sdk-go-v2/service/dynamodb/types"
GOOS=linux GOARCH=arm64 go build -tags lambda.norpc -o bootstrap ./createIncome.go
zip createIncome.zip bootstrap