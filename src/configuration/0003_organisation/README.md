# Schemas

Schemas are a flexible layer that sit between tables and the database. The reason to address them after is precisely because they are so flexible - most objects in the database can live on a schema. In fact, tables all must live on a schema and the default one is called `public`. It's possible and common to define custom schemas for logical grouping purposes.

Advantages of using schemas:
- Allows the logical grouping of tables within a database.
- Cordon off access to certain objects for certain purposes.
- Create layers for different access patterns e.g. modelled data to be used for special purposes vs for the application.
- Replicate naming across use cases - tables/other objects can be called the same thing as another object as long as it's not on the same schema.

## The search path

It's quite common to refer to tables without the schema name in it. So to find the table, you can set where the system will look to find the *unqualified* path. The `search_path` allows one to add schemas into one's "vision" and make sure the system knows to look for it when omitting the schema name. (the default is `"$user", public`, so before tweaking any schemas, table `stores` would actually be found at `public.stores`).

The `$user` is a variable that matches the user name being connected as in case the schema and user are named the same. It's skipped if it doesn't exist.

