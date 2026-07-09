# Data

## Tables

A logical grouped collection of individual data points which allows modelling of raw information into abstract concepts.

A table is made of rows + columns where a column represents an attribute or dimension, and a row is an entry of those things.

Most interactions with a table from an application POV is CRUD of rows on the table:

```sql
-- Read
SELECT * FROM stores WHERE LOWER(name) = 'regent street'; 

-- Create
INSERT INTO stores (name, location) VALUES
    ('Covered Market', 'Oxford, United Kingdom'),
    ('The Shambles', 'York, United Kingdom');

-- Update
UPDATE stores SET name = 'Trafalgar Square' WHERE name = 'Southgate';

-- Delete
DELETE FROM stores WHERE name = 'The Shambles';
```

## Sequences

These datastructures are counters that generate unique incrementing values, used for auto-incrementing primary keys.


## Views

As the name suggests, a view is a specific modelling of table data that acts as an interface into it.

Materialised views are views that are stored at a point in time (ie. refreshed only when explicitly called).
