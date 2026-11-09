# Shared helpers for tests 04 and 05
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIVE="$ROOT/01-traefik-coraza/dynamic/waf.yml"        # file Traefik watches
BASE="$ROOT/01-traefik-coraza/waf.base.yml"           # pristine config
HOST="${HOST:-dvwa.localhost}"
URL="${URL:-http://localhost}"
RELOAD_WAIT="${RELOAD_WAIT:-4}"                        # seconds for Traefik to reload
pass=0; fail=0

apply()   { echo ">> applying $(basename "$(dirname "$1")")/$(basename "$1")"; cp "$1" "$LIVE"; sleep "$RELOAD_WAIT"; }
restore() { cp "$BASE" "$LIVE"; sleep "$RELOAD_WAIT"; echo ">> restored base config"; }
code()    { curl -s -o /dev/null -w '%{http_code}' -H "Host: $HOST" "$@"; }

# expect_block "name" curl-args...   -> 403 expected
# expect_pass  "name" curl-args...   -> anything except 403 (WAF let it through)
expect_block() { local n="$1"; shift; local c; c=$(code "$@")
  if [[ "$c" == 403 ]]; then printf "PASS  %-34s blocked (403)\n" "$n"; ((pass++))
  else printf "FAIL  %-34s expected 403, got %s\n" "$n" "$c"; ((fail++)); fi; }
expect_pass()  { local n="$1"; shift; local c; c=$(code "$@")
  if [[ "$c" != 403 && "$c" != 000 ]]; then printf "PASS  %-34s allowed (%s)\n" "$n" "$c"; ((pass++))
  else printf "FAIL  %-34s expected not-403, got %s\n" "$n" "$c"; ((fail++)); fi; }
summary() { echo; echo "Passed: $pass  Failed: $fail"; [[ $fail -eq 0 ]]; }
