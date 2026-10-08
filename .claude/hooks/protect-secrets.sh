#!/usr/bin/env bash
# Bloque l'accès de l'agent aux fichiers .env (sauf .env.example).
# Spec : docs/specs/002-hook-protect-secrets.md
# Exit 2 = action refusée, le message sur stderr est renvoyé à l'agent.
# Claude Code ne bloque qu'avec le code 2 : toute autre sortie laisserait passer l'action.
set -euo pipefail

# Fermeture en cas de panne : toute sortie autre que 0 ou 2 devient un refus
# Appelée par le trap, que shellcheck ne suit pas (SC2317 avant 0.11, SC2329 ensuite)
# shellcheck disable=SC2317,SC2329
fail_closed() {
  local code=$?
  if [ "$code" -ne 0 ] && [ "$code" -ne 2 ]; then
    echo "protect-secrets : erreur interne (code $code), action refusée par précaution." >&2
    exit 2
  fi
}
trap fail_closed EXIT

deny() {
  echo "protect-secrets : $1" >&2
  exit 2
}

command -v jq >/dev/null 2>&1 ||
  deny "jq n'est pas installé, action refusée. Installe jq pour rétablir les hooks de Claude Code."

input=$(cat)
[ -n "$input" ] || deny "entrée vide, action refusée."
jq -e 'type == "object"' >/dev/null 2>&1 <<<"$input" || deny "entrée JSON invalide, action refusée."

jq -e '.tool_name | type == "string" and length > 0' >/dev/null <<<"$input" ||
  deny "tool_name absent ou invalide, action refusée."
tool=$(jq -r '.tool_name' <<<"$input")
jq -e '.tool_input | type == "object"' >/dev/null <<<"$input" || deny "tool_input absent, action refusée."

case "$tool" in
  Bash)
    target=$(jq -r '.tool_input.command // empty' <<<"$input")
    [ -n "$target" ] || deny "commande Bash absente, action refusée."
    ;;
  Read | Edit | Write | MultiEdit)
    target=$(jq -r '.tool_input.file_path // empty' <<<"$input")
    [ -n "$target" ] || deny "chemin absent pour $tool, action refusée."
    ;;
  *)
    exit 0
    ;;
esac

# On retire .env.example, autorisé, avant de chercher un .env
cleaned="${target//.env.example/}"

# Regex de bash plutôt que grep : une commande externe manquante dans un « if »
# ne déclencherait ni set -e ni le trap, et laisserait passer l'action.
env_file='(^|[^[:alnum:]_])\.env([^[:alnum:]_-]|$)'
if [[ $cleaned =~ $env_file ]]; then
  echo "Refusé par la politique du projet : accès aux fichiers .env interdit. Utilise .env.example." >&2
  exit 2
fi

exit 0
