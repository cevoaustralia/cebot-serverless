PKG = chatbot.zip
ZIP := zip
ZIP_ARGS := -9rv

BUCKET := grogan-splorgin

$(PKG): 
	rm -f $(PKG)
	cd python && \
		pip install -r requirements.txt -t . && \
		$(ZIP) $(ZIP_ARGS) ../$(PKG) .

publish: $(PKG)
	aws s3 cp $(PKG) s3://$(BUCKET)/

stack: publish
	aws cloudformation create-stack \
		--stack-name chatbot \
		--template-bod file://cloudformation/chatbot.yml

.PHONY: $(PKG)
