#!/usr/bin/env bash
# Vérifie scripts/init.sh selon la spec docs/specs/001-script-init.md.
# Chaque vérification cite le critère d'acceptation (CAn) ou le cas limite testé.
# CA20 n'est pas couvert ici : il est vérifié par la CI elle-même.
# Les fonctions de vérification sont appelées via check, que shellcheck ne suit pas.
# shellcheck disable=SC2329
set -u

template="$(cd "$(dirname "$0")/.." && pwd -P)"
script="$template/scripts/init.sh"
fail=0

if [ ! -f "$script" ]; then
  echo "ÉCHEC  $script est absent : toutes les vérifications vont échouer"
  fail=1
fi

# Chemin canonique : sous macOS, /var est un lien vers /private/var
work="$(cd "$(mktemp -d)" && pwd -P)"
trap 'rm -rf "$work"' EXIT

# Isole les tests de la configuration Git de l'utilisateur et de l'appelant
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE
: >"$work/gitconfig"
export GIT_CONFIG_GLOBAL="$work/gitconfig"
export GIT_CONFIG_NOSYSTEM=1

# Répertoire courant neutre par défaut, distinct du template et des cibles
neutral="$work/cwd"
mkdir "$neutral"

# Fichiers de la section « Copiés » de la spec, chemins relatifs au template
copied=(
  CLAUDE.md
  tests/hooks.sh
  tests/pre-commit.sh
  .github/workflows/garde-fous.yml
  .github/workflows/ai-review.yml
  .github/pull_request_template.md
)
while IFS= read -r file; do
  copied+=("$file")
done < <(cd "$template" && find .claude .githooks docs/templates -type f \
  ! -path .claude/settings.local.json | LC_ALL=C sort)

# Entrées attendues dans le .gitignore de la cible
gitignore_entries=(".env" ".env.*" "!.env.example" ".claude/settings.local.json")

# --- Outils de vérification -------------------------------------------------

output=""
code=0

pass() {
  echo "OK     $1"
}

failed() {
  echo "ÉCHEC  $1${2:+ ($2)}"
  fail=1
}

# check <description> <commande...> : OK si la commande réussit
check() {
  local description=$1
  shift
  if "$@"; then
    pass "$description"
  else
    failed "$description"
  fi
}

# Vérifie le code de sortie du dernier lancement
check_code() {
  local expected=$1 description=$2
  if [ "$code" -eq "$expected" ]; then
    pass "$description"
  else
    failed "$description" "attendu $expected, obtenu $code : $(head -n 1 <<<"$output")"
  fi
}

# Vérifie qu'un fragment apparaît dans la sortie du dernier lancement
check_output() {
  local description=$1 fragment=$2
  if grep -qF -- "$fragment" <<<"$output"; then
    pass "$description"
  else
    failed "$description" "fragment « $fragment » absent de la sortie"
  fi
}

# Idem, sans tenir compte de la casse
check_output_i() {
  local description=$1 fragment=$2
  if grep -qiF -- "$fragment" <<<"$output"; then
    pass "$description"
  else
    failed "$description" "fragment « $fragment » absent de la sortie"
  fi
}

# Vérifie qu'un fragment n'apparaît pas dans la sortie
check_no_output() {
  local description=$1 fragment=$2
  if grep -qF -- "$fragment" <<<"$output"; then
    failed "$description" "fragment « $fragment » présent dans la sortie"
  else
    pass "$description"
  fi
}

# Lance init.sh depuis le répertoire courant neutre
run_init() {
  output=$(cd "$neutral" && "$script" "$@" 2>&1)
  code=$?
}

# Lance init.sh depuis un répertoire courant donné
run_init_from() {
  local cwd=$1
  shift
  output=$(cd "$cwd" && "$script" "$@" 2>&1)
  code=$?
}

# Lance init.sh avec un PATH donné
run_init_with_path() {
  local path=$1
  shift
  output=$(cd "$neutral" && PATH="$path" "$script" "$@" 2>&1)
  code=$?
}

# Nouveau dossier de cas, vide
new_case() {
  mktemp -d "$work/case.XXXXXX"
}

# Nouveau dossier de cas, initialisé avec Git
new_repo() {
  local dir
  dir=$(new_case)
  git init -q "$dir"
  echo "$dir"
}

# Empreinte des fichiers et dossiers d'une arborescence, hors .git
snapshot() {
  (
    cd "$1" || exit 1
    {
      find . -path ./.git -prune -o -type d -print
      find . -path ./.git -prune -o -type f -exec cksum {} +
    } | LC_ALL=C sort
  )
}

same_file() {
  cmp -s "$1" "$2"
}

is_executable() {
  [ -x "$1" ]
}

not_exists() {
  [ ! -e "$1" ] && [ ! -L "$1" ]
}

has_line() {
  grep -qxF -- "$2" "$1"
}

has_no_entry() {
  ! grep -q '^## ' "$1"
}

# Aucune ligne non vide n'apparaît deux fois
no_duplicate_lines() {
  [ -z "$(grep -v '^[[:space:]]*$' "$1" | LC_ALL=C sort | uniq -d)" ]
}

ignored() {
  git -C "$1" check-ignore -q -- "$2"
}

not_ignored() {
  ! git -C "$1" check-ignore -q -- "$2"
}

hooks_path_is() {
  [ "$(git -C "$1" config --local --get core.hooksPath)" = "$2" ]
}

hooks_path_unset() {
  ! git -C "$1" config --local --get core.hooksPath >/dev/null
}


not_inside_git() {
  ! git -C "$1" rev-parse --is-inside-work-tree >/dev/null 2>&1
}

equal() {
  [ "$1" = "$2" ]
}

# Une même ligne de la sortie contient les deux fragments (insensible à la casse)
output_line_has() {
  grep -iF -- "$1" <<<"$output" | grep -qiF -- "$2"
}

# Le fragment apparaît sur au moins <n> lignes de la sortie (insensible à la casse)
output_lines_at_least() {
  [ "$(grep -ciF -- "$1" <<<"$output")" -ge "$2" ]
}

# Dossier bin contenant des liens vers toutes les commandes du PATH réel, sauf une
make_bin_without() {
  local excluded=$1 bin dir file name
  local -a dirs
  bin=$(mktemp -d "$work/bin.XXXXXX")
  IFS=: read -ra dirs <<<"$PATH"
  for dir in "${dirs[@]}"; do
    if [ -z "$dir" ] || [ ! -d "$dir" ]; then
      continue
    fi
    for file in "$dir"/*; do
      name=${file##*/}
      if [ "$name" = "$excluded" ] || [ -d "$file" ] || [ ! -x "$file" ]; then
        continue
      fi
      # Le premier dossier du PATH l'emporte, comme pour le shell
      if [ -e "$bin/$name" ] || [ -L "$bin/$name" ]; then
        continue
      fi
      ln -s "$file" "$bin/$name"
    done
  done
  echo "$bin"
}

command_absent_from() {
  ! (PATH="$1" && command -v "$2" >/dev/null 2>&1)
}

# --- CA1 : copie des fichiers ----------------------------------------------

t=$(new_repo)
run_init "$t"
check_code 0 "CA1 : code de sortie 0 sur un dépôt vide"
for file in "${copied[@]}"; do
  check "CA1 : $file identique au template" same_file "$template/$file" "$t/$file"
  if [ -x "$template/$file" ]; then
    check "CA1 : $file reste exécutable" is_executable "$t/$file"
  fi
done
# Vérifications explicites, au cas où le bit serait perdu dans le template
for file in .githooks/pre-commit .claude/hooks/protect-secrets.sh .claude/hooks/format.sh \
  tests/hooks.sh tests/pre-commit.sh; do
  check "CA1 : $file exécutable" is_executable "$t/$file"
done
check "CA1 : .claude/settings.local.json non copié" not_exists "$t/.claude/settings.local.json"

# --- CA19 : fichiers propres au template absents (même cible que CA1) -------

check "CA19 : template-ci.yml absent" \
  equal "" "$(find "$t" -name template-ci.yml -print)"
check "CA19 : ci.yml absent" \
  equal "" "$(find "$t" -name ci.yml -print)"
check "CA19 : test de init.sh absent" \
  equal "" "$(find "$t" -name init-script.sh -print)"

# --- CA16 : étapes manuelles (même cible que CA1) ---------------------------

check_output "CA16 : secret CLAUDE_CODE_OAUTH_TOKEN mentionné" "CLAUDE_CODE_OAUTH_TOKEN"
check_output_i "CA16 : installation de l'application GitHub mentionnée" "application"
check_output_i "CA16 : ruleset sur main mentionné" "ruleset"
check_output "CA16 : label agent-corrigé mentionné" "agent-corrigé"
check_output "CA16 : commande gh de création du label" "gh label create"
check_output "CA16 : sections À ADAPTER du CLAUDE.md mentionnées" "À ADAPTER"

# --- CA2 : dossiers et journal créés ----------------------------------------

t=$(new_repo)
run_init "$t"
check_code 0 "CA2 : code de sortie 0"
check "CA2 : docs/adr/.gitkeep créé" test -f "$t/docs/adr/.gitkeep"
check "CA2 : docs/specs/.gitkeep créé" test -f "$t/docs/specs/.gitkeep"
check "CA2 : docs/journal.md créé" test -f "$t/docs/journal.md"
check "CA2 : docs/journal.md contient l'en-tête" grep -q '^# Journal' "$t/docs/journal.md"
check "CA2 : docs/journal.md sans entrée" has_no_entry "$t/docs/journal.md"
check "CA2 : docs/adr du template non copié" \
  not_exists "$t/docs/adr/001-authentification-ci.md"

# --- CA3 / CA4 : fichier copié déjà présent -----------------------------------

t=$(new_repo)
printf '# Mon projet\n\nContenu local.\n' >"$t/CLAUDE.md"
cp "$t/CLAUDE.md" "$work/claude-before.md"
run_init "$t"
check_code 0 "CA3 : code de sortie 0 avec un CLAUDE.md existant"
check "CA3 : CLAUDE.md non modifié sans --force" same_file "$work/claude-before.md" "$t/CLAUDE.md"
check "CA3 : CLAUDE.md listé comme ignoré" output_line_has "ignor" "CLAUDE.md"

run_init "$t" --force
check_code 0 "CA4 : code de sortie 0 avec --force"
check "CA4 : CLAUDE.md remplacé avec --force" same_file "$template/CLAUDE.md" "$t/CLAUDE.md"

# --- CA5 : journal existant jamais modifié ----------------------------------

for option in "" "--force"; do
  label=${option:-sans --force}
  t=$(new_repo)
  mkdir -p "$t/docs"
  printf '# Journal de bord\n\n## 2026-01-01 : première entrée\n\n- Une note.\n' \
    >"$t/docs/journal.md"
  cp "$t/docs/journal.md" "$work/journal-before.md"
  if [ -n "$option" ]; then
    run_init "$t" "$option"
  else
    run_init "$t"
  fi
  check_code 0 "CA5 : code de sortie 0 ($label)"
  check "CA5 : journal non modifié ($label)" \
    same_file "$work/journal-before.md" "$t/docs/journal.md"
done

# --- CA6 : .gitignore partiel -----------------------------------------------

t=$(new_repo)
printf 'node_modules/\n.env\ndist/\n' >"$t/.gitignore"
cp "$t/.gitignore" "$work/gitignore-before"
run_init "$t"
check_code 0 "CA6 : code de sortie 0"
check "CA6 : contenu existant conservé en tête" \
  equal "$(cat "$work/gitignore-before")" "$(head -n 3 "$t/.gitignore")"
for entry in "${gitignore_entries[@]}"; do
  check "CA6 : entrée $entry présente" has_line "$t/.gitignore" "$entry"
done
check "CA6 : aucune ligne dupliquée" no_duplicate_lines "$t/.gitignore"

# --- CA7 : .gitignore absent ------------------------------------------------

t=$(new_repo)
run_init "$t"
check_code 0 "CA7 : code de sortie 0"
check "CA7 : .gitignore créé" test -f "$t/.gitignore"
for entry in "${gitignore_entries[@]}"; do
  check "CA7 : entrée $entry présente" has_line "$t/.gitignore" "$entry"
done
check "CA7 : .env ignoré" ignored "$t" .env
check "CA7 : .env.local ignoré" ignored "$t" .env.local
check "CA7 : .claude/settings.local.json ignoré" ignored "$t" .claude/settings.local.json
check "CA7 : .env.example non ignoré" not_ignored "$t" .env.example

# --- CA21 : négation déjà présente, .env.* absent ----------------------------

t=$(new_repo)
printf 'node_modules/\n!.env.example\n' >"$t/.gitignore"
run_init "$t"
check_code 0 "CA21 : code de sortie 0"
check "CA21 : .env ignoré" ignored "$t" .env
check "CA21 : .env.local ignoré" ignored "$t" .env.local
check "CA21 : .env.example non ignoré" not_ignored "$t" .env.example

# --- CA8 : core.hooksPath absent --------------------------------------------

t=$(new_repo)
run_init "$t"
check_code 0 "CA8 : code de sortie 0"
check "CA8 : core.hooksPath vaut .githooks" hooks_path_is "$t" .githooks

# --- CA9 / CA10 : core.hooksPath déjà défini ----------------------------------

t=$(new_repo)
git -C "$t" config core.hooksPath custom-hooks
run_init "$t"
check_code 0 "CA9 : code de sortie 0"
check "CA9 : core.hooksPath conservé sans --force" hooks_path_is "$t" custom-hooks
check_output "CA9 : avertissement cite la valeur custom-hooks" "custom-hooks"
check "CA9 : avertissement explique le branchement du pre-commit" \
  output_line_has "custom-hooks" "pre-commit"

t=$(new_repo)
git -C "$t" config core.hooksPath custom-hooks
run_init "$t" --force
check_code 0 "CA10 : code de sortie 0"
check "CA10 : core.hooksPath vaut .githooks avec --force" hooks_path_is "$t" .githooks
check_output "CA10 : avertissement cite l'ancienne valeur custom-hooks" "custom-hooks"

# --- CA11 : cible hors dépôt Git --------------------------------------------

t=$(new_case)
check "CA11 : précondition, cible hors de tout dépôt Git" not_inside_git "$t"
run_init "$t"
check_code 0 "CA11 : code de sortie 0"
check "CA11 : CLAUDE.md appliqué" same_file "$template/CLAUDE.md" "$t/CLAUDE.md"
check "CA11 : .githooks/pre-commit appliqué" \
  same_file "$template/.githooks/pre-commit" "$t/.githooks/pre-commit"
check "CA11 : aucun dépôt Git créé" not_exists "$t/.git"
check_output "CA11 : message final invite à lancer git init" "git init"
check_output "CA11 : message final invite à activer core.hooksPath" "core.hooksPath"

# --- CA12 : sous-dossier d'un dépôt -----------------------------------------

repo=$(new_repo)
printf 'Bonjour\n' >"$repo/README.md"
mkdir "$repo/sub"
before=$(snapshot "$repo")
run_init "$repo/sub"
check_code 2 "CA12 : code de sortie 2 sur un sous-dossier"
check "CA12 : aucun fichier modifié" equal "$before" "$(snapshot "$repo")"
check "CA12 : core.hooksPath non défini" hooks_path_unset "$repo"
check_output "CA12 : message invite à cibler la racine" "racine"

# --- CA13 / CA14 : .claude/settings.json existant -----------------------------

t=$(new_repo)
mkdir -p "$t/.claude"
printf '{\n  "permissions": {}\n}\n' >"$t/.claude/settings.json"
cp "$t/.claude/settings.json" "$work/settings-before.json"
run_init "$t"
check_code 0 "CA13 : code de sortie 0"
check "CA13 : .claude/settings.json non modifié sans --force" \
  same_file "$work/settings-before.json" "$t/.claude/settings.json"
check_output "CA13 : avertissement « NON installés »" "NON installés"
check_output "CA13 : avertissement cite settings.json" "settings.json"
check "CA13 : fusion citée dans l'avertissement et dans les étapes manuelles" \
  output_lines_at_least "fusion" 2

run_init "$t" --force
check_code 0 "CA14 : code de sortie 0 avec --force"
check "CA14 : .claude/settings.json remplacé avec --force" \
  same_file "$template/.claude/settings.json" "$t/.claude/settings.json"
check_no_output "CA14 : pas d'avertissement « NON installés »" "NON installés"

# --- CA15 : idempotence -----------------------------------------------------

t=$(new_repo)
run_init "$t"
check_code 0 "CA15 : premier lancement, code de sortie 0"
before=$(snapshot "$t")
hooks_before=$(git -C "$t" config --local --get core.hooksPath)
run_init "$t"
check_code 0 "CA15 : second lancement, code de sortie 0"
check "CA15 : aucun fichier modifié" equal "$before" "$(snapshot "$t")"
check "CA15 : core.hooksPath inchangé" \
  equal "$hooks_before" "$(git -C "$t" config --local --get core.hooksPath)"
check "CA15 : .gitignore sans ligne en double" no_duplicate_lines "$t/.gitignore"
for file in "${copied[@]}"; do
  check "CA15 : $file listé comme ignoré" output_line_has "ignor" "$file"
done

# --- CA17 : gitleaks absent -------------------------------------------------

bin=$(make_bin_without gitleaks)
check "CA17 : précondition, gitleaks absent du PATH de test" command_absent_from "$bin" gitleaks
t=$(new_repo)
run_init_with_path "$bin" "$t"
check_code 0 "CA17 : code de sortie 0 sans gitleaks"
check "CA17 : message final précise que tous les commits seront bloqués sans gitleaks" \
  output_line_has "gitleaks" "tous"

# --- CA18 : jq absent -------------------------------------------------------

bin=$(make_bin_without jq)
check "CA18 : précondition, jq absent du PATH de test" command_absent_from "$bin" jq
t=$(new_repo)
run_init_with_path "$bin" "$t"
check_code 0 "CA18 : code de sortie 0 sans jq"
check "CA18 : message final cite jq" grep -qw jq <<<"$output"
check "CA18 : message final lie jq et protect-secrets.sh" \
  output_line_has "jq" "protect-secrets"

# --- Cas limites ------------------------------------------------------------

# Sans argument
c=$(new_case)
before=$(snapshot "$c")
run_init_from "$c"
check_code 2 "Limite : sans argument, code de sortie 2"
check_output_i "Limite : sans argument, usage affiché" "usage"
check "Limite : sans argument, rien modifié" equal "$before" "$(snapshot "$c")"

# Option inconnue
t=$(new_repo)
before=$(snapshot "$t")
run_init "$t" --bogus
check_code 2 "Limite : option inconnue, code de sortie 2"
check_output_i "Limite : option inconnue, usage affiché" "usage"
check "Limite : option inconnue, rien modifié" equal "$before" "$(snapshot "$t")"
check "Limite : option inconnue, core.hooksPath non défini" hooks_path_unset "$t"

# Cible inexistante
c=$(new_case)
before=$(snapshot "$c")
run_init "$c/absent"
check_code 1 "Limite : cible inexistante, code de sortie 1"
check "Limite : cible inexistante, non créée" not_exists "$c/absent"
check "Limite : cible inexistante, rien créé à côté" equal "$before" "$(snapshot "$c")"

# Cible = template
before=$(snapshot "$template")
hooks_before=$(git -C "$template" config --local --get core.hooksPath)
run_init "$template"
check_code 1 "Limite : cible = template, code de sortie 1"
check "Limite : cible = template, rien modifié" equal "$before" "$(snapshot "$template")"
check "Limite : cible = template, core.hooksPath inchangé" \
  equal "$hooks_before" "$(git -C "$template" config --local --get core.hooksPath)"

# .gitignore sans saut de ligne final
t=$(new_repo)
printf 'node_modules/' >"$t/.gitignore"
run_init "$t"
check_code 0 "Limite : .gitignore sans saut de ligne final, code de sortie 0"
check "Limite : .gitignore sans saut de ligne final, ligne existante intacte" \
  has_line "$t/.gitignore" "node_modules/"
check "Limite : .gitignore sans saut de ligne final, .env sur sa propre ligne" \
  has_line "$t/.gitignore" ".env"

# Lancement depuis un autre répertoire courant
other=$(new_case)
t=$(new_repo)
run_init_from "$other" "$t"
check_code 0 "Limite : autre répertoire courant, code de sortie 0"
check "Limite : autre répertoire courant, CLAUDE.md copié" \
  same_file "$template/CLAUDE.md" "$t/CLAUDE.md"
check "Limite : autre répertoire courant, .githooks/pre-commit copié" \
  same_file "$template/.githooks/pre-commit" "$t/.githooks/pre-commit"
check "Limite : autre répertoire courant, rien écrit dans le répertoire courant" \
  equal "." "$(snapshot "$other")"

exit $fail
