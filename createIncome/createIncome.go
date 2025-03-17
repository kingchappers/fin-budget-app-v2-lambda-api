package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"os"
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
	UserId         string    `json:"user_id"`
	Category       string    `json:"category"`
	Items          string    `json:"items"`
	IncomeId       string    `json:"income_id"`
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

func createIncomeItem(ctx context.Context, income Income) (*dynamodb.PutItemOutput, error) {
	// Access environment variables
	dynamodbTable := os.Getenv("INCOME_TABLE")
	if dynamodbTable == "" {
		log.Printf("INCOME_TABLE environment variable is not set")
		return nil, fmt.Errorf("missing required environment variable INCOME_TABLE")
	}

	//Convert income to input item struct
	incomeItem := map[string]types.AttributeValue{
		"income_date":     &types.AttributeValueMemberS{Value: income.IncomeDate.String()},
		"company":         &types.AttributeValueMemberS{Value: income.Company},
		"amount":          &types.AttributeValueMemberN{Value: fmt.Sprintf("%.2f", income.Amount)},
		"income_category": &types.AttributeValueMemberS{Value: income.IncomeCategory},
		"notes":           &types.AttributeValueMemberS{Value: income.Notes},
		"user_id":         &types.AttributeValueMemberS{Value: income.UserId},
		"category":        &types.AttributeValueMemberS{Value: income.Category},
		"items":           &types.AttributeValueMemberS{Value: income.Items},
		"income_id":       &types.AttributeValueMemberS{Value: income.IncomeId},
	}

	input := &dynamodb.PutItemInput{
		TableName: aws.String(dynamodbTable),
		Item:      incomeItem,
	}

	response, err := dynamodbClient.PutItem(ctx, input)

	if err != nil {
		log.Printf("Failed to add dynamoDB item: %v", err)
		log.Printf("putItem response: %v", response)
		return response, err
	}
	return response, nil
}

func handleRequest(ctx context.Context, event json.RawMessage) error {
	// Parse the input event
	var income Income
	if err := json.Unmarshal(event, &income); err != nil {
		log.Printf("Failed to unmarshal event: %v", err)
		return err
	}

	// Create income entry in the database using the helper method
	if response, err := createIncomeItem(ctx, income); err != nil {
		return err
	} else {
		log.Printf("Successfully added income %v", response)
	}

	return nil
}

func main() {
	lambda.Start(handleRequest)
}
