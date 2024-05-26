SHELL=/opt/homebrew/bin/bash

# Local Development
# --------------------------------------------------
.PHONY: http
http:
	bundle exec rails server -p 3002 -b 0.0.0.0

.PHONY: worker
worker:
	bundle exec sidekiq -q default -q mailers

.PHONY: up
up:
	docker-compose up -d postgres redis

.PHONY: install
install:
	bundle install && yarn install

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
reset-db: db-drop init