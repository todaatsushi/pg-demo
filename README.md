This repository demonstrates some of the concepts behind working with postgresql in production.

It contains a Docker environment with seed data and scripts that emulates a simple store that sells coffee online.

The aim is to demonstrate the following:
- Optimising queries
    - Indexes
    - Different types of joins
- Locking
    - mainly in the context of database migrations

## Getting started

### Prerequisites

- Docker and Docker Compose

### Run

1. Build and start the container:

```bash
docker compose up -d
```

2. Shell into the container:

```bash
docker compose exec db bash
```

3. Authenticate Claude Code via device auth:

```bash
claude
```

This will provide a URL to authenticate in your browser.

4. Run the schema migration:

```bash
psql -f /app/src/migrations/0001_init.sql
```

5. Seed the data (~30-60s):

```bash
psql -f /app/src/migrations/0002_seed.sql
```

6. Connect to the database:

```bash
psql -U postgres -d coffee_store
```

### Stop

```bash
docker compose down
```

To also remove the database volume:

```bash
docker compose down -v
```
