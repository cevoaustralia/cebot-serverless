PKG = chatbot.zip
ZIP := zip
ZIP_ARGS := -9rq

STACK := chatbot
BUCKET := grogan-splorgin

all: test

$(PKG): 
	rm -f $(PKG)
	cd python && \
		pip install --quiet -r requirements.txt -t . && \
		$(ZIP) $(ZIP_ARGS) ../$(PKG) .

publish: $(PKG)
	$(eval ETAG=$(shell aws s3api head-object --bucket $(BUCKET) --key $(PKG) --query ETag --output text | sed -e 's/"//g' ))
	$(eval MD5=$(shell md5sum $(PKG) | awk '{ print $$1 }' ))
	if [ "x$(ETAG)" = "x$(MD5)" ]; then \
		echo "No changes to the code, not updating"; \
	else \
		aws s3 cp $(PKG) s3://$(BUCKET)/; \
	fi
	$(eval VERSION=$(shell aws s3api head-object --bucket $(BUCKET) --key $(PKG) --query VersionId --output text ))

stack: publish
	if aws cloudformation describe-stacks --stack-name $(STACK) >/dev/null 2>&1; then \
		aws cloudformation update-stack \
			--capabilities CAPABILITY_IAM \
			--stack-name chatbot \
			--parameters ParameterKey=CodeVersion,ParameterValue=$(VERSION) \
			--template-body file://cloudformation/chatbot.yml || exit 0 && \
		aws cloudformation wait stack-update-complete --stack-name $(STACK); \
	else \
		aws cloudformation create-stack \
			--capabilities CAPABILITY_IAM \
			--stack-name $(STACK) \
			--parameters ParameterKey=CodeVersion,ParameterValue=$(VERSION) \
			--template-body file://cloudformation/chatbot.yml && \
		aws cloudformation wait stack-create-complete \
			--stack-name $(STACK); \
	fi

test: stack
	cd tests && ./run_tests $(STACK)

.PHONY: $(PKG)
