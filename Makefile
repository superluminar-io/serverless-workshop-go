PATH_FUNCTIONS := ./functions/
LIST_FUNCTIONS := $(subst $(PATH_FUNCTIONS),,$(wildcard $(PATH_FUNCTIONS)*))

test:
	@for dir in `ls functions`; do \
		(cd functions/$$dir && go test); \
	done

.PHONY: build
build:
	@for dir in `ls functions`; do \
		(cd functions/$$dir && GOOS=linux CGO_ENABLED=0 GOARCH=amd64 go build -installsuffix cgo -o ../../dist/functions/$$dir/handler .); \
	done

deploy: build
	@ sam deploy

.PHONY: test deploy
