# Roles + Users

Postgres uses RBAC to allow access to various features provided by the platform. It ranges from simple stuff like the ability to login all the way down to being able to interact with the data itself.

A collection of these abilities (ie. the permissions or `privileges`) can be grouped into a `Role`. In `psql` you can see all roles using `\du`. Any role can be granted the ability to login with a password - this then makes a role a `User`.

The basic privileges are:
- `SELECT`
- `INSERT`
- `UPDATE`
- `DELETE`
- `TRUNCATE`
- `REFERENCES`
- `TRIGGER`
- `CREATE`
- `CONNECT`
- `TEMPORARY`
- `EXECUTE`
- `USAGE`
- `SET` -- server level
- `ALTER SYSTEM` -- server level
- `MAINTAIN` -- new in 17

You can read about these individually in [the docs](https://www.postgresql.org/docs/current/ddl-priv.html#DDL-PRIV) and you combine one of these on a Postgres entity to create the "behaviour" you want to `grant` (the official verb).

Because a user is just a role to login, it's possible to create a logical separation - users just collect roles, which in turn collect privileges:

```
- USER: application  -- Can login using password
    - HAS ROLE: connect  -- can connect to the database `grocery_store`
        - DUE TO PRIVILEGE: CONNECT ON `grocery_store`
```

As an example, you might separate the users to match access patterns - a human that is connecting to the database in order to query results could be a different user to the application, so would warrant different privileges.

## Users in this setup

| User | Owns | Access |
|------|------|--------|
| `application` | `application` schema + all its tables | Full DDL + DML on `application.*`. No access to `reporting`. |
| `reporting` | `reporting` schema + all its views | Full DDL + DML on `reporting.*`. SELECT on `application.*` (needed to define and query views over application data). |
| `developer_ro` | — | SELECT on `application.*` and `reporting.*`. Human read-only access. |
| `performance_monitoring` | — | `pg_stat_activity` and monitoring views only via `pg_monitor`. No access to application data. |

Grouping roles:

| Role | Privileges |
|------|-----------|
| `read_app_data` | `USAGE` on `application` schema + `SELECT` on all its tables |
| `write_app_data` | `USAGE` on `application` schema + `SELECT, INSERT, UPDATE, DELETE` on all its tables + `USAGE` on sequences |
| `read_reporting` | `USAGE` on `reporting` schema + `SELECT` on all its views |

## Granting — "at the time" vs "from now on"

A standard `GRANT` statement only applies to objects that exist when the statement runs:

```sql
GRANT SELECT ON ALL TABLES IN SCHEMA application TO read_app_data;
```

This covers every table currently in `application` — but any table created later will have no grant and will be inaccessible to `read_app_data`.

To cover future objects automatically, use `ALTER DEFAULT PRIVILEGES`:

```sql
ALTER DEFAULT PRIVILEGES IN SCHEMA application
    GRANT SELECT ON TABLES TO read_app_data;
```

This tells PostgreSQL: from now on, any table created in `application` should automatically grant `SELECT` to `read_app_data`. Both are typically used together — the first covers existing objects, the second ensures new ones are covered.

## Ownership and grants

Every object in PostgreSQL has exactly one owner (a role). The owner has implicit full privileges on the object including DDL rights — they can `ALTER` or `DROP` it without any explicit grant. Only the owner (or a superuser) can grant privileges on an object to other roles.

`ALTER DEFAULT PRIVILEGES` is scoped to the role that **creates** the object — i.e. the would-be owner. This means default privilege declarations must match the creating role:

```sql
ALTER DEFAULT PRIVILEGES FOR ROLE application IN SCHEMA application
    GRANT SELECT ON TABLES TO read_app_data;

ALTER DEFAULT PRIVILEGES FOR ROLE reporting IN SCHEMA reporting
    GRANT SELECT ON TABLES TO read_reporting;
```

If `application` creates a table in `application`, the first declaration applies. If `reporting` creates a view in `reporting`, the second applies. Without the appropriate `FOR ROLE` clause, the object is created with no automatic grants and roles that need access will be denied.
