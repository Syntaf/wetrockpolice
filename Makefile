SHELL=/opt/homebrew/bin/bash

# Local Development
# --------------------------------------------------
.PHONY: http
http:
	bundle exec rails server -p 3002 -b 0.0.0.0

.PHONY: build
build:
	docker build -t syntaf/wetrockpolice:$(LATEST_HASH) \
		--build-arg RAILS_ENV=production \
		--build-arg USER_ID=1000 \
		--build-arg GROUP_ID=1000 \
		-f ./Dockerfile.production \
		.

.PHONY: push
push:
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

.PHONY: worker
worker:
	bundle exec sidekiq -q default -q mailers

.PHONY: up
up:
	docker-compose up -d postgres redis

.PHONY: install
install:
	bundle install && yarn install

.PHONY: restart-pg
restart-pg:
	docker compose restart postgres

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
