# 🚀 Launch Guide — Odoo 20.0 (this repository)

This repo is a fork of **Odoo 20.0 Community Edition** (open-source ERP/CRM:
Sales, Accounting, Inventory, Manufacturing, Website/eCommerce, POS, HR, … —
642 apps in `addons/`). Odoo is a **Python server + PostgreSQL database**;
you use it from your web browser. There is no single file to double-click.

> ✅ **This setup has been run and verified end-to-end** (Python 3.12 +
> PostgreSQL 16): database initialization with `base,web` succeeds,
> `GET /web/login` returns **HTTP 200**, and logging in as `admin` works.
> A GitHub Actions workflow (`.github/workflows/docker-smoke-test.yml`)
> repeats the same check inside real Docker on every change to the
> Docker files. Details in [What was tested](#what-was-tested).

---

## TL;DR — launch in 3 commands (Docker, recommended)

Requires [Docker](https://docs.docker.com/get-docker/) with Compose v2
(Docker Desktop on Windows/macOS, Docker Engine on Linux).

```bash
git clone -b 20.0 https://github.com/hnmodeq/odoo.git
cd odoo
docker compose up --build -d        # first build: ~5–15 min, then seconds
docker compose logs -f web          # wait for: HTTP service running on 0.0.0.0:8069
```

Then open **http://localhost:8069** and create your first database:

| Field on the creation screen | What to enter |
|---|---|
| **Master Password** | `admin` (default — comes from `ADMIN_PASSWORD`, change it in `.env`) |
| **Database Name** | e.g. `mycompany` (lowercase letters/numbers/underscore) |
| **Email** | your e-mail — this becomes your **login username** |
| **Password** | a password **you invent now** — this becomes your login password |
| Demo data | check it if you just want to explore with sample data |

After creation you land in Odoo logged in as administrator. Install apps
(CRM, Sales, Accounting, Inventory, …) from the **Apps** menu. Done 🎉

> 💡 Already have a database and get a login screen instead? Log in with
> the e-mail/password you chose at creation time. On a database created
> with `make init-demo` / `-i base` from the command line (no creation
> screen), the built-in administrator is **`admin` / `admin`**.

---

## Which method should I use?

| Method | Command | Runs *this* code? | Best for |
|---|---|---|---|
| **1. Docker (build)** | `docker compose up --build -d` | ✅ exact checkout | **Recommended.** Using & developing this fork |
| **2. Docker (quick look)** | `docker compose -f docker-compose.try.yml up -d` | ❌ official `odoo:20.0` image | Seeing Odoo in 2 min, no build |
| **3. From source** | `./odoo-bin -c odoo.conf` | ✅ exact checkout | Linux/WSL2 development without Docker |

---

## Method 1 — Docker, built from this source (recommended)

### What you get

```
Browser ──► http://localhost:8069 ──► web  (this repo, Python 3.12)
                                          │  odoo-bin, config generated
                                          │  from .env by entrypoint
                                          ▼
                                       db   (PostgreSQL 16)
        volumes: odoo20-web-data (filestore) · odoo20-db-data (database)
```

Files involved: `Dockerfile`, `docker-compose.yml`, `docker/entrypoint.sh`,
`docker/wait-for-psql.py`, `.env.example`, `.dockerignore`, `Makefile`.

### Steps

1. **(Optional) set your own passwords** — defaults work out of the box,
   but change them for anything real:
   ```bash
   cp .env.example .env     # then edit DB_PASSWORD / ADMIN_PASSWORD
   ```
   ⚠️ Do this **before the first start**. PostgreSQL only applies
   `POSTGRES_USER/PASSWORD` when the data volume is first created;
   changing them later causes *"password authentication failed"*
   (= "Internal Server Error" in the browser). Fix: change them back,
   or reset with `docker compose down -v` (**deletes all data**).

2. **Build & start:**
   ```bash
   docker compose up --build -d
   docker compose ps          # web and db should become (healthy)
   docker compose logs -f web # Ctrl+C stops following, not the server
   ```
   The first build downloads base images and installs ~70 Python
   packages (several minutes, ~3–4 GB disk). Later starts take seconds.

3. **Open http://localhost:8069** and create your database as in the
   TL;DR table above.

4. **Optional shortcut** — create a ready-made database from the CLI
   instead of the browser form:
   ```bash
   make init-demo                    # or, without make:
   docker compose run --rm web odoo -d demo -i base,web,crm,sale_management --without-demo=all --stop-after-init
   docker compose up -d web
   ```
   Then log in at http://localhost:8069 with **`admin` / `admin`**
   and change that password immediately (top-right avatar → My Profile).

### Daily commands

```bash
docker compose up -d                 # start
docker compose down                  # stop (data kept in volumes)
docker compose logs -f web           # server logs  ← first stop when anything is wrong
docker compose logs -f db            # database logs
docker compose ps                    # status / health
docker compose restart web           # restart Odoo only
docker compose up --build -d         # rebuild after changing dependencies/Dockerfile
docker compose exec web bash         # shell inside the Odoo container
docker compose exec db psql -U odoo postgres   # SQL shell
```

On Linux/macOS, `Makefile` wraps the common ones (`make up`, `make logs`,
`make down`, `make reset`, `make init-demo` …).

### Your own modules

Put custom addons in a folder `addons_custom/` next to
`docker-compose.yml`, uncomment the `./addons_custom:/mnt/extra-addons:ro`
line in `docker-compose.yml`, restart (`docker compose up -d`), then
**Apps → Update Apps List** in Odoo (developer mode).

### Backup / restore

* **Easiest:** http://localhost:8069/web/database/manager → *Backup*
  (master password required). Restore from the same screen.
* **Volume-level:** `docker compose down` then back up the volumes
  `odoo20-db-data` + `odoo20-web-data` **together** (database and
  filestore must stay in sync).

---

## Method 2 — Quick look with the official image (no build)

```bash
docker compose -f docker-compose.try.yml up -d
docker compose -f docker-compose.try.yml logs -f web
```

Open http://localhost:8069 and create a database exactly as above.
This uses the official **`odoo:20.0`** image from Docker Hub — same
Odoo version as this repo, but the code in your checkout is *not* used.
Stop it with `docker compose -f docker-compose.try.yml down`.
Don't run Method 1 and 2 at the same time (both want port 8069).

---

## Method 3 — From source, no Docker (Ubuntu 24.04 / WSL2)

> **Windows:** run this inside **WSL2 (Ubuntu)** or use Method 1.
> Native Windows is not a supported Odoo dev setup.
>
> **Python must be ≥ 3.12** (`odoo/release.py: MIN_PY_VERSION = (3, 12)`;
> the code uses 3.12-only syntax — Python 3.11 will fail with
> `SyntaxError`).

```bash
# 1) System packages + PostgreSQL
sudo apt update
sudo apt install -y postgresql python3.12 python3.12-venv python3-pip \
  build-essential libpq-dev libxml2-dev libxslt1-dev libldap2-dev \
  libsasl2-dev libjpeg-dev libffi-dev libssl-dev libmagic1 \
  wkhtmltopdf nodejs npm git
#    libldap2-dev is required: python-ldap has no wheel and compiles
#    against lber.h. Without it pip install fails.

# 2) PostgreSQL user for Odoo
sudo -u postgres psql -c "CREATE USER odoo WITH PASSWORD 'odoo' CREATEDB;"

# 3) Code + Python environment
git clone -b 20.0 https://github.com/hnmodeq/odoo.git
cd odoo
python3.12 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

# 4a) First run — plain flags (mind the UNDERSCORES: --db_password)
./odoo-bin --addons-path=addons -d demo \
  --db_host=localhost --db_port=5432 \
  --db_user=odoo --db_password=odoo \
  --http-port=8069

# 4b) …or save the flags once and start with a config file
cp odoo.conf.example odoo.conf      # adapt if needed
./odoo-bin -c odoo.conf
```

Open **http://localhost:8069**, create your database (or log in to the
`-d demo` database created in 4a with `admin`/`admin`), install apps.

Useful variants:

```bash
# install apps into an existing DB from the CLI, then exit
./odoo-bin -c odoo.conf -d demo -i crm,sale_management --stop-after-init
# update modules after pulling new code
./odoo-bin -c odoo.conf -d demo -u all --stop-after-init
```

---

## Troubleshooting — "Internal Server Error" 😖

**Rule #1: the browser message tells you nothing. The logs tell you
everything.** Always look first:

```bash
docker compose logs --tail=100 web     # the real Python error is here
docker compose logs --tail=100 db
docker compose ps                      # is anything exited/unhealthy?
curl -I http://localhost:8069/web/login   # expect HTTP 200 (or 303)
```

| Symptom / log line | Cause | Fix |
|---|---|---|
| `psycopg2.OperationalError: password authentication failed for user "odoo"` → 500 in browser | DB password in `.env` ≠ password the **existing volume** was created with (PostgreSQL ignores `POSTGRES_PASSWORD` after first init) | Use the original password, **or** reset: `docker compose down -v && docker compose up -d` ⚠️ deletes data |
| `FATAL: role "odoo" does not exist` | Volume was created with a different `POSTGRES_USER` (usually re-used from another tutorial) | Same as above: align names or `down -v` and start fresh. (Our volumes are named `odoo20-*` to avoid this.) |
| db log: `database files are incompatible with server` / db keeps restarting | Volume created by another PostgreSQL **major version** (e.g. 13/15) now mounted into `postgres:16` | Pin the old major in `docker-compose.yml`, or `down -v` and re-create on PG16 |
| 500 / `connection to server … failed` right after `up`, works a minute later | Odoo started before PostgreSQL accepted connections | This setup prevents it (healthcheck + `wait-for-psql.py`). If you removed those, just `docker compose restart web` once db is healthy |
| Browser: *connection refused* / nothing answers on 8069 | Containers not running, still building/starting, or port 8069 taken by another program | `docker compose ps` + `docker compose logs web`; if the port is busy set `ODOO_PORT=8070` in `.env` and use http://localhost:8070 |
| 500 after switching image/version, errors about missing modules/registry | A database created by Odoo 18/19 opened with Odoo 20 (or vice versa) — databases are **not** compatible across major versions | Create a **new** database with the version you run; never point two major versions at one DB |
| `error: no such option: --db-password` (source install) | Hyphen instead of underscore | It's `--db_password` (also `--db_host`, `--db_user`, `--db_port`) |
| `fatal error: lber.h: No such file or directory` while `pip install` | `python-ldap` compiles from source and needs LDAP headers | `sudo apt install libldap2-dev libsasl2-dev` (already in the Dockerfile) |
| `SyntaxError` in `odoo/http/retrying.py` (source install) | Python < 3.12 | Install Python 3.12+ and recreate the venv |
| Database creation screen rejects the master password | Wrong *master* password (not your login password) | Default is `admin`, or your `ADMIN_PASSWORD` from `.env` |
| PDF reports look broken / wkhtmltopdf warning in logs | Missing/old `wkhtmltopdf` | Included in the Docker image; on source installs `sudo apt install wkhtmltopdf` |

**Nuclear option (start 100% fresh, deletes ALL Odoo data):**

```bash
docker compose down -v
docker compose -f docker-compose.try.yml down -v
docker compose up --build -d
```

Still stuck? Open an issue **with the output of
`docker compose logs --tail=200 web db`** — without logs, "Internal
Server Error" cannot be diagnosed.

---

## Production notes

The defaults above are for local use/development. Before exposing
Odoo to a network:

* Change **all** passwords (`DB_PASSWORD`, `ADMIN_PASSWORD`, admin login).
* Put a reverse proxy (Nginx/Traefik/Caddy) with HTTPS in front,
  set `PROXY_MODE=True` for the `web` service, and route
  `/websocket` to port 8072.
* Use multiple workers (`WORKERS=2` or more) instead of threaded mode,
  and give PostgreSQL real resources + regular backups.
* Restrict the database manager: set `list_db = False`
  (via a mounted config with `GENERATE_CONFIG=0`, see
  `docker/entrypoint.sh`) or block `/web/database/*` in the proxy.
* Pin versions you deploy; never reuse one database across major
  Odoo versions.

## What was tested

Verified live against this exact checkout
(`20.0`, commit `afbcf79d`) with Python 3.12.10 + PostgreSQL 16.2:

```
$ ./odoo-bin --version                     → Odoo Server 20.0
$ ./odoo-bin -d testdb -i base,web --without-demo=all --stop-after-init
                                           → 16 modules loaded, exit 0
$ curl -I http://localhost:8069/          → 303 → /odoo
$ curl http://localhost:8069/web/login    → HTTP 200, <title>Odoo</title>
$ POST /web/session/authenticate (admin)  → uid 2, server_version 20.0
```

The Docker build performs the same steps (Python 3.12 image →
system libs incl. `libldap2-dev` → `pip install -r requirements.txt`
→ this source), and `.github/workflows/docker-smoke-test.yml`
builds the image with Docker, initializes a database, starts the
stack and asserts that `/web/login` answers — so a broken launch
setup fails CI instead of failing on your machine.
