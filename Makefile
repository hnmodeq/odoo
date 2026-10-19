# Convenience wrappers around docker compose (Linux/macOS).
# Windows users: just run the docker compose commands directly —
# see LAUNCH_GUIDE.md. This file is optional.

.PHONY: up try down logs ps build rebuild reset init-demo shell dbshell

up:            ## Build (first time) and start Odoo from this source
	docker compose up --build -d

try:           ## Start the official odoo:20.0 image instead (no build)
	docker compose -f docker-compose.try.yml up -d

down:          ## Stop everything (data is kept)
	docker compose down
	docker compose -f docker-compose.try.yml down

logs:          ## Follow the Odoo server logs
	docker compose logs -f web

ps:            ## Show container status / health
	docker compose ps

build:         ## (Re)build the image without starting it
	docker compose build

reset:         ## DANGER: stop and DELETE all data (volumes), then rebuild fresh
	docker compose down -v
	docker compose up --build -d

init-demo:     ## Create a database "demo" with CRM + Sales already installed
	docker compose run --rm web odoo -d demo -i base,web,crm,sale_management --without-demo=all --stop-after-init
	docker compose up -d web

shell:         ## Open a shell inside the web container
	docker compose exec web bash

dbshell:       ## Open psql inside the db container
	docker compose exec db sh -c 'psql -U "$$POSTGRES_USER" postgres'
