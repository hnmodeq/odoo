# syntax=docker/dockerfile:1
#
# Dockerfile for THIS repository (Odoo 20.0 Community, from source).
#
# Why build from source instead of `image: odoo:20.0`?
#   The code inside the container is then guaranteed to be exactly the
#   code in this repo — no version mismatch between the image, your
#   checkout and your database (a classic cause of "Internal Server
#   Error" on the first page).
#
# Odoo 20 requires Python >= 3.12 (odoo/release.py: MIN_PY_VERSION)
# and the code uses 3.12-only syntax, so the base image is pinned
# to Python 3.12 on Debian 12 (Bookworm) — the platform the pins in
# requirements.txt target.

# ---------------------------------------------------------------- builder
FROM python:3.12-slim-bookworm AS builder

ENV PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PYTHONDONTWRITEBYTECODE=1

# Build-time system libraries.
# Most requirements ship manylinux wheels, but two do NOT and are
# compiled at install time:
#   * psycopg2     -> libpq-dev          (PostgreSQL client headers)
#   * python-ldap  -> libldap2-dev       (provides lber.h) + libsasl2-dev
# The rest are safety nets so a missing wheel never breaks the build.
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
        build-essential \
        libpq-dev \
        libldap2-dev \
        libsasl2-dev \
        libxml2-dev \
        libxslt1-dev \
        libjpeg-dev \
        libffi-dev \
        libssl-dev \
        zlib1g-dev \
 && rm -rf /var/lib/apt/lists/*

RUN python -m venv /opt/venv
ENV PATH=/opt/venv/bin:$PATH

WORKDIR /build
COPY requirements.txt ./
RUN pip install --no-cache-dir --upgrade pip \
 && pip install --no-cache-dir -r requirements.txt

# ---------------------------------------------------------------- runtime
FROM python:3.12-slim-bookworm AS runtime

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH=/opt/venv/bin:$PATH \
    ODOO_BIN=/opt/odoo/odoo-bin \
    ODOO_CONFIG=/tmp/odoo.conf \
    ADDONS_PATH=/opt/odoo/addons \
    DATA_DIR=/var/lib/odoo

# Runtime-only system libraries:
#   libpq5 / libldap-2.5-0 / libsasl2-2 -> psycopg2 + python-ldap at runtime
#   libmagic1                           -> python-magic (mimetype guessing)
#   wkhtmltopdf + fonts                 -> PDF reports
#   curl                                -> container healthcheck / debugging
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
        libpq5 \
        libldap-2.5-0 \
        libsasl2-2 \
        libxml2 \
        libxslt1.1 \
        libjpeg62-turbo \
        libmagic1 \
        wkhtmltopdf \
        fonts-dejavu-core \
        fonts-liberation \
        tzdata \
        curl \
 && rm -rf /var/lib/apt/lists/*

# Never run Odoo as root.
RUN useradd --create-home --home-dir /var/lib/odoo --shell /usr/sbin/nologin odoo \
 && mkdir -p /var/lib/odoo /mnt/extra-addons \
 && chown odoo:odoo /var/lib/odoo /mnt/extra-addons

COPY --from=builder /opt/venv /opt/venv

WORKDIR /opt/odoo
COPY --chown=odoo:odoo . /opt/odoo

COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh /opt/odoo/docker/entrypoint.sh /opt/odoo/odoo-bin

USER odoo
VOLUME ["/var/lib/odoo"]
EXPOSE 8069 8072

ENTRYPOINT ["/entrypoint.sh"]
CMD ["odoo"]
