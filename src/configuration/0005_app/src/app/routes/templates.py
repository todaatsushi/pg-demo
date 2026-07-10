"""
routes/templates.py — HTML template routes.

These routes serve server-rendered HTML pages using Jinja2.
They allow a user to view and add stores, staff members, and orders.

The `jinja` variable is injected by main.py after import, which avoids
a circular dependency between main.py (which owns the Jinja2Templates
instance) and this module.

Routes
------
GET  /            Landing page with navigation links.
GET  /stores      List all stores + form to add a new one.
POST /stores      Insert a new store; redirect back to GET /stores.
GET  /staff       List all staff (joined with store name) + form to add.
POST /staff       Insert a new staff member; redirect back to GET /staff.
GET  /orders      List all orders + form to add a new one.
POST /orders      Insert a new order; redirect back to GET /orders.

Database access
---------------
All queries run against the `application` schema:
  - application.stores
  - application.staff
  - application.orders

The `application` login user (used by this app) has write_app_data,
which grants SELECT, INSERT, UPDATE, DELETE on application.*.

Form handling
-------------
FastAPI's Form(...) dependency parses application/x-www-form-urlencoded
bodies (the default encoding for plain HTML forms). python-multipart
must be installed for this to work (it is listed in pyproject.toml).

After a successful POST, we redirect with HTTP 303 (See Other) so that
a browser refresh does not resubmit the form.
"""

from typing import Any

from fastapi import APIRouter, Form, Request
from fastapi.responses import HTMLResponse, RedirectResponse
from fastapi.templating import Jinja2Templates

from app import db

router = APIRouter()

# Injected by main.py — see main.py for explanation.
jinja: Jinja2Templates | None = None


# ---------------------------------------------------------------------------
# Landing page
# ---------------------------------------------------------------------------


@router.get("/", response_class=HTMLResponse)
def index(request: Request) -> Any:
    assert jinja is not None
    return jinja.TemplateResponse(request, "index.html")


# ---------------------------------------------------------------------------
# Stores
# ---------------------------------------------------------------------------


@router.get("/stores", response_class=HTMLResponse)
def stores_page(request: Request) -> Any:
    """Render the stores page.

    Fetches all rows from application.stores and passes them to the
    template as `stores`. The template renders both the add-store form
    and the listing table.
    """
    with db.pool.connection() as conn:
        with conn.cursor(row_factory=db.dict_row) as cur:
            cur.execute("SELECT id, name, location FROM application.stores ORDER BY id")
            stores = cur.fetchall()

    assert jinja is not None
    return jinja.TemplateResponse(request, "stores.html", {"stores": stores})


@router.post("/stores")
def add_store(
    name: str = Form(...),
    location: str = Form(""),
) -> RedirectResponse:
    """Insert a new store into application.stores.

    Both columns map directly to the stores table definition:
      name      text NOT NULL
      location  text           (nullable — empty string stored as empty, not NULL)

    After insert we redirect to GET /stores with HTTP 303 so the browser
    does not resubmit the form on refresh.
    """
    with db.pool.connection() as conn:
        conn.execute(
            "INSERT INTO application.stores (name, location) VALUES (%s, %s)",
            (name, location or None),
        )

    return RedirectResponse(url="/stores", status_code=303)


# ---------------------------------------------------------------------------
# Staff
# ---------------------------------------------------------------------------


@router.get("/staff", response_class=HTMLResponse)
def staff_page(request: Request) -> Any:
    """Render the staff page.

    Fetches all staff joined with their store name, and all stores for
    the dropdown in the add-staff form. Both are passed to the template.
    """
    with db.pool.connection() as conn:
        with conn.cursor(row_factory=db.dict_row) as cur:
            cur.execute("""
                SELECT st.id, st.name, s.name AS store_name
                FROM application.staff st
                JOIN application.stores s ON s.id = st.store_id
                ORDER BY st.id
            """)
            staff = cur.fetchall()

            cur.execute("SELECT id, name FROM application.stores ORDER BY id")
            stores = cur.fetchall()

    assert jinja is not None
    return jinja.TemplateResponse(
        request, "staff.html", {"staff": staff, "stores": stores}
    )


@router.post("/staff")
def add_staff(
    name: str = Form(...),
    store_id: int = Form(...),
) -> RedirectResponse:
    """Insert a new staff member into application.staff.

    store_id must reference an existing row in application.stores — this
    is enforced by the FK constraint on the table. If an invalid store_id
    is submitted the database will raise an IntegrityError, which FastAPI
    will surface as a 500. In production you would catch this explicitly.
    """
    with db.pool.connection() as conn:
        conn.execute(
            "INSERT INTO application.staff (name, store_id) VALUES (%s, %s)",
            (name, store_id),
        )

    return RedirectResponse(url="/staff", status_code=303)


# ---------------------------------------------------------------------------
# Orders
# ---------------------------------------------------------------------------


@router.get("/orders", response_class=HTMLResponse)
def orders_page(request: Request) -> Any:
    with db.pool.connection() as conn:
        with conn.cursor(row_factory=db.dict_row) as cur:
            cur.execute("""
                SELECT o.id, o.product, o.units, o.ordered_at,
                       s.name AS store_name, st.name AS staff_name
                FROM application.orders o
                JOIN application.stores s ON s.id = o.store_id
                JOIN application.staff st ON st.id = o.staff_id
                ORDER BY o.ordered_at DESC
            """)
            orders = cur.fetchall()

            cur.execute("SELECT id, name FROM application.stores ORDER BY id")
            stores = cur.fetchall()

            cur.execute("SELECT id, name FROM application.staff ORDER BY id")
            staff = cur.fetchall()

    assert jinja is not None
    return jinja.TemplateResponse(
        request, "orders.html", {"orders": orders, "stores": stores, "staff": staff}
    )


@router.post("/orders")
def add_order(
    product: str = Form(...),
    units: int = Form(...),
    store_id: int = Form(...),
    staff_id: int = Form(...),
) -> RedirectResponse:
    with db.pool.connection() as conn:
        conn.execute(
            "INSERT INTO application.orders (product, units, store_id, staff_id) "
            "VALUES (%s, %s, %s, %s)",
            (product, units, store_id, staff_id),
        )

    return RedirectResponse(url="/orders", status_code=303)
