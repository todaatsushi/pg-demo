up:
	docker compose up -d

down:
	docker compose down

wipe:
	docker compose down -v

shell:
	docker compose exec pg-demo /bin/bash

logs:
	docker compose logs pg-demo
