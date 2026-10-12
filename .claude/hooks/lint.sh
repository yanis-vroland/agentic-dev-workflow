#!/usr/bin/env bash
# Après chaque modification de l'agent : formate le fichier (format.sh), le passe au
# lint déclaré dans .claude/quality.json, et marque les tests « à lancer » pour la fin
# du tour (run-tests.sh). Spec 006.
#
# Codes de sortie : 0 (rien à signaler, ou avertissement JSON pour l'humain),
# 2 (lint en échec, sortie transmise à l'agent), 1 (erreur interne, non bloquante).
set -u

max_lines=50

if ! command -v jq >/dev/null 2>&1; then
  echo "lint : jq est introuvable, lint non lancé." >&2
  exit 1
fi

input=$(cat)
file=$(jq -r '.tool_input.file_path // empty' <<<"$input" 2>/dev/null)
session=$(jq -r '.session_id // empty' <<<"$input" 2>/dev/null)
[ -z "$file" ] && exit 0

project=$(cd "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null && pwd -P) || exit 0

# Chemin absolu et physique du fichier ; rien à faire s'il est hors du projet
case "$file" in
  /*) ;;
  *) file="$project/$file" ;;
esac
dir=$(cd "$(dirname "$file")" 2>/dev/null && pwd -P) || exit 0
file="$dir/$(basename "$file")"
case "$file" in
  "$project"/*) ;;
  *) exit 0 ;;
esac

# 1. Formatage, avant le lint : les hooks d'un même événement tournent en parallèle
printf '%s' "$input" | CLAUDE_PROJECT_DIR="$project" "$(dirname "$0")/format.sh" >/dev/null 2>&1

# 2. Marque « à lancer », propre à la session et au worktree, hors de l'arbre de travail
# shellcheck source=.claude/hooks/quality-common.sh
. "$(dirname "$0")/quality-common.sh"
if marker=$(pending_marker "$project" "$session"); then
  mkdir -p "$(dirname "$marker")" && : >"$marker"
fi

# 3. Lint
config="$project/.claude/quality.json"
[ -f "$config" ] || exit 0
if ! lint_cmd=$(jq -er '.lint // ""' "$config" 2>/dev/null); then
  echo "lint : .claude/quality.json est invalide (JSON attendu, clés lint et test)." >&2
  exit 1
fi
[ -z "$lint_cmd" ] && exit 0

cd "$project" || exit 1
read -r first _ <<<"$lint_cmd"
if ! command -v "$first" >/dev/null 2>&1; then
  jq -nc --arg c "$first" \
    '{systemMessage: ("lint : commande introuvable « " + $c + " » (.claude/quality.json), lint non lancé.")}'
  exit 0
fi

# Le chemin est passé comme argument séparé, jamais interpolé dans la commande
output=$(bash -c "$lint_cmd \"\$@\"" lint "$file" 2>&1)
status=$?
if [ "$status" -ne 0 ]; then
  {
    echo "Lint en échec sur $file (code $status) :"
    tail -n "$max_lines" <<<"$output"
  } >&2
  exit 2
fi

exit 0
