#!/bin/sh
# dev.sh - Helper script for running dev commands in podman containers
# Usage: ./dev.sh <command> [args...]
#
# Commands:
#   build       - Build the TypeScript project
#   test        - Run unit tests
#   test:e2e    - Run e2e tests
#   test:security - Run security tests
#   lint        - Run linter
#   typecheck   - Run TypeScript type checking
#   check       - Run lint + typecheck + unit tests
#   install     - Run npm install (regenerates lockfile)
#   ci          - Run npm ci (strict lockfile install)
#   audit       - Run npm audit
#   shell       - Open interactive shell in container
#   run         - Run arbitrary npm command, e.g. ./dev.sh run test:unit
#   exec        - Run arbitrary command in container, e.g. ./dev.sh exec node -e "..."

set -e

IMAGE="node:20-slim"
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"

run_in_container() {
  podman run --rm \
    -v "${PROJECT_DIR}":/app \
    -w /app \
    -e NODE_ENV=test \
    "$IMAGE" \
    sh -c "$1"
}

case "${1:-help}" in
  build)
    run_in_container "npm ci && npm run build"
    ;;
  test)
    run_in_container "npm ci && npm run test:unit"
    ;;
  test:e2e)
    run_in_container "npm ci && npm run test:e2e"
    ;;
  test:security)
    run_in_container "npm ci && npm run test:security"
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
  help|*)
    echo "Usage: ./dev.sh <command>"
    echo ""
    echo "Commands:"
    echo "  build         Build the TypeScript project"
    echo "  test          Run unit tests"
    echo "  test:e2e      Run e2e tests"
    echo "  test:security Run security tests"
    echo "  lint          Run linter"
    echo "  typecheck     Run TypeScript type checking"
    echo "  check         Run lint + typecheck + unit tests"
    echo "  install       Run npm install (regenerates lockfile)"
    echo "  ci            Run npm ci (strict lockfile install)"
    echo "  audit         Run npm audit"
    echo "  shell         Open interactive shell in container"
    echo "  run <script>  Run arbitrary npm script"
    echo "  exec <cmd>    Run arbitrary command in container"
    ;;
esac
