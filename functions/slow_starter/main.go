package main

import (
	"encoding/json"
	"time"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	log "github.com/sirupsen/logrus"
)

func handler() (events.APIGatewayProxyResponse, error) {
	log.Info("finally started...")
	jsonBody, _ := json.Marshal(struct{ Status string }{Status: "OK"})
	return events.APIGatewayProxyResponse{StatusCode: 200, Body: string(jsonBody)}, nil
}

func main() {
	time.Sleep(time.Second * 2)
	lambda.Start(handler)
}
