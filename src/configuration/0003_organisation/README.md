# Schemas

Schemas are a flexible layer that sit between tables and the database. The reason to address them after is precisely because they are so flexible - most objects in the database can live on a schema. In fact, tables all must live on a schema and the default one is called `public`. It's possible and common to define custom schemas for logical grouping purposes.

Advantages of using schemas:
- Allows the logical grouping of tables within a database.
- Cordon off access to certain objects for certain purposes.
- Create layers for different access patterns e.g. modelled data to be used for special purposes vs for the application.
- Replicate naming across use cases - tables/other objects can be called the same thing as another object as long as it's not on the same schema.

## The search path

It's quite common to refer to tables without the schema name in it (the default is `"$user", public`, so before tweaking any schemas, table `stores` would actually be found at `public.stores`).

So to find the table, you can set where the system will look to find the *unqualified* path. The `search_path` allows one to add schemas into one's "vision" and make sure the system knows to look for it when omitting the schema name.

The `$user` is a variable that matches the user name being connected as in case the schema and user are named the same. It's skipped if it doesn't exist.

## Granting on schemas

Schema privileges and object privileges are two separate layers — both are required to access an object.

Schema-level privileges:
- `USAGE ON SCHEMA <name>` — required to reference objects in the schema at all. Without it a role cannot even mention `schema.table`.
- `CREATE ON SCHEMA <name>` — required to create new objects in the schema.

Object-level privileges (`SELECT`, `INSERT`, etc.) are granted per-object and are independent of the schema. Reading a table requires both:

```sql
GRANT USAGE ON SCHEMA application TO some_role;
GRANT SELECT ON application.stores TO some_role;
```

`USAGE` on a schema does **not** cascade down to grant `SELECT` on its tables — there is no schema-level equivalent of `SELECT` that bubbles down to all objects. The closest bulk mechanism is:

```sql
GRANT SELECT ON ALL TABLES IN SCHEMA application TO some_role;
```

but this only covers tables that exist at the time the statement runs. See `0004_users/README.md` for how `ALTER DEFAULT PRIVILEGES` addresses future objects.

Schemas are separate objects to the objects within the schema. Grants on the schema apply to the literal schema itself and grants to the objects must be made individually.
