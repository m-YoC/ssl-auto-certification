

###> !This is command set related to ssh certificates of domain

###> docker compose

up: ## Up container
	@docker compose up -d
down: ## Down container
	@docker compose down
build: ## Build container
	@docker compose build

###> @
.DEFAULT_GOAL := help
help: ## Display this help screen
	@sed -n 2p mfhelp.awk | cut -c 2- | xargs -i grep -E '{}' $(MAKEFILE_LIST) | awk -f mfhelp.awk
