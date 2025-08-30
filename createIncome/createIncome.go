package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb/types"
	"github.com/awslabs/aws-lambda-go-api-proxy/httpadapter"
)

type Income struct {
	IncomeDate     time.Time `json:"IncomeDate"`
	Company        string    `json:"Company"`
	Amount         float64   `json:"Amount"`
	IncomeCategory string    `json:"IncomeCategory"`
	Notes          string    `json:"Notes"`
	UserId         string    `json:"UserId"`
	Items          string    `json:"Items"`
	IncomeId       string    `json:"IncomeId"`
}

var (
	dynamodbClient *dynamodb.Client
)

func init() {
	// Initialize the dynamoDB client outside of the handler, during the init phase
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
		"IncomeDate":     &types.AttributeValueMemberS{Value: income.IncomeDate.String()},
		"Company":        &types.AttributeValueMemberS{Value: income.Company},
		"Amount":         &types.AttributeValueMemberN{Value: fmt.Sprintf("%.2f", income.Amount)},
		"IncomeCategory": &types.AttributeValueMemberS{Value: income.IncomeCategory},
		"Notes":          &types.AttributeValueMemberS{Value: income.Notes},
		"UserId":         &types.AttributeValueMemberS{Value: income.UserId},
		"Items":          &types.AttributeValueMemberS{Value: income.Items},
		"IncomeId":       &types.AttributeValueMemberS{Value: income.IncomeId},
	}

	log.Printf("Creating income item : %v", incomeItem)

	input := &dynamodb.PutItemInput{
		TableName: aws.String(dynamodbTable),
		Item:      incomeItem,
	}

	response, err := dynamodbClient.PutItem(ctx, input)
	log.Printf("putItem response: %v", response)

	if err != nil {
		log.Printf("Failed to add dynamoDB item: %v", err)
		log.Printf("putItem response: %v", response)
		return response, err
	}
	return response, nil
}

// func handleRequest(ctx context.Context, event json.RawMessage) error {
// 	// Parse the input event
// 	var income Income
// 	if err := json.Unmarshal(event, &income); err != nil {
// 		log.Printf("Failed to unmarshal event: %v", err)
// 		return err
// 	}

// 	// Create income entry in the database using the helper method
// 	if response, err := createIncomeItem(ctx, income); err != nil {
// 		return err
// 	} else {
// 		log.Printf("Successfully added income %v", response)
// 	}

// 	return nil
// }

func main() {
	http.HandleFunc("/income", func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodPost {
			http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
			return
		}

		var income Income
		if err := json.NewDecoder(r.Body).Decode(&income); err != nil {
			http.Error(w, fmt.Sprintf("Failed to decode request body: %v", err), http.StatusBadRequest)
			return
		}

		ctx := r.Context()
		_, err := createIncomeItem(ctx, income)
		if err != nil {
			http.Error(w, "Failed to create income", http.StatusInternalServerError)
			return
		}

		// Handle preflight OPTIONS request
        if r.Method == http.MethodOptions {
            w.WriteHeader(http.StatusOK)
            return
        }

		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusCreated)
		w.Header().Set("Access-Control-Allow-Origin", "'*'")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token")
		w.Header().Set("Access-Control-Allow-Methods", "OPTIONS,POST")
		w.Header().Set("Access-Control-Allow-Credentials", "true")
		json.NewEncoder(w).Encode(map[string]string{"status": "success"})
	})

	lambda.Start(httpadapter.New(http.DefaultServeMux).ProxyWithContext)
}
