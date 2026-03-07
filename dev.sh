#!/bin/sh
# dev.sh - Helper script for running dev commands in podman containers
# Usage: ./dev.sh <command> [args...]
#
# Commands:
#   build         - Build the TypeScript project
#   test          - Run unit tests
#   test:e2e      - Run e2e tests (PostgreSQL)
#   test:security - Run security tests (PostgreSQL)
#   lint          - Run linter
#   typecheck     - Run TypeScript type checking
#   check         - Run lint + typecheck + unit tests
#   install       - Run npm install (regenerates lockfile)
#   ci            - Run npm ci (strict lockfile install)
#   audit         - Run npm audit
#   shell         - Open interactive shell in container
#   run           - Run arbitrary npm command
#   exec          - Run arbitrary command in container
#   demo          - Start demo server (PostgreSQL + Express on port 3000)
#   demo:stop     - Stop demo server and database
#   db:seed       - Seed the demo database
#   db:psql       - Open psql shell to demo database

set -e

IMAGE="node:20-slim"
PG_IMAGE="postgres:17-alpine"
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
COMPOSE_PROJECT="odata-phrase"

# Container/network names
PG_CONTAINER="${COMPOSE_PROJECT}-postgres"
DEMO_CONTAINER="${COMPOSE_PROJECT}-demo"
PG_NETWORK="${COMPOSE_PROJECT}_default"

PG_USER="odata"
PG_PASSWORD="odata"
PG_DB="odata_test"

run_in_container() {
  podman run --rm \
    -v "${PROJECT_DIR}":/app \
    -w /app \
    -e NODE_ENV=test \
    "$IMAGE" \
    sh -c "$1"
}

# Run a command in a container connected to the postgres network
run_with_postgres() {
  podman run --rm \
    -v "${PROJECT_DIR}":/app \
    -w /app \
    --network "${PG_NETWORK}" \
    -e NODE_ENV=test \
    -e DB_DIALECT=postgres \
    -e DB_HOST="${PG_CONTAINER}" \
    -e DB_PORT=5432 \
    -e DB_NAME="${PG_DB}" \
    -e DB_USER="${PG_USER}" \
    -e DB_PASSWORD="${PG_PASSWORD}" \
    -e DB_SCHEMA=public \
    "$IMAGE" \
    sh -c "$1"
}

ensure_postgres() {
  # Create network if it doesn't exist
  podman network exists "${PG_NETWORK}" 2>/dev/null || podman network create "${PG_NETWORK}"

  # Start postgres if not running
  if ! podman ps --format '{{.Names}}' | grep -q "^${PG_CONTAINER}$"; then
    echo "Starting PostgreSQL..."
    # Remove stopped container if it exists
    podman rm -f "${PG_CONTAINER}" 2>/dev/null || true
    podman run -d \
      --name "${PG_CONTAINER}" \
      --network "${PG_NETWORK}" \
      -e POSTGRES_DB="${PG_DB}" \
      -e POSTGRES_USER="${PG_USER}" \
      -e POSTGRES_PASSWORD="${PG_PASSWORD}" \
      -p 5433:5432 \
      "${PG_IMAGE}"

    # Wait for postgres to be ready
    echo "Waiting for PostgreSQL to be ready..."
    for i in $(seq 1 30); do
      if podman exec "${PG_CONTAINER}" pg_isready -U "${PG_USER}" -d "${PG_DB}" >/dev/null 2>&1; then
        echo "PostgreSQL is ready."
        return
      fi
      sleep 1
    done
    echo "ERROR: PostgreSQL failed to start within 30 seconds"
    exit 1
  fi
}

stop_postgres() {
  podman rm -f "${PG_CONTAINER}" 2>/dev/null || true
}

seed_database() {
  echo "Setting up database (schema + seed data)..."
  podman exec -i "${PG_CONTAINER}" psql -U "${PG_USER}" -d "${PG_DB}" < "${PROJECT_DIR}/examples/express-app/demo-setup.sql"
  echo "Database ready."
}

case "${1:-help}" in
  build)
    run_in_container "npm ci && npm run build"
    ;;
  test)
    run_in_container "npm ci && npm run test:unit"
    ;;
  test:e2e)
    ensure_postgres
    run_with_postgres "npm ci && npm run test:e2e"
    ;;
  test:security)
    ensure_postgres
    run_with_postgres "npm ci && npm run test:security"
    ;;
  lint)
    run_in_container "npm ci && npm run lint"
    ;;
  typecheck)
    run_in_container "npm ci && npm run typecheck"
    ;;
  check)
    run_in_container "npm ci && npm run check"
    ;;
  install)
    run_in_container "npm install"
    ;;
  ci)
    run_in_container "npm ci"
    ;;
  audit)
    run_in_container "npm ci && npm audit"
    ;;
  shell)
    podman run --rm -it \
      -v "${PROJECT_DIR}":/app \
      -w /app \
      -e NODE_ENV=test \
      "$IMAGE" \
      bash
    ;;
  run)
    shift
    run_in_container "npm ci && npm run $*"
    ;;
  exec)
    shift
    run_in_container "npm ci 2>/dev/null && $*"
    ;;
  exec-raw)
    shift
    run_in_container "$*"
    ;;
  demo)
    ensure_postgres
    seed_database

    # Stop existing demo container if running
    podman rm -f "${DEMO_CONTAINER}" 2>/dev/null || true

    echo ""
    echo "Starting OData demo server on http://localhost:3000"
    echo ""
    echo "  Excel/Power Query OData feed URL:  http://localhost:3000/CustomUser"
    echo "  Metadata:                          http://localhost:3000/\$metadata"
    echo ""
    echo "  Available endpoints:"
    echo "    /CustomUser        - Users with departments, notes, categories"
    echo "    /Department        - Departments with users and showcases"
    echo "    /Note              - Notes with user, category, and tags"
    echo "    /Category          - Categories with creator and notes"
    echo "    /Tag               - Tags with note-tag links"
    echo "    /Role              - Roles with role-permission links"
    echo "    /Permission        - Permissions with role-permission links"
    echo "    /DataTypeShowcase  - Every supported data type + department relation"
    echo "    /NoteTag           - Note-tag junction (note + tag relations)"
    echo "    /RolePermission    - Role-permission junction (role + permission relations)"
    echo "    /UserRole          - User-role mappings (query model)"
    echo ""
    echo "  Example queries:"
    echo "    http://localhost:3000/CustomUser?\$select=username,email,fullName&\$filter=isActive eq true"
    echo "    http://localhost:3000/Note?\$expand=user,category&\$top=5"
    echo "    http://localhost:3000/Department?\$expand=users"
    echo "    http://localhost:3000/CustomUser?\$expand=myDepartment,notes,categories"
    echo ""
    echo "Press Ctrl+C to stop."
    echo ""

    podman run --rm \
      --name "${DEMO_CONTAINER}" \
      --network "${PG_NETWORK}" \
      -v "${PROJECT_DIR}":/app \
      -w /app \
      -p 3000:3000 \
      -e NODE_ENV=development \
      -e DB_DIALECT=postgres \
      -e DB_HOST="${PG_CONTAINER}" \
      -e DB_PORT=5432 \
      -e DB_NAME="${PG_DB}" \
      -e DB_USER="${PG_USER}" \
      -e DB_PASSWORD="${PG_PASSWORD}" \
      -e DB_SCHEMA=public \
      -e port=3000 \
      "$IMAGE" \
      sh -c "npm ci 2>/dev/null && npx ts-node examples/express-app/server.ts"
    ;;
  demo:stop)
    echo "Stopping demo..."
    podman rm -f "${DEMO_CONTAINER}" 2>/dev/null || true
    stop_postgres
    echo "Demo stopped."
    ;;
  db:seed)
    ensure_postgres
    seed_database
    ;;
  db:psql)
    ensure_postgres
    podman exec -it "${PG_CONTAINER}" psql -U "${PG_USER}" -d "${PG_DB}"
    ;;
  help|*)
    echo "Usage: ./dev.sh <command>"
    echo ""
    echo "Commands:"
    echo "  build           Build the TypeScript project"
    echo "  test            Run unit tests"
    echo "  test:e2e        Run e2e tests (PostgreSQL)"
    echo "  test:security   Run security tests (PostgreSQL)"
    echo "  lint            Run linter"
    echo "  typecheck       Run TypeScript type checking"
    echo "  check           Run lint + typecheck + unit tests"
    echo "  install         Run npm install (regenerates lockfile)"
    echo "  ci              Run npm ci (strict lockfile install)"
    echo "  audit           Run npm audit"
    echo "  shell           Open interactive shell in container"
    echo "  run <script>    Run arbitrary npm script"
    echo "  exec <cmd>      Run arbitrary command in container"
    echo ""
    echo "  demo            Start demo server (PostgreSQL + Express on :3000)"
    echo "  demo:stop       Stop demo server and PostgreSQL"
    echo "  db:seed         (Re)seed the demo database"
    echo "  db:psql         Open psql shell to demo database"
    ;;
esac
