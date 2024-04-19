.DEFAULT_GOAL := help

This-is: ## command set related to ssh certificates of [webmemo-test.net] 
	:
up: ## docker compose: up container
	@docker compose up -d
down: ## docker compose: down container
	@docker compose down
build: ## docker compose: build container
	@docker compose build
help: ## Display this help screen
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'