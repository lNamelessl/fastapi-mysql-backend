FROM python:3.14

ENV PYTHONUNBUFFERED=1

# Install uv
# Ref: https://docs.astral.sh/uv/guides/integration/docker/#installing-uv
COPY --from=ghcr.io/astral-sh/uv:0.9.26 /uv /uvx /bin/

# Compile bytecode
# Ref: https://docs.astral.sh/uv/guides/integration/docker/#compiling-bytecode
ENV UV_COMPILE_BYTECODE=1

# uv Cache
# Ref: https://docs.astral.sh/uv/guides/integration/docker/#caching
ENV UV_LINK_MODE=copy

WORKDIR /app/

# Place executables in the environment at the front of the path
# Ref: https://docs.astral.sh/uv/guides/integration/docker/#using-the-environment
ENV PATH="/app/.venv/bin:$PATH"

# Install dependencies. Plain COPY + RUN layers: Railway's Metal builder
# rejects BuildKit bind/cache mounts (`dockerfile invalid: missing a
# type=cache argument`), so the upstream `RUN --mount=...` form can't be used.
# Ref: https://docs.astral.sh/uv/guides/integration/docker/#intermediate-layers
COPY uv.lock pyproject.toml /app/
COPY backend/pyproject.toml /app/backend/pyproject.toml

RUN uv sync --frozen --no-install-workspace --package app

COPY ./backend/scripts /app/backend/scripts

COPY ./backend/pyproject.toml ./backend/alembic.ini /app/backend/

COPY ./backend/app /app/backend/app

# Sync the project (installs the app package itself)
# Ref: https://docs.astral.sh/uv/guides/integration/docker/#intermediate-layers
RUN uv sync --frozen --package app

WORKDIR /app/backend/

# Migrations and seed data must run inside the container start: Railway
# ignores preDeployCommand on its Metal/CLI pipeline. ${PORT:-8000} binds to
# Railway's dynamically assigned port in deployment, 8000 locally.
CMD ["sh", "-c", "bash scripts/prestart.sh && exec fastapi run --host 0.0.0.0 --port ${PORT:-8000} --workers 4"]
