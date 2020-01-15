package main

import (
	"context"
	"fmt"
	"os"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/badoux/goscraper"
	"github.com/sirupsen/logrus"

	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/dynamodb"
)

type Response events.APIGatewayProxyResponse

func handler(ctx context.Context, event events.DynamoDBEvent) (Response, error) {
	dynamoDBTableName := os.Getenv("TABLE_NAME")
	sess := session.Must(session.NewSession())
	dbClient := dynamodb.New(sess)
	for _, r := range event.Records {
		logrus.Infof("%v", r.Change.NewImage)
		url, ok := r.Change.NewImage["url"]
		if !ok {
			return Response{StatusCode: 501}, fmt.Errorf("cant handle event: %v", event)
		}

		s, err := goscraper.Scrape(url.String(), 5)
		if err != nil {
			logrus.WithField("error", err).Errorf("failed to scrape '%s'", url)
			return Response{StatusCode: 501}, err
		}

		_, err = dbClient.PutItemWithContext(ctx, &dynamodb.PutItemInput{
			TableName: aws.String(dynamoDBTableName),
			Item: map[string]*dynamodb.AttributeValue{
				"url":   {S: aws.String(url.String())},
				"image": {S: aws.String(s.Preview.Images[0])},
				"name":  {S: aws.String(s.Preview.Name)},
				"title": {S: aws.String(s.Preview.Title)},
			}})

		if err != nil {
			logrus.WithField("error", err).Error("Couldn't save Preview")
			return Response{StatusCode: 501}, err
		}
	}

	resp := Response{
		StatusCode: 201,
		Body:       "s",
		Headers: map[string]string{
			"Content-Type": "text/plain",
		},
	}

	return resp, nil
}

func main() {
	lambda.Start(handler)
}
