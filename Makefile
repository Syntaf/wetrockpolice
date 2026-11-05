SHELL=/opt/homebrew/bin/bash

# Local Development
# --------------------------------------------------
.PHONY: http
http:
	bundle exec rails server -p 3002 -b 0.0.0.0

.PHONY: up
up:
	docker-compose up -d postgres

.PHONY: install
install:
	bundle install && yarn install

.PHONY: restart-pg
restart-pg:
	docker compose restart postgres

# Build the JS/CSS bundles tests serve from app/assets/builds (Propshaft
# serves them live in dev/test; no precompile step needed).
.PHONY: pcat
pcat:
	yarn build && yarn build:css

.PHONY: db-drop
db-drop:
	rails db:drop

.PHONY: db-create
db-create:
	rails db:create

.PHONY: db-migrate
db-migrate:
	rails db:migrate

.PHONY: db-seed
db-seed:
	rails db:seed

.PHONY: init
init: db-create db-migrate db-seed

.PHONY: reset_db
reset-db: restart-pg db-drop init

# Deployment
# --------------------------------------------------
LATEST_HASH := $(shell cat .git/refs/heads/master)
LATEST_GIT_TAG := $(shell git describe --abbrev=0 --tags)
LATEST_CHART_VERSION := $(shell yq e '.version' k8s/wetrockpolice/Chart.yaml)

.PHONY: dev
dev:
	./bin/dev	

# DEPRECATED: CI is the image source of truth — pushes to master build and
# publish the image (.github/workflows/tests.yml). Kept only as an escape
# hatch; local pushes bypass the test gate.
.PHONY: build
build:
	@echo "WARNING: 'make build' is deprecated; CI builds the image on pushes to master (.github/workflows/tests.yml)."
	docker build -t syntaf/wetrockpolice:$(LATEST_HASH) \
		-f ./Dockerfile.production \
		.

.PHONY: push
push:
	@echo "WARNING: 'make push' is deprecated; CI publishes the image on pushes to master (.github/workflows/tests.yml)."
	docker push syntaf/wetrockpolice:$(LATEST_HASH)

.PHONY: sync
sync:
	yq -i ".image.tag = \"$$(kubectl get pods -n wetrockpolice -l app.kubernetes.io/name=wetrockpolice -o=jsonpath='{$$.items[*].spec.containers[*].image}' | head -n 1 | awk '{print $$1}' | awk -F':' '{print $$2}')\"" k8s/wetrockpolice/values.yaml
	yq -i ".appVersion = \"$$(kubectl get pods -n wetrockpolice -l app.kubernetes.io/name=wetrockpolice -o=jsonpath='{$$.items[*].metadata.annotations.wetrockpolice-app-version}' | awk -F' ' '{print $$2}')\"" k8s/wetrockpolice/Chart.yaml

.PHONY: deploy
deploy:
	helm upgrade -n wetrockpolice -f secrets.yaml wetrockpolice k8s/wetrockpolice

.PHONY: commit
commit:
	echo $(LATEST_HASH) > version.txt