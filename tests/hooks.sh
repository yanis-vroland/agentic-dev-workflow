#!/usr/bin/env bash
# Vérifie le hook protect-secrets selon la spec docs/specs/002-hook-protect-secrets.md.
set -u

hook="$(cd "$(dirname "$0")/.." && pwd)/.claude/hooks/protect-secrets.sh"
fail=0

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

# Sortie (stderr) du dernier lancement, pour vérifier un fragment du message
output=""

# check <code attendu> <description> <entrée> [PATH]
check() {
  local expected=$1 description=$2 input=$3 path=${4:-$PATH}
  output=$(printf '%s' "$input" | PATH="$path" "$hook" 2>&1 >/dev/null)
  local code=$?
  if [ "$code" -eq "$expected" ]; then
    echo "OK     $description"
  else
    echo "ÉCHEC  $description (attendu $expected, obtenu $code)"
    fail=1
  fi
}

# --- Comportement actuel conservé -------------------------------------------

# Doit être bloqué (exit 2)
check 2 "CA1 : Read .env"             '{"tool_name":"Read","tool_input":{"file_path":"/repo/.env"}}'
check 2 "CA2 : Read .env.local"       '{"tool_name":"Read","tool_input":{"file_path":"/repo/.env.local"}}'
check 2 "CA3 : Write .env.production" '{"tool_name":"Write","tool_input":{"file_path":"/repo/.env.production"}}'
check 2 "CA4 : Bash cat .env"         '{"tool_name":"Bash","tool_input":{"command":"cat .env"}}'

# Doit passer (exit 0)
check 0 "CA5 : Read .env.example"     '{"tool_name":"Read","tool_input":{"file_path":"/repo/.env.example"}}'
check 0 "CA6 : Edit src/app.ts"       '{"tool_name":"Edit","tool_input":{"file_path":"/repo/src/app.ts"}}'
check 0 "CA7 : Bash grep process.env" '{"tool_name":"Bash","tool_input":{"command":"grep -r process.env src"}}'
check 0 "CA8 : Read .envrc"           '{"tool_name":"Read","tool_input":{"file_path":"/repo/.envrc"}}'

# --- Fermeture en cas de panne (#7) -----------------------------------------

# PATH réduit aux seuls binaires dont le hook a besoin, sans jq. Retirer /usr/bin
# du PATH ne convient pas : sur Ubuntu, jq y côtoie bash et cat.
no_jq="$work/bin"
mkdir "$no_jq"
for cmd in bash cat; do
  ln -s "$(command -v "$cmd")" "$no_jq/$cmd"
done
check 2 "CA9 : jq absent : refus" \
  '{"tool_name":"Read","tool_input":{"file_path":"/repo/src/app.ts"}}' "$no_jq"
if grep -q "jq" <<<"$output"; then
  echo "OK     CA9 : jq absent : message cite jq"
else
  echo "ÉCHEC  CA9 : jq absent : message sans jq (sortie : $output)"
  fail=1
fi

check 2 "CA10 : JSON invalide"           'pas du json {'
check 2 "CA11 : entrée vide"             ''
check 2 "CA12 : tool_name absent"        '{"tool_input":{"file_path":"/repo/src/app.ts"}}'
check 2 "CA13 : tool_input absent"       '{"tool_name":"Read"}'
check 2 "CA12 : tool_name non textuel"   '{"tool_name":5,"tool_input":{"file_path":"/repo/src/app.ts"}}'
check 2 "CA14 : Read sans file_path"     '{"tool_name":"Read","tool_input":{}}'
check 2 "CA14 : Edit sans file_path"     '{"tool_name":"Edit","tool_input":{}}'
check 2 "CA14 : Write sans file_path"    '{"tool_name":"Write","tool_input":{}}'
check 2 "CA14 : MultiEdit sans file_path" '{"tool_name":"MultiEdit","tool_input":{}}'
check 2 "Règle 2 : MultiEdit .env"       '{"tool_name":"MultiEdit","tool_input":{"file_path":"/repo/.env"}}'
check 0 "Règle 4 : autre outil autorisé" '{"tool_name":"Grep","tool_input":{}}'
check 2 "CA15 : Bash sans command"       '{"tool_name":"Bash","tool_input":{}}'

# CA16 : une erreur interne ne doit jamais laisser passer. Les cas testés
# couvrent les commandes externes manquantes (jq en CA9, cat ici) et des entrées
# hors contrat (CA10 à CA15, tool_name non textuel). Limite : une erreur de
# set -u ou un échec de jq après la validation ne peuvent pas être provoqués
# de l'extérieur ; seul le trap EXIT du hook les couvre (vérifié par mutation :
# sans le trap, le cas ci-dessous sort en 127).
no_cat="$work/bin-sans-cat"
mkdir "$no_cat"
for cmd in bash jq; do
  ln -s "$(command -v "$cmd")" "$no_cat/$cmd"
done
check 2 "CA16 : cat absent : refus" \
  '{"tool_name":"Read","tool_input":{"file_path":"/repo/src/app.ts"}}' "$no_cat"

exit $fail
