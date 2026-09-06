#! /usr/bin/env bash

set -e
set -x

# Create the database if it does not exist. The MySQL image only creates the
# initial database when MYSQL_DATABASE is set on the container, which template
# deployments omit — so create the database named in DATABASE_URL here,
# before migrations run against it.
python - <<'PY'
import os
from urllib.parse import urlparse, unquote

import pymysql

url = urlparse(os.environ["DATABASE_URL"])
name = url.path.lstrip("/")
conn = pymysql.connect(
    host=url.hostname,
    port=url.port or 3306,
    user=unquote(url.username or "root"),
    password=unquote(url.password or ""),
)
with conn.cursor() as cur:
    cur.execute(f"CREATE DATABASE IF NOT EXISTS `{name}`")
conn.commit()
conn.close()
print(f"database {name} ready")
PY

# Run migrations
alembic upgrade head

# Create initial data in DB
python app/initial_data.py
