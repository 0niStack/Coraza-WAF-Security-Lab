#!/usr/bin/env bash
source "$(dirname "$0")/../common.sh"
trap restore EXIT
XSS='%3Cscript%3Ealert(1)%3C/script%3E'
SQLI='1%27%20OR%20%271%27=%271'

echo "=== BEFORE exclusion (base config) ==="
apply "$BASE"
expect_block "xss_r  <script> (false positive)" "$URL/vulnerabilities/xss_r/?name=$XSS"

echo; echo "=== AFTER exclusion (04 config) ==="
apply "$(dirname "$0")/waf.yml"
expect_pass  "xss_r  <script> now allowed"        "$URL/vulnerabilities/xss_r/?name=$XSS"
expect_block "xss_s  <script> still blocked"      "$URL/vulnerabilities/xss_s/?name=$XSS"
expect_block "xss_r  SQLi still blocked"          "$URL/vulnerabilities/xss_r/?name=$SQLI"
expect_block "sqli page still blocked"            "$URL/vulnerabilities/sqli/?id=$SQLI&Submit=Submit"
summary
