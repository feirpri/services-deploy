#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

PROFILES=()
COMPOSE_FILES=(-f docker-compose.yml)
ENV_FILE=".env"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --with-mihomo) PROFILES+=("mihomo"); shift ;;
    --env) [[ "$2" == "test" ]] && COMPOSE_FILES+=(-f docker-compose.test.yml); shift 2 ;;
    *) echo "unknown arg: $1"; exit 1 ;;
  esac
done

PROFILE_ARGS=()
for p in "${PROFILES[@]}"; do PROFILE_ARGS+=(--profile "$p"); done

docker compose --env-file "$ENV_FILE" "${COMPOSE_FILES[@]}" "${PROFILE_ARGS[@]}" pull
docker compose --env-file "$ENV_FILE" "${COMPOSE_FILES[@]}" "${PROFILE_ARGS[@]}" up -d
docker compose --env-file "$ENV_FILE" "${COMPOSE_FILES[@]}" ps
