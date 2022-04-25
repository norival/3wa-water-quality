# Executables (local)
DOCKER      = docker
DOCKER_COMP = docker-compose

# Docker containers
PHP_CONT = $(DOCKER_COMP) exec php

# Executables
PHP      = $(PHP_CONT) php
COMPOSER = $(PHP_CONT) composer
SYMFONY  = $(PHP_CONT) php bin/console

# Misc
.DEFAULT_GOAL = help
.PHONY        = help build up start down logs sh composer vendor sf cc reset init get_db_ip

## —— 🎵 🐳 The Symfony-docker Makefile 🐳 🎵 ——————————————————————————————————
help: ## Outputs this help screen
	@grep -E '(^[a-zA-Z0-9_-]+:.*?##.*$$)|(^##)' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}{printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}' | sed -e 's/\[32m##/[33m/'

## —— Docker 🐳 ————————————————————————————————————————————————————————————————
build: ## Builds the Docker images
	@$(DOCKER_COMP) build --pull --no-cache

up: ## Start the docker hub in detached mode (no logs)
	@$(DOCKER_COMP) up --detach --wait

start: build up ## Build and start the containers

down: ## Stop the docker hub
	@$(DOCKER_COMP) down --remove-orphans

logs: ## Show live logs
	@$(DOCKER_COMP) logs --tail=0 --follow

sh: ## Connect to the PHP FPM container
	@$(PHP_CONT) sh

## —— Composer 🧙 ——————————————————————————————————————————————————————————————
composer: ## Run composer, pass the parameter "c=" to run a given command, example: make composer c='req symfony/orm-pack'
	@$(eval c ?=)
	@$(COMPOSER) $(c)

vendor: ## Install vendors according to the current composer.lock file
vendor: c=install --prefer-dist --no-dev --no-progress --no-scripts --no-interaction
vendor: composer

## —— Symfony 🎵 ———————————————————————————————————————————————————————————————
sf: ## List all Symfony commands or pass the parameter "c=" to run a given command, example: make sf c=about
	@$(eval c ?=)
	@$(SYMFONY) $(c)

cc: c=c:c ## Clear the cache
cc: sf

## —— Salon 🧙 —————————————————————————————————————————————————————————————————

#| sed -e 's/.*"IPAddress": "\|",$$//g' | sed -e 's/^/
get_db_ip: ## Get database container IP
	@$(DOCKER) inspect salonv3-db | \
		grep -e '"IPAddress": "[0-9]' | \
		sed -e 's/^[ ]*//g' | \
		sed -e 's/,$$//g'

fixtures: ## Clear DB and reload fixtures
	@$(SYMFONY) hub:unregister-salon HUB_PROD_SECRET
	@$(SYMFONY) doctrine:fixtures:load --no-interaction --group=dev
	@$(SYMFONY) hub:register -u https://localhost HUB_PROD_SECRET
	@$(DOCKER_COMP) cp docker/assets/dev/upload php:/srv/app/public

reset: ## Reset or initialize project for development
	@$(SYMFONY) doctrine:schema:drop --force
	@$(SYMFONY) doctrine:schema:create
	@$(SYMFONY) doctrine:fixtures:load --group=dev --no-interaction
	@$(SYMFONY) hub:register -u https://localhost HUB_PROD_SECRET
	@$(SYMFONY) doctrine:migration:sync-metadata-storage
	@$(SYMFONY) doctrine:migration:version --no-interaction --add --all
	@$(DOCKER_COMP) cp docker/assets/dev/upload php:/srv/app/public

init: ## Initialize project for production
	@$(SYMFONY) doctrine:schema:drop --force
	@$(SYMFONY) doctrine:schema:create
	@$(SYMFONY) doctrine:fixtures:load --group=prod --no-interaction
	@$(SYMFONY) doctrine:migration:sync-metadata-storage
	@$(SYMFONY) doctrine:migration:version --no-interaction --add --all
	@$(DOCKER_COMP) cp docker/assets/prod/upload php:/srv/app/public
