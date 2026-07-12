"""
main.py - FastAPI application entrypoint.

Responsibilities:
  - Define the lifespan context that opens and closes the connection pool.
    psycopg's ConnectionPool must be explicitly opened before use; the
    lifespan ensures it is open for the full lifetime of the server and
    cleanly closed on shutdown.
  - Mount the template router:
      /        → template routes (HTML, stores + staff CRUD)
  - Configure Jinja2Templates so all template routes can render HTML.

Run with:
    fastapi dev app/main.py
"""

from collections.abc import AsyncGenerator
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.templating import Jinja2Templates

from app import db
from app.routes import templates

# ---------------------------------------------------------------------------
# Jinja2 template engine
# Pointed at the templates/ directory relative to this file.
# ---------------------------------------------------------------------------
jinja = Jinja2Templates(directory="app/templates")


# ---------------------------------------------------------------------------
# Lifespan
# Opens the psycopg ConnectionPool on startup and closes it on shutdown.
# Using a lifespan (rather than @app.on_event) is the modern FastAPI pattern.
# ---------------------------------------------------------------------------
@asynccontextmanager
async def lifespan(_: FastAPI) -> AsyncGenerator[None, None]:
    db.pool.open()
    yield
    db.pool.close()


# ---------------------------------------------------------------------------
# Application
# ---------------------------------------------------------------------------
app = FastAPI(title="Grocery Store Demo", lifespan=lifespan)

# Pass the Jinja2 instance into the template router so it can render responses.
templates.jinja = jinja

app.include_router(templates.router)
