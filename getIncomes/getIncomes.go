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
	"github.com/aws/aws-sdk-go-v2/feature/dynamodb/attributevalue"
	"github.com/aws/aws-sdk-go-v2/feature/dynamodb/expression"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb"
	"github.com/awslabs/aws-lambda-go-api-proxy/httpadapter"
)

var (
	dynamodbClient *dynamodb.Client
)

type GetIncomeParams struct {
	UserId string `json:"UserId"`
}

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

func getIncomeItems(ctx context.Context, getIncomeParams GetIncomeParams) (*dynamodb.QueryOutput, []Income, error) {
	var err error
	var response *dynamodb.QueryOutput
	var incomes []Income

	// Access environment variables
	dynamodbTable := os.Getenv("INCOME_TABLE")
	if dynamodbTable == "" {
		log.Printf("INCOME_TABLE environment variable is not set")
		return response, nil, fmt.Errorf("missing required environment variable INCOME_TABLE")
	}

	// Create date range for the last 5 years
	endDate := time.Now().Format("2006-01-02")                     // YYYY-MM-DD
	startDate := time.Now().AddDate(-5, 0, 0).Format("2006-01-02") // YYYY-MM-DD

	// Build the query expression
	queryKey := expression.Key("UserId").Equal(expression.Value(getIncomeParams.UserId))
	queryFilter := expression.Name("IncomeDate").Between(expression.Value(startDate), expression.Value(endDate))

	expr, err := expression.NewBuilder().WithKeyCondition(queryKey).WithFilter(queryFilter).Build()

	if err != nil {
		log.Printf("Failed to build expression: %v", err)
		return response, incomes, err
	}

	log.Printf("Getting income items")
	// Create the DynamoDB query paginator
	queryPaginator := dynamodb.NewQueryPaginator(dynamodbClient, &dynamodb.QueryInput{
		TableName:                 aws.String(dynamodbTable),
		ExpressionAttributeNames:  expr.Names(),
		ExpressionAttributeValues: expr.Values(),
		KeyConditionExpression:    expr.KeyCondition(),
		FilterExpression:          expr.Filter(),
	})

	for queryPaginator.HasMorePages() {
		response, err = queryPaginator.NextPage(ctx)
		if err != nil {
			log.Printf("Failed to get query page: %v", err)
			log.Printf("putItem response: %v", response)
			return response, incomes, err
		} else {
			var incomePage []Income
			err = attributevalue.UnmarshalListOfMaps(response.Items, &incomePage)
			if err != nil {
				log.Printf("Failed to unmarshal query items: %v", err)
				return response, incomes, err
			}
			incomes = append(incomes, incomePage...)
		}
	}

	if err != nil {
		log.Printf("Failed to add dynamoDB item: %v", err)
		log.Printf("putItem response: %v", response)
		return response, incomes, err
	}
	return response, incomes, nil
}

func main() {
	http.HandleFunc("/income", func(w http.ResponseWriter, r *http.Request) {
		// Enable CORS
		w.Header().Set("Access-Control-Allow-Origin", "https://finbudget.co.uk")
		w.Header().Set("Access-Control-Allow-Methods", "OPTIONS,GET")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token")
		w.Header().Set("Access-Control-Allow-Credentials", "true")

		// Handle preflight OPTIONS request
		if r.Method == http.MethodOptions {
			w.WriteHeader(http.StatusOK)
			return
		}

		// Only allow GET method
		if r.Method != http.MethodGet {
			http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
			return
		}

		// var incomes []Income
		var getIncomeParams GetIncomeParams
		// if err := json.NewDecoder(r.Body).Decode(&getIncomeParams); err != nil {
		// 	http.Error(w, fmt.Sprintf("Failed to decode request body: %v", err), http.StatusBadRequest)
		// 	return
		// }

		// getIncomeParams.UserId = r.Header.Get("UserId")
		getIncomeParams.UserId = r.URL.Query().Get("UserId")
		if getIncomeParams.UserId == "" {
			http.Error(w, "Missing UserId header", http.StatusBadRequest)
			return
		}

		ctx := r.Context()
		_, incomes, err := getIncomeItems(ctx, getIncomeParams)
		if err != nil {
			http.Error(w, fmt.Sprintf("Failed to create income: %v", err), http.StatusInternalServerError)
			return
		}

		//Set response headers
		w.Header().Set("Content-Type", "application/json")

		// Encode and send the incomes in the response
		if err := json.NewEncoder(w).Encode(incomes); err != nil {
			http.Error(w, fmt.Sprintf("Failed to encode response: %v", err), http.StatusInternalServerError)
			return
		}

		// Handle preflight OPTIONS request
		if r.Method == http.MethodOptions {
			w.WriteHeader(http.StatusOK)
			return
		}

		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusCreated)
		json.NewEncoder(w).Encode(map[string]string{"status": "success"})
	})

	lambda.Start(httpadapter.New(http.DefaultServeMux).ProxyWithContext)
}
