# Coraza + Traefik + DVWA lab

```
01-traefik-coraza/      Traefik v3 + OWASP Coraza (CRS) WAF plugin, creates network waf-net
02-dvwa/                DVWA + MariaDB, routed via Traefik with the waf middleware
03-malicious-url-test/  curl script: benign vs malicious URLs
04-false-positive-exclusion/  scoped CRS exclusion + test (blocked -> allowed, rest still protected)
05-custom-policy/       custom block rules (path, user-agent, param) + test
common.sh               helpers: swaps config into 01/dynamic/waf.yml, restores base on exit
```

## Run
```bash
cd 01-traefik-coraza && docker compose up -d
cd ../02-dvwa        && docker compose up -d
cd ../03-malicious-url-test && ./test.sh
```
Browse: http://dvwa.localhost (first visit: /setup.php -> Create/Reset Database; login admin / password).
Traefik dashboard: http://localhost:8080

## Notes
- Set `SecRuleEngine DetectionOnly` in 01-traefik-coraza/dynamic/waf.yml to log instead of block.
- Blocked requests return 403; check `docker logs traefik` for matched CRS rule IDs.
- The plugin is fetched on first start; if Traefik fails to load it, verify the version tag
  at https://github.com/jcchavezs/coraza-http-wasm-traefik/releases and edit traefik.yml.
- Lab only: dashboard is insecure and DVWA is deliberately vulnerable. Don't expose to the internet.

## Tests 04 / 05
```bash
./04-false-positive-exclusion/test.sh
./05-custom-policy/test.sh
```
Each test applies the base config, shows the 'before' result, copies its own waf.yml over
01-traefik-coraza/dynamic/waf.yml, waits for Traefik to reload (RELOAD_WAIT, default 4s), shows the
'after' result, then restores 01-traefik-coraza/waf.base.yml. On Docker Desktop (Mac/Windows) file-change
detection can be slow: use e.g. `RELOAD_WAIT=10 ./04-.../test.sh`.
