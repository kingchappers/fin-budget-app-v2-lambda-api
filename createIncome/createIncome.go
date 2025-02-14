package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"strings"
	"time"

	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb/types"
)

type Income struct {
	IncomeDate     time.Time `json:"income_date"`
	Company        string    `json:"company"`
	Amount         float64   `json:"amount"`
	IncomeCategory string    `json:"income_category"`
	Notes          string    `json:"notes"`
	UserID         string    `json:"user_id"`
	Category       string    `json:"category"`
	Items          string    `json:"items"`
	TransactionId  string    `json:"transaction_id"`
}

var (
	dynamodbClient *dynamodb.Client
)

func init() {
	// Initialize the S3 client outside of the handler, during the init phase
	cfg, err := config.LoadDefaultConfig(context.TODO(),
		config.WithRegion("eu-west-2"),
	)
	if err != nil {
		log.Fatalf("unable to load SDK config, %v", err)
	}

	dynamodbClient = dynamodb.NewFromConfig(cfg)
}

func createIncomeItem(ctx context.Context, income Income) error {
	// Access environment variables
	dynamodbTable := os.Getenv("INCOME_TABLE")
	if dynamodbTable == "" {
		log.Printf("INCOME_TABLE environment variable is not set")
		return fmt.Errorf("missing required environment variable INCOME_TABLE")
	}

	incomeItem := map[string]types.AttributeValue{
		"income_date":     &types.AttributeValueMemberS{Value: income.IncomeDate.String()},
		"company":         &types.AttributeValueMemberS{Value: income.Company},
		"amount":          &types.AttributeValueMemberN{Value: fmt.Sprintf("%.2f", income.Amount)},
		"income_category": &types.AttributeValueMemberS{Value: income.IncomeCategory},
		"notes":           &types.AttributeValueMemberS{Value: income.Notes},
		"user_id":         &types.AttributeValueMemberS{Value: income.UserID},
		"category":        &types.AttributeValueMemberS{Value: income.Category},
		"items":           &types.AttributeValueMemberS{Value: income.Items},
		"transaction_id":  &types.AttributeValueMemberS{Value: income.TransactionId},
	}

	input := &dynamodb.PutItemInput{
		TableName: aws.String(dynamodbTable),
		Item:      incomeItem,
	}

	response, err := dynamodbClient.PutItem(ctx, input)

	if err != nil {
		log.Printf("Failed to add dynamoDB item: %v", err)
		log.Printf("putItem response: %v", response)
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

	// Create the receipt content and key destination
	receiptContent := fmt.Sprintf("OrderID: %s\nAmount: $%.2f\nItem: %s",
		order.OrderID, order.Amount, order.Item)
	key := "receipts/" + order.OrderID + ".txt"

	// Upload the receipt to S3 using the helper method
	if err := createIncomeItem(ctx, dynamodbTable, income); err != nil {
		return err
	}

	log.Printf("Successfully processed order %s and stored receipt in S3 bucket %s", order.OrderID, dynamodbTable)
	return nil
}

func main() {
	lambda.Start(handleRequest)
}
