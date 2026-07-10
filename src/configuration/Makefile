USER     ?= postgres
PASSWORD ?= postgres

shell:
	docker compose -f ../../docker-compose.yml exec -e PGPASSWORD=$(PASSWORD) pg-demo /bin/bash

sql:
	docker compose -f ../../docker-compose.yml exec -e PGPASSWORD=$(PASSWORD) pg-demo psql -U $(USER) -d grocery_store
