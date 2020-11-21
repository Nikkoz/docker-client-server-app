#!/usr/bin/make

# Включаем .env
envfile = .env
include $(envfile)
export $(shell sed 's/=.*//' $(envfile))

ifeq "@docker" ""
	docker_message ?= "\n No docker installed"
	exit1
endif

ifeq "@docker-compose" ""
	docker_message += "\n No docker-compose installed"
	exit1
endif

ifndef VIRTUAL_HOST
	$(error The VIRTUAL_HOST variable is missing.)
endif

ifndef COMPOSE_PROJECT_NAME
	$(error The COMPOSE_PROJECT_NAME variable is missing.)
endif

exit1: ## exit
	@echo $(docker_message)
	@echo "\n exiting"
	kill 2

# Containers
SERVER := server
CLIENT := client
ANALYTICS := analytics
CLICKHOUSE := clickhouse
DB := mariadb
REDIS := redis
REDIS_COMMANDER := redis-commander
NGINX := nginx
PROXY := nginx-proxy

SERVER_CONTAINER_NAME := ${COMPOSE_PROJECT_NAME}_${SERVER}_1
CLIENT_CONTAINER_NAME := ${COMPOSE_PROJECT_NAME}_${CLIENT}_1
ANALYTICS_CONTAINER_NAME := ${COMPOSE_PROJECT_NAME}_${ANALYTICS}_1
CLICKHOUSE_CONTAINER_NAME := ${COMPOSE_PROJECT_NAME}_${CLICKHOUSE}_1

DC_BIN := $(shell command -v docker-compose 2> /dev/null)
CURRENT_USER = $(shell id -u):$(shell id -g)

RUN_APP_ARGS = -it --user "$(CURRENT_USER)"

COMPOSE_YML = \
			-f docker-compose.yml \
			-f docker/compose/docker-compose.server.yml \
			-f docker/compose/docker-compose.analytics.yml \
			-f docker/compose/docker-compose.client.yml \
			-f docker/compose/docker-compose.nginx.yml \
			-f docker/compose/docker-compose.redis.yml \
			-f docker/compose/docker-compose.mariadb.yml \
			-f docker/compose/docker-compose.clickhouse.yml

env:
	@echo -e "Make: Copying env file.\n"
	@cp ./.env.example ./.env
	@sed -i "s/CURRENT_USER=/CURRENT_USER=$$(id -u)/" .env

init: prepare-app prepare-db

prepare-db: migrate db-seed
	@echo -e "Make: DB prepared. \n"

prepare-app: composer-install key-generate #cert-generate
	@echo -e "Make: App is completed. \n"

clean:
	@docker system prune --volumes --force

up: memory
	@echo -e "Make: Up containers.\n"
	CURRENT_USER=$(CURRENT_USER) $(DC_BIN) ${COMPOSE_YML} -p $project_name up -d --force-recreate

down:
	@docker-compose ${COMPOSE_YML} -p $project_name down

start:
	@docker-compose ${COMPOSE_YML} -p $project_name start

logs:
	@docker-compose ${COMPOSE_YML} -p $project_name logs --follow

stop:
	@docker-compose ${COMPOSE_YML} -p $project_name stop

build: memory
	@docker-compose ${COMPOSE_YML} -p $project_name build --build-arg CURRENT_USER=$$(id -u) ${DB}
	@docker-compose ${COMPOSE_YML} -p $project_name build ${CLICKHOUSE}
	@docker-compose ${COMPOSE_YML} -p $project_name build ${REDIS}
	@docker-compose ${COMPOSE_YML} -p $project_name build ${REDIS_COMMANDER}
	@docker-compose ${COMPOSE_YML} -p $project_name build --build-arg CURRENT_USER=$$(id -u) ${ANALYTICS}
	@docker-compose ${COMPOSE_YML} -p $project_name build --build-arg CURRENT_USER=$$(id -u) ${SERVER}
	@docker-compose ${COMPOSE_YML} -p $project_name build --build-arg CURRENT_USER=$$(id -u) ${CLIENT}
	@docker-compose ${COMPOSE_YML} -p $project_name build ${NGINX}
	@docker-compose ${COMPOSE_YML} -p $project_name build ${PROXY}

migrate:
	@echo -e "Make: Database migration.\n"
	@docker-compose ${COMPOSE_YML} -p $project_name run ${SERVER} php artisan rinvex:migrate:attributes
	@docker-compose ${COMPOSE_YML} -p $project_name run ${SERVER} php artisan migrate --force

tinker:
	@docker-compose ${COMPOSE_YML} -p $project_name run ${SERVER} php artisan tinker

db-seed: dump-autoload
	@echo -e "Make: Database seeding.\n"
	@docker-compose ${COMPOSE_YML} -p $project_name run ${SERVER} php artisan db:seed --class=ViewsSeed
	@docker-compose ${COMPOSE_YML} -p $project_name run ${SERVER} php artisan db:seed --force

dump-autoload:
	@docker-compose ${COMPOSE_YML} -p $project_name run ${SERVER} composer dump-autoload

db-fresh:
	@echo -e "Make: Fresh database.\n"
	@docker exec ${RUN_APP_ARGS} "${SERVER_CONTAINER_NAME}" sh -c "php artisan migrate:fresh --seed --force"

composer-install:
	@echo -e "Make: Installing composer dependencies.\n"
	@docker exec ${RUN_APP_ARGS} "${SERVER_CONTAINER_NAME}" sh -c "composer install"

composer-update:
	@echo -e "Make: Installing composer dependencies.\n"
	@docker exec ${RUN_APP_ARGS} "${SERVER_CONTAINER_NAME}" sh -c "composer update"

key-generate:
	@echo -e "Make: Generate Laravel key.\n"
	@docker exec ${RUN_APP_ARGS} "${SERVER_CONTAINER_NAME}" sh -c "php artisan key:generate"

#cert-generate:
#	@echo -e "Make: Generate self-sign certifications.\n"
#	@mkcert ${VIRTUAL_HOST}
#	@mv ./${VIRTUAL_HOST}.pem ./storage/certs/${VIRTUAL_HOST}.crt
#	@mv ./${VIRTUAL_HOST}-key.pem ./storage/certs/${VIRTUAL_HOST}.key

helper-generate:
	@docker exec ${RUN_APP_ARGS} "${SERVER_CONTAINER_NAME}" sh -c "php artisan ide-helper:eloquent && php artisan ide-helper:generate && php artisan ide-helper:meta && php artisan ide-helper:models"

bash:
	@docker exec ${RUN_APP_ARGS} "${SERVER_CONTAINER_NAME}" bash

bash-client:
	@docker exec ${RUN_APP_ARGS} "${CLIENT_CONTAINER_NAME}" bash

bash-analytics:
	@docker exec ${RUN_APP_ARGS} "${ANALYTICS_CONTAINER_NAME}" bash

clickhouse-client:
	@docker exec ${RUN_APP_ARGS} "${CLICKHOUSE_CONTAINER_NAME}" clickhouse-client

perm:
	sudo chgrp -R ${CURRENT_USER} storage bootstrap/cache
	sudo chmod -R ug+rwx storage bootstrap/cache

test:
	@docker exec ${RUN_APP_ARGS} "${SERVER_CONTAINER_NAME}" sh -c "./vendor/bin/phpunit"

npm-build:
	@docker exec ${RUN_APP_ARGS} "${CLIENT_CONTAINER_NAME}" sh -c "npm run build"

npm-serve:
	@docker exec ${RUN_APP_ARGS} "${CLIENT_CONTAINER_NAME}" sh -c "npm run serve"

horizon:
	@docker exec ${RUN_APP_ARGS} "${SERVER_CONTAINER_NAME}" sh -c "php artisan horizon"

memory:
	sudo sysctl -w vm.max_map_count=262144