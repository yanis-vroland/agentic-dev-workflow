#!/usr/bin/env bash
# Bloque l'accès de l'agent aux fichiers .env (sauf .env.example).
# Exit 2 = action refusée, le message sur stderr est renvoyé à l'agent.
set -euo pipefail

input=$(cat)
tool=$(jq -r '.tool_name' <<<"$input")

if [ "$tool" = "Bash" ]; then
  target=$(jq -r '.tool_input.command // ""' <<<"$input")
else
  target=$(jq -r '.tool_input.file_path // ""' <<<"$input")
fi

# On retire .env.example, autorisé, avant de chercher un .env
cleaned="${target//.env.example/}"

if grep -Eq '(^|[^[:alnum:]_])\.env([^[:alnum:]_-]|$)' <<<"$cleaned"; then
  echo "Refusé par la politique du projet : accès aux fichiers .env interdit. Utilise .env.example." >&2
  exit 2
fi

exit 0
