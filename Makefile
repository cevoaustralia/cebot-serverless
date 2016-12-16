PKG = chatbot.zip
ZIP := zip
ZIP_ARGS := -9r

BUCKET := grogan-splorgin

all: stack

$(PKG): 
	rm -f $(PKG)
	cd python && \
		pip install -r requirements.txt -t . && \
		$(ZIP) $(ZIP_ARGS) ../$(PKG) .

publish: $(PKG)
	aws s3 cp $(PKG) s3://$(BUCKET)/
	$(eval VERSION=$(shell aws s3api head-object --bucket $(BUCKET) --key $(PKG) --query VersionId --output text ))

stack: publish
	if aws cloudformation describe-stacks --stack-name chatbot >/dev/null 2>&1; then \
		aws cloudformation update-stack \
			--capabilities CAPABILITY_IAM \
			--stack-name chatbot \
			--parameters ParameterKey=CodeVersion,ParameterValue=$(VERSION) \
			--template-body file://cloudformation/chatbot.yml && \
		aws cloudformation wait stack-update-complete --stack-name chatbot; \
	else \
		aws cloudformation create-stack \
			--capabilities CAPABILITY_IAM \
			--stack-name chatbot \
			--parameters ParameterKey=CodeVersion,ParameterValue=$(VERSION) \
			--template-body file://cloudformation/chatbot.yml && \
		aws cloudformation wait stack-create-complete \
			--stack-name chatbot; \
	fi

.PHONY: $(PKG)
