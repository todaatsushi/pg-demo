USER     ?= postgres
PASSWORD ?= postgres

shell:
	docker compose -f ../../docker-compose.yml exec -e PGPASSWORD=$(PASSWORD) pg-demo /bin/bash

sql:
	docker compose -f ../../docker-compose.yml exec -e PGPASSWORD=$(PASSWORD) pg-demo psql -U $(USER) -d coffee_store

clear-cache:
	docker compose -f ../../docker-compose.yml exec pg-demo psql -c "select pg_buffercache_evict_all();"
