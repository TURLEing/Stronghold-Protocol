#!/usr/bin/env bash
# Run from a source checkout; no game art, GPU setup or training is performed.
set -euo pipefail
install=0
full=0
for arg in "$@"; do
  case "$arg" in
    --install) install=1 ;;
    --full) full=1 ;;
    --help|-h)
      printf '%s\n' 'Usage: bash scripts/verify-training-server.sh [--install] [--full]' \
        'Default: prerequisites, setup and regulation tests. Requires installed npm dependencies.' \
        '--install: run npm ci (replaces node_modules according to package-lock.json).' \
        '--full: also run complete CI, regulation golden, twice determinism and legacy golden, sequentially.' \
        'Logs: .cache/server-verification/<UTC timestamp>-<PID>. No system changes or game art downloads.'
      exit 0 ;;
    *) printf 'Unknown argument: %s\n' "$arg" >&2; exit 2 ;;
  esac
done
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$root"
for command in git node npm; do
  command -v "$command" >/dev/null || { printf 'Missing command: %s\n' "$command" >&2; exit 2; }
done
if (( full )); then
  for command in python3 zip unzip; do
    command -v "$command" >/dev/null || { printf 'Full verification needs: %s\n' "$command" >&2; exit 2; }
  done
fi
node -e 'if (+process.versions.node.split(".")[0] < 22) { console.error("Node >=22 required; previously verified version: 24.13.1"); process.exit(2); }'
log_dir="$root/.cache/server-verification/$(date -u +%Y%m%dT%H%M%SZ)-$$"
mkdir -p "$log_dir"
{
  printf 'UTC: '; date -u +%FT%TZ
  printf 'Revision: '; git rev-parse HEAD
  printf 'Node: '; node --version
  printf 'npm: '; npm --version
  printf 'System: '; uname -srm
  printf 'Working tree:\n'; git status --short
} | tee "$log_dir/environment.log"
if (( install )); then
  npm ci --no-audit --no-fund 2>&1 | tee "$log_dir/install.log"
fi
if [[ ! -d node_modules ]]; then
  printf 'Dependencies missing. Run again with --install.\n' >&2
  exit 2
fi
# Avoid inherited shard/browser switches silently changing the acceptance scope.
unset SHARD JUNIT
export SP_E2E=0 SP_REAL_E2E=0 RENDER_E2E=0 SIM_E2E=0 NO_COLOR=1
failed=0
run() {
  local label=$1
  shift
  printf '\n=== %s ===\n' "$label"
  if "$@" 2>&1 | tee "$log_dir/$label.log"; then
    printf 'PASS %s\n' "$label" >> "$log_dir/summary.txt"
  else
    printf 'FAIL %s\n' "$label" >> "$log_dir/summary.txt"
    failed=1
  fi
}
run setup node tools/setup.mjs --check --no-local --no-scenes
run regulation node --test test/versions-regulation.test.js test/match/bond-groups.test.js \
  test/match/version-equipment.test.js test/bands/regulation-*.test.js test/bonds/regulation.test.js \
  test/garrisons/regulation.test.js test/items/regulation.test.js test/kits/regulation-*.test.js \
  test/sim/regulation-enemies.test.js
if (( full )); then
  run ci node tools/ci.mjs --keep-going
  run regulation-golden node tools/golden.mjs --version act3autochess@V3_1
  run regulation-determinism node tools/golden.mjs --version act3autochess@V3_1 --twice
  run legacy-golden node tools/golden.mjs
fi
printf '\nLogs: %s\n' "$log_dir"
cat "$log_dir/summary.txt"
exit "$failed"
