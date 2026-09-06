# FastAPI MySQL Backend — Railway Template

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy/fastapi-mysql-backend)

A production-ready **FastAPI backend API with MySQL**, derived from the official [Full Stack FastAPI Template](https://github.com/fastapi/full-stack-fastapi-template) (frontend removed, PostgreSQL replaced by MySQL) and packaged for one-click deployment on Railway.

## What you get

- ⚡ **FastAPI** with automatic interactive docs (`/docs`) and an OpenAPI schema (`/api/v1/openapi.json`).
- 🔐 **JWT authentication** (OAuth2 password flow), secure Argon2 password hashing, email-based password recovery.
- 🗄️ **MySQL 8** provisioned as a Railway database service, accessed through SQLModel + PyMySQL.
- 🧱 **SQLModel** ORM models for `User` and `Item` (UUID primary keys), with typed CRUD utilities.
- 🧳 **Alembic migrations** plus automatic first-superuser seeding, run on every deploy by the container start command.
- 📧 Email sending via SMTP with Jinja2 HTML templates (Mailpit for local development).
- 🩺 A redirect-free `GET /health` endpoint used by Railway's healthcheck.
- 🧪 A full **Pytest** suite covering auth, users, and items CRUD.

## Deploying

1. Click the deploy button above. The deploy form has **no required variables** — just deploy.
2. Railway provisions two services from the template: **MySQL** and the **backend** app, and creates a public domain for the backend automatically.
3. The backend's `DATABASE_URL` is a live reference to the MySQL service (private hostname + per-deployment generated root password), and `SECRET_KEY` is generated fresh for each deployment via a Railway `secret()` expression — nothing to configure.
4. On boot the container creates the database, runs `alembic upgrade head`, and seeds the first superuser — no manual migration step.
5. The admin account starts with placeholder credentials (`admin@example.com` / `ChangeMeBeforeDeploy1`). For a real deployment, set `FIRST_SUPERUSER` and `FIRST_SUPERUSER_PASSWORD` before the first deploy (or reset the seeded user afterwards) — seeding only runs on an empty database.
6. `FRONTEND_HOST` (the CORS allowed origin) defaults to the backend's own generated domain via `${{RAILWAY_PUBLIC_DOMAIN}}`; `PROJECT_NAME` defaults to a placeholder. Both are editable on the service after deploy.

**Never set `FASTAPI_ENV`** on Railway: the config only allows `development` or unset, and any other value crash-loops the container.

# Deploy and Host

Deploy a FastAPI REST API with a managed MySQL database on Railway in one click. The template provisions two services: a MySQL database and a Dockerized FastAPI backend that runs its own Alembic migrations and superuser seeding on every boot, then serves the API on Railway's dynamically assigned `PORT` with a `/health` healthcheck.

## About Hosting

Hosting this template gives you a self-contained JSON/REST API: JWT auth with Argon2 password hashing, users and items CRUD backed by MySQL through SQLModel, Alembic schema migrations, and SMTP email with Jinja2 templates for password recovery. The backend listens on `$PORT`, is healthchecked at `/health`, and restarts on failure (`ON_FAILURE`, up to 10 retries). Migrations and the initial superuser seed (from the `FIRST_SUPERUSER` / `FIRST_SUPERUSER_PASSWORD` variables) run automatically inside the container start command, so every fresh deploy comes up ready to serve authenticated requests. After the first deploy, generate a public domain and set it as `FRONTEND_HOST` (the CORS origin) if you will call the API from a browser.

## Why Deploy

The upstream template assumes a full-stack repo with React, a Bun workspace, PostgreSQL, and docker-compose + Traefik for self-hosting — none of which fits a platform like Railway. This template removes all of that for you: it ships a backend-only API, swaps the database layer to MySQL (`MySQLDsn` parsing, `mysql+pymysql` driver, `CHAR(32)` UUID columns, a squashed MySQL-safe migration), bakes migrations into the container start command because Railway ignores `preDeployCommand`, binds to Railway's `PORT`, and exposes a redirect-free `/health` endpoint so healthchecks pass first try. Deploying this instead of hand-porting the official template saves you every one of those integration failures.

## Common Use Cases

- A standalone REST API backend for a separately hosted web or mobile frontend.
- Internal tools and admin APIs needing ready-made JWT auth, superuser roles, and user management endpoints.
- Prototyping a SaaS API with database migrations and seeding already wired up.
- A reference implementation of FastAPI + SQLModel + MySQL on Railway, with a test suite to build on.

## Dependencies for

### Deployment Dependencies

- **MySQL** — provisioned by the template as a Railway database plugin service with a per-deployment generated root password (`secret()` expression); the backend creates its own database on boot and connects via a composed `DATABASE_URL` reference, so no database credentials are hardcoded or prompted.
- **Backend variables** — none are required at deploy time. `SECRET_KEY` is auto-generated per deployment; `FRONTEND_HOST` defaults to the generated domain (`${{RAILWAY_PUBLIC_DOMAIN}}`); `PROJECT_NAME`, `FIRST_SUPERUSER`, and `FIRST_SUPERUSER_PASSWORD` fall back to documented placeholders (`FastAPI MySQL Backend`, `admin@example.com`, `ChangeMeBeforeDeploy1`) — override them (ideally before the first deploy) for real use. Optional: `SENTRY_DSN`, `SMTP_HOST` / `SMTP_USER` / `SMTP_PASSWORD` / `EMAILS_FROM_EMAIL` for password-recovery emails. Do not set `FASTAPI_ENV`.
- **Dockerfile + railway.json** — the repo root contains the Dockerfile Railway builds from and `railway.json` with the builder, start command, and healthcheck configuration, so GitHub-triggered and CLI deploys behave identically.
