#!/usr/bin/env python3
"""Wait until PostgreSQL accepts a connection, then exit 0.

Used by docker/entrypoint.sh so Odoo never starts before the
database is really ready. ``depends_on`` alone only waits for the
container to exist — not for PostgreSQL to accept connections —
and starting Odoo too early shows up in the browser as
"Internal Server Error".

Connection settings are read from the environment:
    DB_HOST (default: db), DB_PORT (default: 5432),
    DB_USER (default: odoo), DB_PASSWORD (default: odoo)
Timeout: DB_WAIT_TIMEOUT seconds (default: 120).
"""
import os
import sys
import time

def main() -> int:
    import psycopg2

    host = os.environ.get("DB_HOST", "db")
    port = int(os.environ.get("DB_PORT", "5432"))
    user = os.environ.get("DB_USER", "odoo")
    password = os.environ.get("DB_PASSWORD", "odoo")
    timeout = float(os.environ.get("DB_WAIT_TIMEOUT", "120"))

    deadline = time.time() + timeout
    attempt = 0
    while True:
        attempt += 1
        try:
            conn = psycopg2.connect(
                dbname="postgres",
                host=host,
                port=port,
                user=user,
                password=password,
                connect_timeout=3,
            )
            conn.close()
            print(f"wait-for-psql: PostgreSQL at {host}:{port} is ready "
                  f"(attempt {attempt}).", flush=True)
            return 0
        except Exception as exc:  # psycopg2.OperationalError and friends
            if time.time() >= deadline:
                print(f"wait-for-psql: giving up after {timeout:.0f}s — "
                      f"cannot connect to PostgreSQL at {host}:{port} "
                      f"as user '{user}': {exc}", file=sys.stderr, flush=True)
                print("wait-for-psql: check that DB_USER/DB_PASSWORD match "
                      "the POSTGRES_USER/POSTGRES_PASSWORD the database "
                      "volume was FIRST created with (changing them later "
                      "in .env does not change an existing volume).",
                      file=sys.stderr, flush=True)
                return 1
            print(f"wait-for-psql: PostgreSQL at {host}:{port} not ready "
                  f"yet (attempt {attempt}) — retrying in 2s...",
                  flush=True)
            time.sleep(2)

if __name__ == "__main__":
    sys.exit(main())
