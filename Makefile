PATH_FUNCTIONS := ./functions/
LIST_FUNCTIONS := $(subst $(PATH_FUNCTIONS),,$(wildcard $(PATH_FUNCTIONS)*))

test:
	@for dir in `ls functions`; do \
		(cd functions/$$dir && go test); \
	done

.PHONY: build
build:
	@ $(MAKE) $(foreach FUNCTION,$(LIST_FUNCTIONS),build-$(FUNCTION))

.PHONY: build-%
build-%:
	@ make ./dist/functions/$*/handler SRC_FILES=functions/$*/*.go

./dist/functions/%/handler: $(SRC_FILES)
	@ GOOS=linux CGO_ENABLED=0 GOARCH=amd64 go build -installsuffix cgo -o $@ $(PATH_FUNCTIONS)/$*

deploy: build
	@ sam deploy

.PHONY: test deploy
