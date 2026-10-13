#!/usr/bin/env bash
# Vérifie le hook restrict-learnings du subagent learning-curator selon la spec
# https://github.com/yanis-vroland/agentic-dev-workflow/blob/main/docs/specs/005-capitalisation-des-pieges.md
# (section « Subagent learning-curator », CA15 à CA20).
set -u

hook="$(cd "$(dirname "$0")/.." && pwd)/.claude/hooks/restrict-learnings.sh"
fail=0

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

project="$work/projet"
mkdir -p "$project/docs/learnings"

# Sortie (stderr) du dernier lancement, pour vérifier un fragment du message
output=""

# check <code attendu> <description> <entrée> [PATH] [CLAUDE_PROJECT_DIR]
check() {
  local expected=$1 description=$2 input=$3 path=${4:-$PATH} dir=${5-$project}
  output=$(printf '%s' "$input" | PATH="$path" CLAUDE_PROJECT_DIR="$dir" "$hook" 2>&1 >/dev/null)
  local code=$?
  if [ "$code" -eq "$expected" ]; then
    echo "OK     $description"
  else
    echo "ÉCHEC  $description (attendu $expected, obtenu $code)"
    fail=1
  fi
}

# input <outil> <chemin> : entrée JSON d'un appel d'outil sur un fichier
input() {
  printf '{"tool_name":"%s","tool_input":{"file_path":"%s"}}' "$1" "$2"
}

# --- Écriture autorisée -----------------------------------------------------

check 0 "CA15 : Write d'un piège" "$(input Write "$project/docs/learnings/quantite-non-recalculee.md")"
check 0 "CA15 : Edit d'un piège"  "$(input Edit "$project/docs/learnings/quantite-non-recalculee.md")"
check 0 "CA15 : slug avec chiffres" "$(input Write "$project/docs/learnings/migration-002-avant-fixtures.md")"

# --- Écriture hors de docs/learnings/ ---------------------------------------

for file in README.md CLAUDE.md .claude/agents/reviewer.md src/app.ts; do
  check 2 "CA16 : Write $file" "$(input Write "$project/$file")"
done
check 2 "CA16 : Edit CLAUDE.md"      "$(input Edit "$project/CLAUDE.md")"
check 2 "CA16 : MultiEdit README.md" "$(input MultiEdit "$project/README.md")"
check 2 "CA16 : message qui cite le chemin" "$(input Write "$project/README.md")"
if grep -qF "$project/README.md" <<<"$output"; then
  echo "OK     CA16 : chemin cité dans le message"
else
  echo "ÉCHEC  CA16 : chemin absent du message (sortie : $output)"
  fail=1
fi

# --- Chemins qui sortent du dossier ou n'ont pas la forme attendue -----------

check 2 "CA17 : remontée par .."      "$(input Write "$project/docs/learnings/../CLAUDE.md")"
check 2 "CA17 : remontée par .. (2)"  "$(input Write "$project/docs/learnings/../../docs/learnings/x.md")"
check 2 "CA17 : sous-dossier"         "$(input Write "$project/docs/learnings/a/b.md")"
check 2 "CA17 : extension .txt"       "$(input Write "$project/docs/learnings/piege.txt")"
check 2 "CA17 : .gitkeep"             "$(input Write "$project/docs/learnings/.gitkeep")"
check 2 "CA17 : slug en majuscules"   "$(input Write "$project/docs/learnings/Piege.md")"
check 2 "CA17 : slug avec espace"     "$(input Write "$project/docs/learnings/mon piege.md")"
check 2 "CA17 : slug vide"            "$(input Write "$project/docs/learnings/.md")"
check 2 "CA17 : autre projet"         "$(input Write "/tmp/autre/docs/learnings/x.md")"
check 2 "CA17 : chemin relatif"       "$(input Write "docs/learnings/x.md")"
check 2 "CA17 : dossier lui-même"     "$(input Write "$project/docs/learnings/")"

# --- Outils -------------------------------------------------------------------

check 0 "CA18 : Read hors de docs/learnings/" "$(input Read "$project/README.md")"
check 0 "CA18 : Grep" '{"tool_name":"Grep","tool_input":{"pattern":"x"}}'
check 0 "CA18 : Glob" '{"tool_name":"Glob","tool_input":{"pattern":"**/*.md"}}'
check 2 "CA18 : Bash" '{"tool_name":"Bash","tool_input":{"command":"echo x > docs/learnings/x.md"}}'
check 2 "CA18 : NotebookEdit" "$(input NotebookEdit "$project/docs/learnings/x.md")"
check 2 "CA18 : WebFetch" '{"tool_name":"WebFetch","tool_input":{"url":"https://example.com"}}'

# --- Liens symboliques --------------------------------------------------------

ln -s "$project/CLAUDE.md" "$project/docs/learnings/lien.md"
check 2 "CA19 : piège qui est un lien symbolique" "$(input Write "$project/docs/learnings/lien.md")"

linked="$work/projet-lie"
mkdir -p "$linked/docs" "$work/ailleurs"
ln -s "$work/ailleurs" "$linked/docs/learnings"
check 2 "CA19 : docs/learnings/ qui est un lien symbolique" \
  "$(input Write "$linked/docs/learnings/x.md")" "$PATH" "$linked"

# --- Fermeture en cas de panne ------------------------------------------------

check 2 "CA20 : JSON invalide"        'pas du json {'
check 2 "CA20 : entrée vide"          ''
check 2 "CA20 : tool_name absent"     "{\"tool_input\":{\"file_path\":\"$project/docs/learnings/x.md\"}}"
check 2 "CA20 : tool_name non textuel" "{\"tool_name\":5,\"tool_input\":{\"file_path\":\"$project/docs/learnings/x.md\"}}"
check 2 "CA20 : Write sans file_path" '{"tool_name":"Write","tool_input":{}}'
check 2 "CA20 : Edit sans tool_input" '{"tool_name":"Edit"}'

# PATH réduit aux binaires dont le hook a besoin, sans jq
no_jq="$work/bin"
mkdir "$no_jq"
for cmd in bash cat; do
  ln -s "$(command -v "$cmd")" "$no_jq/$cmd"
done
check 2 "CA20 : jq absent" "$(input Write "$project/docs/learnings/x.md")" "$no_jq"
if grep -q "jq" <<<"$output"; then
  echo "OK     CA20 : jq absent : message cite jq"
else
  echo "ÉCHEC  CA20 : jq absent : message sans jq (sortie : $output)"
  fail=1
fi

check 2 "CA20 : CLAUDE_PROJECT_DIR vide" "$(input Write "$project/docs/learnings/x.md")" "$PATH" ""
output=$(input Write "$project/docs/learnings/x.md" | env -u CLAUDE_PROJECT_DIR "$hook" 2>&1 >/dev/null)
code=$?
if [ "$code" -eq 2 ]; then
  echo "OK     CA20 : CLAUDE_PROJECT_DIR absent"
else
  echo "ÉCHEC  CA20 : CLAUDE_PROJECT_DIR absent (attendu 2, obtenu $code)"
  fail=1
fi

exit $fail
