package main

import (
	"time"
	"context"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"strings"

	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb"
)

type Income struct {
	IncomeDate		time.Time 	`json:"income_date"`
	Company			string 		`json:"company"`
	Amount			float64  	`json:"amount"`
	IncomeCategory 	string 		`json:"income_category"`
	Notes			string 		`json:"notes"`	
	UserID 			string 		`json:"user_id"`
	Category 		string 		`json:"category"`
	Items 			string 		`json:"items"`
	TransactionId 	string 		`json:"transaction_id"`
}

var (
	dynamodbClient *dynamodb.Client
)

func init() {
	// Initialize the S3 client outside of the handler, during the init phase
	cfg, err := config.LoadDefaultConfig(context.TODO())
	if err != nil {
		log.Fatalf("unable to load SDK config, %v", err)
	}

	dynamodbClient = dynamodb.NewFromConfig(cfg)
}

func uploadReceiptToS3(ctx context.Context, bucketName, key, receiptContent string) error {
	_, err := s3Client.PutObject(ctx, &s3.PutObjectInput{
		Bucket: &bucketName,
		Key:    &key,
		Body:   strings.NewReader(receiptContent),
	})
	if err != nil {
		log.Printf("Failed to upload receipt to S3: %v", err)
		return err
	}
	return nil
}

func handleRequest(ctx context.Context, event json.RawMessage) error {
	// Parse the input event
	var income Income
	if err := json.Unmarshal(event, &income); err != nil {
		log.Printf("Failed to unmarshal event: %v", err)
		return err
	}

	// Access environment variables
	dynamodbTable := os.Getenv("INCOME_TABLE")
	if dynamodbTable == "" {
		log.Printf("INCOME_TABLE environment variable is not set")
		return fmt.Errorf("missing required environment variable INCOME_TABLE")
	}

	dynamodb.PutItemInput{
		TableName: &dynamodbTable,
		Item: {
			"incomeDate": {
				"S": params.data.transactionDate.toDateString(),
			},
		},
	}

	// Create the receipt content and key destination
	receiptContent := fmt.Sprintf("OrderID: %s\nAmount: $%.2f\nItem: %s",
		order.OrderID, order.Amount, order.Item)
	key := "receipts/" + order.OrderID + ".txt"

	// Upload the receipt to S3 using the helper method
	if err := uploadReceiptToS3(ctx, dynamodbTable, key, receiptContent); err != nil {
		return err
	}

	log.Printf("Successfully processed order %s and stored receipt in S3 bucket %s", order.OrderID, dynamodbTable)
	return nil
}

func main() {
	lambda.Start(handleRequest)
}
