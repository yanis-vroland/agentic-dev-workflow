#!/usr/bin/env bash
# Vérifie que le hook protect-secrets bloque les .env et laisse passer le reste.
set -u

hook=".claude/hooks/protect-secrets.sh"
fail=0

check() {
  local expected=$1 description=$2 input=$3
  echo "$input" | "$hook" >/dev/null 2>&1
  local code=$?
  if [ "$code" -eq "$expected" ]; then
    echo "OK     $description"
  else
    echo "ÉCHEC  $description (attendu $expected, obtenu $code)"
    fail=1
  fi
}

# Doit être bloqué (exit 2)
check 2 "Read .env"             '{"tool_name":"Read","tool_input":{"file_path":"/repo/.env"}}'
check 2 "Read .env.local"       '{"tool_name":"Read","tool_input":{"file_path":"/repo/.env.local"}}'
check 2 "Write .env.production" '{"tool_name":"Write","tool_input":{"file_path":"/repo/.env.production"}}'
check 2 "Bash cat .env"         '{"tool_name":"Bash","tool_input":{"command":"cat .env"}}'

# Doit passer (exit 0)
check 0 "Read .env.example"     '{"tool_name":"Read","tool_input":{"file_path":"/repo/.env.example"}}'
check 0 "Edit src/app.ts"       '{"tool_name":"Edit","tool_input":{"file_path":"/repo/src/app.ts"}}'
check 0 "Bash grep process.env" '{"tool_name":"Bash","tool_input":{"command":"grep -r process.env src"}}'
check 0 "Read .envrc"           '{"tool_name":"Read","tool_input":{"file_path":"/repo/.envrc"}}'

exit $fail
