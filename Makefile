up:
	docker compose up -d

down:
	docker compose down

wipe:
	docker compose down -v

shell:
	docker compose exec pg-demo /bin/bash

sql:
	docker compose exec pg-demo psql

logs:
	docker compose logs pg-demo

clear-cache:
	docker compose exec pg-demo psql -c "select pg_buffercache_evict_all();"
