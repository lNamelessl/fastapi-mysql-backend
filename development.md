# FastAPI MySQL Backend - Development

## Local Development

Run MySQL and Mailpit with Docker Compose, and run the FastAPI development server locally.

Start the supporting services:

```bash
docker compose up -d db mailpit
```

- MySQL is available on `localhost:3306` (user `root`, database `app`, password from `MYSQL_ROOT_PASSWORD` in `.env`).
- Mailpit's inbox UI is at `http://localhost:8025` (SMTP on port `1025`).

Then, from the `backend` directory, install the dependencies and prepare the database:

```bash
uv sync
uv run bash scripts/prestart.sh
```

`scripts/prestart.sh` runs the Alembic migrations and creates the first superuser from `FIRST_SUPERUSER` / `FIRST_SUPERUSER_PASSWORD` in `.env`.

Start the FastAPI development server:

```bash
uv run fastapi dev --reload
```

The API is served at `http://localhost:8000`, the interactive docs at `http://localhost:8000/docs`, and the OpenAPI spec at `http://localhost:8000/api/v1/openapi.json`.

### Full stack in Docker

Alternatively run the whole thing in containers:

```bash
docker compose up -d --wait
```

The backend listens on `http://localhost:8000`. The `compose.override.yml` override runs it with `fastapi dev`, hot code sync via `docker compose watch`, and Mailpit as the SMTP host.

## Database Migrations

The migration history is a single squashed initial migration (`0001_initial_models.py`) that creates the final schema directly on MySQL — `sa.Uuid()` primary keys (stored as `CHAR(32)`), 255-char varchars, and the `ON DELETE CASCADE` foreign key. Upstream's Postgres migration chain (integer IDs → `uuid-ossp` UUID swap) does not apply to MySQL.

After changing the SQLModel models in `backend/app/models.py`, autogenerate a migration:

```bash
cd backend
uv run alembic revision --autogenerate -m "describe the change"
uv run bash scripts/prestart.sh   # apply it
```

Note MySQL's Alembic rules: every `op.alter_column` needs `existing_type=`, use `sa.Uuid()` (never `sa.UUID()`), and DDL is non-transactional — if a migration fails halfway, drop and recreate the database before retrying (`docker compose down -v && docker compose up -d db`).

## Emails

In development, SMTP points at Mailpit (`SMTP_HOST=mailpit`, port `1025` in the compose override). Emails never leave your machine — inspect them at `http://localhost:8025`.

## Tests

```bash
docker compose up -d --wait db mailpit
cd backend
uv run bash scripts/prestart.sh
uv run bash scripts/tests-start.sh
```

The test suite runs against the same local MySQL database as development. Coverage HTML lands in `backend/htmlcov`.
