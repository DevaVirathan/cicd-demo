# Makefile for CI/CD Demo

.PHONY: help setup install test lint format build run deploy clean docker-* local-ci

# Colors
GREEN := \033[32m
YELLOW := \033[33m
RED := \033[31m
RESET := \033[0m

# Default target
help: ## Show this help message
	@echo "$(GREEN)CI/CD Demo - Available Commands:$(RESET)"
	@echo ""
	@awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z_-]+:.*##/ { \
		printf "$(YELLOW)%-20s$(RESET) %s\n", $$1, $$2 \
	}' $(MAKEFILE_LIST)
	@echo ""
	@echo "$(GREEN)Examples:$(RESET)"
	@echo "  make setup     # Set up development environment"
	@echo "  make test      # Run full test suite"
	@echo "  make local-ci  # Run full CI pipeline locally"

# =============================================================================
# SETUP AND INSTALLATION
# =============================================================================

setup: ## Set up development environment
	@echo "$(GREEN)Setting up development environment...$(RESET)"
	chmod +x scripts/*.sh
	./scripts/setup.sh

install: ## Install dependencies
	@echo "$(GREEN)Installing dependencies...$(RESET)"
	pip install -r requirements-dev.txt

install-prod: ## Install production dependencies only
	@echo "$(GREEN)Installing production dependencies...$(RESET)"
	pip install -r requirements.txt

# =============================================================================
# DEVELOPMENT
# =============================================================================

run: ## Run the application locally
	@echo "$(GREEN)Starting application...$(RESET)"
	uvicorn app.main:app --reload --host 127.0.0.1 --port 3000

run-prod: ## Run the application in production mode
	@echo "$(GREEN)Starting application (production mode)...$(RESET)"
	uvicorn app.main:app --host 0.0.0.0 --port 3000 --workers 4

dev: ## Start development server with auto-reload
	@echo "$(GREEN)Starting development server...$(RESET)"
	uvicorn app.main:app --reload --host 127.0.0.1 --port 3000 --log-level debug

# =============================================================================
# TESTING AND QUALITY
# =============================================================================

test: ## Run all tests
	@echo "$(GREEN)Running tests...$(RESET)"
	./scripts/test.sh

test-unit: ## Run unit tests only
	@echo "$(GREEN)Running unit tests...$(RESET)"
	pytest tests/ -v -m "not integration"

test-integration: ## Run integration tests only
	@echo "$(GREEN)Running integration tests...$(RESET)"
	pytest tests/ -v -m "integration"

test-coverage: ## Run tests with detailed coverage report
	@echo "$(GREEN)Running tests with coverage...$(RESET)"
	pytest tests/ --cov=app --cov-report=html --cov-report=term

lint: ## Run linting checks
	@echo "$(GREEN)Running linting...$(RESET)"
	flake8 app/ tests/ --max-line-length=88 --extend-ignore=E203,W503
	isort --check-only app/ tests/

format: ## Format code
	@echo "$(GREEN)Formatting code...$(RESET)"
	black app/ tests/
	isort app/ tests/

format-check: ## Check if code is formatted correctly
	@echo "$(GREEN)Checking code formatting...$(RESET)"
	black --check app/ tests/
	isort --check-only app/ tests/

security: ## Run security checks
	@echo "$(GREEN)Running security checks...$(RESET)"
	safety check

# =============================================================================
# DOCKER OPERATIONS
# =============================================================================

build: ## Build Docker image
	@echo "$(GREEN)Building Docker image...$(RESET)"
	./scripts/build.sh

docker-run: ## Run application in Docker
	@echo "$(GREEN)Running application in Docker...$(RESET)"
	docker run -d --name cicd-demo -p 3000:3000 cicd-demo-app:latest

docker-stop: ## Stop Docker container
	@echo "$(GREEN)Stopping Docker container...$(RESET)"
	docker stop cicd-demo || true
	docker rm cicd-demo || true

docker-logs: ## Show Docker container logs
	@echo "$(GREEN)Showing container logs...$(RESET)"
	docker logs cicd-demo -f

docker-shell: ## Get shell access to running container
	@echo "$(GREEN)Accessing container shell...$(RESET)"
	docker exec -it cicd-demo /bin/bash

docker-clean: ## Clean up Docker images and containers
	@echo "$(GREEN)Cleaning up Docker resources...$(RESET)"
	docker stop cicd-demo || true
	docker rm cicd-demo || true
	docker rmi cicd-demo-app:latest || true

# =============================================================================
# DEPLOYMENT
# =============================================================================

deploy-local: ## Deploy to local environment
	@echo "$(GREEN)Deploying to local environment...$(RESET)"
	./scripts/deploy.sh --env local --port 3000

deploy-staging: ## Deploy to staging environment
	@echo "$(GREEN)Deploying to staging environment...$(RESET)"
	./scripts/deploy.sh --env staging --port 8001

deploy-production: ## Deploy to production environment
	@echo "$(GREEN)Deploying to production environment...$(RESET)"
	./scripts/deploy.sh --env production --port 8002

# =============================================================================
# CI/CD SIMULATION
# =============================================================================

local-ci: format-check lint test build ## Run complete CI pipeline locally
	@echo "$(GREEN)✅ Local CI pipeline completed successfully!$(RESET)"

pre-commit: format-check lint test ## Run pre-commit checks
	@echo "$(GREEN)✅ Pre-commit checks passed!$(RESET)"

pre-push: local-ci ## Run pre-push checks (full CI)
	@echo "$(GREEN)✅ Ready to push!$(RESET)"

simulate-pipeline: ## Simulate full CI/CD pipeline
	@echo "$(GREEN)🚀 Simulating full CI/CD pipeline...$(RESET)"
	@echo "$(YELLOW)Stage 1: Code Quality$(RESET)"
	make format-check
	make lint
	@echo "$(YELLOW)Stage 2: Testing$(RESET)"
	make test
	@echo "$(YELLOW)Stage 3: Security$(RESET)"
	make security || echo "$(RED)⚠️ Security warnings found$(RESET)"
	@echo "$(YELLOW)Stage 4: Build$(RESET)"
	make build
	@echo "$(YELLOW)Stage 5: Deploy to Staging$(RESET)"
	make deploy-staging
	@echo "$(YELLOW)Stage 6: Deploy to Production$(RESET)"
	make deploy-production
	@echo "$(GREEN)🎉 Full pipeline simulation completed!$(RESET)"

# =============================================================================
# UTILITIES
# =============================================================================

clean: ## Clean up generated files
	@echo "$(GREEN)Cleaning up...$(RESET)"
	find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	find . -name "*.pyc" -delete 2>/dev/null || true
	rm -rf htmlcov/ .coverage coverage.xml .pytest_cache/ || true
	rm -rf build/ dist/ *.egg-info/ || true

clean-all: clean docker-clean ## Clean everything including Docker
	@echo "$(GREEN)Deep cleaning completed!$(RESET)"

health-check: ## Check application health
	@echo "$(GREEN)Checking application health...$(RESET)"
	curl -f http://localhost:3000/health || echo "$(RED)❌ Health check failed$(RESET)"

logs: ## Show application logs (if running in Docker)
	@echo "$(GREEN)Showing application logs...$(RESET)"
	docker logs cicd-demo -f

status: ## Show system status
	@echo "$(GREEN)System Status:$(RESET)"
	@echo "Python: $$(python3 --version)"
	@echo "Docker: $$(docker --version)"
	@echo "Current branch: $$(git branch --show-current 2>/dev/null || echo 'Not in git repo')"
	@echo "Docker containers:"
	@docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep cicd || echo "No CI/CD containers running"

# =============================================================================
# GITHUB ACTIONS LOCAL TESTING (requires act)
# =============================================================================

act-install: ## Install act for local GitHub Actions testing
	@echo "$(GREEN)Installing act (GitHub Actions local runner)...$(RESET)"
	@if command -v act >/dev/null 2>&1; then \
		echo "$(GREEN)act is already installed$(RESET)"; \
	else \
		echo "$(YELLOW)Please install act manually from: https://github.com/nektos/act$(RESET)"; \
	fi

act-test: ## Run GitHub Actions workflow locally (requires act)
	@echo "$(GREEN)Running GitHub Actions locally...$(RESET)"
	act --job test

act-build: ## Run build job locally
	@echo "$(GREEN)Running build job locally...$(RESET)"
	act --job build

act-full: ## Run full workflow locally
	@echo "$(GREEN)Running full workflow locally...$(RESET)"
	act