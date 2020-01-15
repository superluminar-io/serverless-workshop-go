package main

import (
	"context"
	"os"

	"github.com/aws/aws-xray-sdk-go/xray"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/dynamodb"
	"github.com/aws/aws-sdk-go/service/dynamodb/dynamodbiface"
	log "github.com/sirupsen/logrus"
)

type HandlerConfig struct {
	DynamoDBTable  string
	DynamoDBClient dynamodbiface.DynamoDBAPI
}

func (hc *HandlerConfig) handler(ctx context.Context, request events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	s := request.PathParameters["short_id"]
	log.WithField("short_id", s).Info("Got short URL")

	result, err := hc.DynamoDBClient.GetItemWithContext(ctx, &dynamodb.GetItemInput{
		TableName: aws.String(hc.DynamoDBTable),
		Key: map[string]*dynamodb.AttributeValue{
			"short_id": {S: aws.String(s)},
		},
	})
	if err != nil {
		log.WithField("error", err).Info("Couldn't get data from DynamoDB")
		return events.APIGatewayProxyResponse{StatusCode: 500, Body: err.Error()}, nil
	}
	if result.Item == nil {
		return events.APIGatewayProxyResponse{StatusCode: 404, Body: "nix"}, nil
	}
	loc := result.Item["url"]
	return events.APIGatewayProxyResponse{StatusCode: 302, Headers: map[string]string{"Location": *loc.S}}, nil
}

func main() {
	sess := session.Must(session.NewSession())
	dbClient := dynamodb.New(sess)
	xray.AWS(dbClient.Client)

	hc := &HandlerConfig{
		DynamoDBTable:  os.Getenv("TABLE_NAME"),
		DynamoDBClient: dbClient,
	}
	lambda.Start(hc.handler)
}
