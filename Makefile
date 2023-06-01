include .env

default: help

DRUPAL_CONTAINER=$(shell docker ps --filter name='^/$(PROJECT_NAME)_drupal' --format "{{ .ID }}")
COMPOSER_ROOT ?= /home/drupal/project
DRUPAL_ROOT ?= /home/drupal/project/httpdocs
DESKTOP_PATH ?= ~/Desktop/

## help : Print commands help.
.PHONY: help
ifneq (,$(wildcard docker.mk))
help : docker.mk
	@sed -n 's/^##//p' $<
else
help : Makefile
	@sed -n 's/^##//p' $<
endif

## up : Start up containers.
.PHONY: up
up:
	mkdir -p project
	@echo "Starting up containers for $(PROJECT_NAME)..."
	docker compose pull
	docker compose up -d --wait --remove-orphans --build

## down : Stop containers.
.PHONY: down
down: stop

## start : Start containers without updating.
.PHONY: start
start:
	@echo "Starting containers for $(PROJECT_NAME) from where you left off..."
	@docker compose start

## stop : Stop containers.
.PHONY: stop
stop:
	@echo "Stopping containers for $(PROJECT_NAME)..."
	@docker compose stop

## prune : Remove containers and their volumes.
##		You can optionally pass an argument with the service name to prune single container
##		prune mariadb : Prune `mariadb` container and remove its volumes.
##		prune mariadb solr : Prune `mariadb` and `solr` containers and remove their volumes.
.PHONY: prune
prune:
	$(MAKE) clean-project
	@echo "Removing containers for $(PROJECT_NAME)..."
	@docker compose down -v $(filter-out $@,$(MAKECMDGOALS))

## ps : List running containers.
.PHONY: ps
ps:
	@docker ps --filter name='$(PROJECT_NAME)*'

## shell : Access `php` container via shell.
##		You can optionally pass an argument with a service name to open a shell on the specified container
.PHONY: shell
shell:
	docker exec -ti -e COLUMNS=$(shell tput cols) -e LINES=$(shell tput lines) $(shell docker ps --filter name='$(PROJECT_NAME)_$(or $(filter-out $@,$(MAKECMDGOALS)), 'drupal')' --format "{{ .ID }}") bash

## composer : Executes `composer` command in a specified `COMPOSER_ROOT` directory (default is `/var/www/html`).
##		To use "--flag" arguments include them in quotation marks.
##		For example: make composer "update drupal/core --with-dependencies"
.PHONY: composer
composer:
	docker exec $(DRUPAL_CONTAINER) composer --working-dir=$(COMPOSER_ROOT) $(filter-out $@,$(MAKECMDGOALS))

## drush : Executes `drush` command in a specified `DRUPAL_ROOT` directory (default is `/home/drupal/project/httpdocs`).
##		To use "--flag" arguments include them in quotation marks.
##		For example: make drush "watchdog:show --type=cron"
.PHONY: drush
drush:
	docker exec $(DRUPAL_CONTAINER) drush -r $(DRUPAL_ROOT) $(filter-out $@,$(MAKECMDGOALS))

## logs : View containers logs.
##		You can optinally pass an argument with the service name to limit logs
##		logs php : View `php` container logs.
##		logs nginx php : View `nginx` and `php` containers logs.
.PHONY: logs
logs:
	@docker compose logs -f $(filter-out $@,$(MAKECMDGOALS))

.PHONY: create-init
create-init:
##		For example: make create-init "<project_name>"
	cp -R ${DESKTOP_PATH}drupal-7-pro-docker ${DESKTOP_PATH}$(word 2, $(MAKECMDGOALS))-docker
	mkdir ${DESKTOP_PATH}$(word 2, $(MAKECMDGOALS))-docker/project

## create-setup : Setup local project from existing Git project.
##		For example: make create-setup "<project_name> <repo-git>"
.PHONY: create-setup
create-setup:
	cp -R ${DESKTOP_PATH}drupal-7-pro-docker ${DESKTOP_PATH}$(word 2, $(MAKECMDGOALS))-docker
	git clone $(word 3, $(MAKECMDGOALS)) ${DESKTOP_PATH}$(word 2, $(MAKECMDGOALS))-docker/project

## init : Init new Drupal 7 project.
.PHONY: init
init:
	$(MAKE) up
	$(MAKE) create-project
	$(MAKE) web-symlink
	$(MAKE) drupal-install

## setup : Install existing Drupal 7 project.
.PHONY: setup
setup:
	$(MAKE) up
	$(MAKE) web-symlink
	$(MAKE) drupal-install

## create-project : Create project from Drupal 7 release.
.PHONY: create-project
create-project:
	docker exec $(DRUPAL_CONTAINER) rm -rf front
	docker exec $(DRUPAL_CONTAINER) wget https://ftp.drupal.org/files/projects/drupal-${DRUPAL_VERSION}.tar.gz
	docker exec $(DRUPAL_CONTAINER) mkdir httpdocs
	docker exec $(DRUPAL_CONTAINER) tar --strip-components=1 -xvzf drupal-${DRUPAL_VERSION}.tar.gz -C httpdocs
	docker exec $(DRUPAL_CONTAINER) rm -rf drupal-${DRUPAL_VERSION}.tar.gz
	docker exec $(DRUPAL_CONTAINER) mkdir front

## drupal-install : Drupal site install from existent.
.PHONY: drupal-install
drupal-install:
	docker exec $(DRUPAL_CONTAINER) drush -r $(DRUPAL_ROOT) site-install standard install_configure_form.update_status_module='array(FALSE,FALSE)' --db-url=${DB_DRIVER}://root:${DB_ROOT_PASSWORD}@${DB_HOST}/${DB_NAME} -y --account-name=${INSTALL_ACCOUNT_NAME} --account-pass=${INSTALL_ACCOUNT_PASS} --account-mail=${INSTALL_ACCOUNT_MAIL}

## clean-project : Remove project directory content
.PHONY: clean-project
clean-project:
	docker exec -u root -w /home/drupal $(DRUPAL_CONTAINER) bash -c 'shopt -s dotglob && rm -rf project/*'

## web-symlink : Create web symbolic link in /var/www/
.PHONY: web-symlink
web-symlink:
	docker exec -u root $(DRUPAL_CONTAINER) rm -rf /var/www/html
	docker exec -u root $(DRUPAL_CONTAINER) ln -sf /home/drupal/project/httpdocs /var/www/html
	docker exec -u root $(DRUPAL_CONTAINER) chown drupal:drupal /var/www/html

## copy-env-file : Copy .env file.
.PHONY: copy-env-file
copy-env-file:
	cp .env.dist .env

## restore-dump : Restore dump.
##		For example: make restore-dump ./dump/<dump_name>.sql.gz
.PHONY: restore-dump
restore-dump:
	docker exec $(DRUPAL_CONTAINER) drush -r $(DRUPAL_ROOT) sql-drop -y
	docker exec -i $(DRUPAL_CONTAINER) gunzip -c $(filter-out $@,$(MAKECMDGOALS)) | docker exec -i $(DRUPAL_CONTAINER) drush -r $(DRUPAL_ROOT) sql-cli
	docker exec $(DRUPAL_CONTAINER) drush -r $(DRUPAL_ROOT) uli

## backup : Make a backup.
.PHONY: backup
backup:
	docker exec $(DRUPAL_CONTAINER) drush -r $(DRUPAL_ROOT) sql-dump --result-file=auto --gzip


# https://stackoverflow.com/a/6273809/1826109
%:
	@:
