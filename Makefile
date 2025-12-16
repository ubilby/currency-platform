.PHONY: help up down logs ps restart clean db-init health test

# Output colors
GREEN  := \033[0;32m
YELLOW := \033[0;33m
NC     := \033[0m # No Color

help: ## Show manual
	@echo "$(GREEN)Currency Platform - Available Commands:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-15s$(NC) %s\n", $$1, $$2}'

up: ## Run all services
	@echo "$(GREEN)Starting Currency Platform...$(NC)"
	docker-compose -f docker/docker-compose.yml --env-file .env up -d
	@echo "$(GREEN)Services started! Check with 'make ps'$(NC)"

down: ## Stop all srvices
	@echo "$(YELLOW)Stopping services...$(NC)"
	docker-compose -f docker/docker-compose.yml --env-file .env down

logs: ## Show all logs of these services
	docker-compose -f docker/docker-compose.yml --env-file .env logs -f

logs-%: ## Show current service logs
	docker-compose -f docker/docker-compose.yml --env-file .env logs -f $*

ps: ## Show container status
	@echo "$(GREEN)Services Status:$(NC)"
	@docker-compose -f docker/docker-compose.yml --env-file .env ps

restart: down up ## Restart services

health: ## Show health
	@echo "$(GREEN)Checking services health...$(NC)"
	@docker ps --filter "name=currency_*" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

db-init: ## Reinitialize database (DELETE DATA!!!)
	@echo "$(YELLOW)WARNING: This will delete all data!$(NC)"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		$(MAKE) down; \
		docker volume rm currency_postgres_data || true; \
		$(MAKE) up; \
		echo "$(GREEN)Database reinitialized!$(NC)"; \
	fi

clean: ## Dleate all containers and volumes
	@echo "$(YELLOW)WARNING: This will delete ALL data and containers!$(NC)"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $REPLY =~ ^[Yy]$ ]]; then \
		docker-compose -f docker/docker-compose.yml --env-file .env down -v; \
		echo "$(GREEN)All cleaned up!$(NC)"; \
	fi

test: ## Run tests
	@echo "$(YELLOW)Tests will be implemented in Week 3$(NC)"

check-env: ## Check availbility .env file
	@if [ ! -f .env ]; then \
		echo "$(YELLOW).env file not found! Copying from .env.example...$(NC)"; \
		cp .env.example .env; \
		echo "$(GREEN)Please edit .env file with your settings$(NC)"; \
	fi