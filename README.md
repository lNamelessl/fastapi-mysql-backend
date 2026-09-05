# FastAPI MySQL Backend Template

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy/fastapi-mysql-backend)

A **backend-only, MySQL-powered** variant of the official [Full Stack FastAPI Template](https://github.com/fastapi/full-stack-fastapi-template), packaged for **one-click deployment on [Railway](https://railway.app)**.

All frontend code (React, Vite, Playwright, the Bun workspace) and all PostgreSQL specifics have been removed. What remains is a production-ready FastAPI API server with JWT auth, SQLModel ORM, Alembic migrations, and an email stack — wired for MySQL 8.x and Railway's deployment model.

## Technology Stack and Features

- ⚡ [**FastAPI**](https://fastapi.tiangolo.com) for the Python backend API.
  - 🧰 [SQLModel](https://sqlmodel.tiangolo.com) for the Python SQL database interactions (ORM).
  - 🔍 [Pydantic](https://docs.pydantic.dev), used by FastAPI, for the data validation and settings management.
  - 💾 **MySQL 8.x** as the SQL database, via [PyMySQL](https://pymysql.readthedocs.io) + `cryptography`.
- 🔒 Secure password hashing by default (Argon2).
- 🔑 JWT (JSON Web Token) authentication with OAuth2 password flow.
- 📫 Email-based password recovery, with Jinja2 HTML templates.
- 🗃️ [Alembic](https://alembic.sqlalchemy.org) migrations that run automatically on every deploy.
- 🩺 A redirect-free `GET /health` endpoint for platform healthchecks.
- 🐋 [Docker Compose](https://www.docker.com) for local development (MySQL + Mailpit).
- ✅ Tests with [Pytest](https://pytest.org).

## Deploy to Railway

The repo root contains a Railway-ready `Dockerfile` and `railway.json`:

- The `Dockerfile` builds the backend (no frontend stage), binds to Railway's `PORT` variable, and runs **migrations + initial seed inside the container start command** (Railway ignores `preDeployCommand` on its Metal/CLI pipeline).
- `railway.json` configures the Dockerfile builder, a `/health` healthcheck path, and an `ON_FAILURE` restart policy.

### One-click deploy

Click the deploy button at the top of this README, or open the template page:

```
https://railway.com/deploy/fastapi-mysql-backend
```

### Manual deploy with the Railway CLI

```bash
railway init --name my-api
railway add -d mysql          # provisions a MySQL database service
railway add -s backend        # creates the app service from this repo
railway variables --set 'DATABASE_URL=${{MySQL.MYSQL_URL}}' \
  --set "PROJECT_NAME=My API" \
  --set "SECRET_KEY=$(openssl rand -hex 32)" \
  --set "FIRST_SUPERUSER=admin@example.com" \
  --set "FIRST_SUPERUSER_PASSWORD=$(openssl rand -hex 16)" \
  --service backend
railway up --service backend
railway domain                # generate a public URL
```

After generating a public domain, set it as the allowed CORS origin:

```bash
railway variables --set "FRONTEND_HOST=https://<your-domain>" --service backend --skip-deploy
```

**Important**: never set `FASTAPI_ENV` on Railway — config only allows `development` or unset; any other value crash-loops the container at boot.

On every deploy the container start command runs `alembic upgrade head` (migrations) and seeds the first superuser from `FIRST_SUPERUSER` / `FIRST_SUPERUSER_PASSWORD` if the users table is empty.

## Local Development

Read the [development guide](development.md) for the full workflow. Quickstart:

```bash
docker compose up -d db mailpit   # MySQL on localhost:3306, Mailpit UI on :8025
cd backend
uv sync
uv run bash scripts/prestart.sh   # alembic migrations + seed superuser
uv run fastapi dev --reload
```

The default `.env` points the app at `mysql://root:changethis@localhost:3306/app` (matching the compose MySQL). Change `MYSQL_ROOT_PASSWORD` in `.env` if you change one.

## Tests

With the local stack up:

```bash
docker compose up -d --wait db mailpit
cd backend
uv run bash scripts/prestart.sh
uv run bash scripts/tests-start.sh
```

## How it differs from the upstream template

- **No frontend**: removed `frontend/`, the Bun/npm workspace, React Email packages, Playwright, and the generated client. The API no longer serves a SPA; `GET /` returns a small JSON welcome message.
- **MySQL instead of PostgreSQL**: `MySQLDsn` config parsing, `mysql+pymysql` driver rewriting, `pool_recycle`/`READ COMMITTED` engine settings, `sa.Uuid()` columns (stored as `CHAR(32)`), and a squashed single initial migration (upstream's int→UUID migration chain relied on the Postgres `uuid-ossp` extension).
- **Railway packaging**: root `Dockerfile`, `railway.json`, `$PORT` binding, `/health` endpoint, and migrations in the container start command.

## License

MIT, same as the upstream [full-stack-fastapi-template](https://github.com/fastapi/full-stack-fastapi-template).
