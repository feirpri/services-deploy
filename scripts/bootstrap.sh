#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

copy_if_missing() {
  local demo="$1"
  local target="${demo%-demo}"
  target="${target/.env-demo/.env}"
  if [[ -f "$target" ]]; then
    echo "skip  $target (exists)"
  else
    cp "$demo" "$target"
    echo "init  $target"
  fi
}

# 根 .env
[[ -f .env ]] || { cp .env-demo .env; echo "init  .env"; }

# 各子服务
find services -name '.env-demo' | while read -r f; do
  dir="$(dirname "$f")"
  if [[ -f "$dir/.env" ]]; then
    echo "skip  $dir/.env (exists)"
  else
    cp "$f" "$dir/.env"
    echo "init  $dir/.env"
  fi
done

# 创建外部网络
NET="$(grep -E '^EDGE_NETWORK=' .env | cut -d= -f2)"
NET="${NET:-edge}"
docker network inspect "$NET" >/dev/null 2>&1 || docker network create "$NET"
echo "done. 请编辑各 .env 文件后执行 ./scripts/up.sh"
