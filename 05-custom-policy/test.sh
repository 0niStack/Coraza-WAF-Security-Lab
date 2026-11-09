#!/usr/bin/env bash
source "$(dirname "$0")/../common.sh"
trap restore EXIT

echo "=== BEFORE custom policy (base config) ==="
apply "$BASE"
expect_pass  "/secret-admin allowed (404 ok)"   "$URL/secret-admin"
expect_pass  "BadBot UA allowed"                -A "BadBot/1.0" "$URL/"
expect_pass  "?debug=true allowed"              "$URL/?debug=true"

echo; echo "=== AFTER custom policy (05 config) ==="
apply "$(dirname "$0")/waf.yml"
expect_block "/secret-admin blocked"            "$URL/secret-admin"
expect_block "BadBot UA blocked"                -A "BadBot/1.0" "$URL/"
expect_block "?debug=true blocked"              "$URL/?debug=true"
expect_pass  "control: /other-path allowed"     "$URL/other-path"
expect_pass  "control: normal UA allowed"       -A "Mozilla/5.0" "$URL/"
expect_pass  "control: ?debug=false allowed"    "$URL/?debug=false"
expect_block "CRS still on: SQLi blocked"       "$URL/vulnerabilities/sqli/?id=1%27%20OR%20%271%27=%271&Submit=Submit"
summary
