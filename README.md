# pg-demo

A PostgreSQL demo environment running in Docker.

## `src/queries`

Query performance and locking using a high-volume coffee store dataset (up to 5M orders).

- **Indexes** — B-tree, composite, partial, covering, GIN
- **Joins** — nested loop, hash join, merge join
- **Locking** — long-running ops, lock queuing, timeouts

See [`src/queries/README.md`](src/queries/README.md).

## `src/configuration`

Configuring a PostgreSQL database from scratch.

- **Databases, tables, views** — modelling data, regular vs materialised views
- **Schemas** — organising objects, search path, grants
- **Roles and users** — RBAC, ownership, privilege separation, default privileges
- **App** — FastAPI app and Python scripts exercising the permission boundaries

See [`src/configuration/README.md`](src/configuration/README.md).

## Usage

```bash
make up    # start
make dev   # shell into container
make down  # stop
make wipe  # stop + remove volume
```
