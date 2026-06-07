up:
	docker compose up -d

down:
	docker compose down

wipe:
	docker compose down -v

dev:
	docker compose exec pg-demo /bin/bash

shell:
	docker compose exec	-e PGPASSWORD=postgres pg-demo /bin/bash

sql:
	docker compose exec -e PGPASSWORD=postgres pg-demo psql -U postgres -d coffee_store

logs:
	docker compose logs pg-demo

clear-cache:
	docker compose exec pg-demo psql -c "select pg_buffercache_evict_all();"
