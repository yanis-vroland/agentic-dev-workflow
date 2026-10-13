#!/usr/bin/env bash
# Vérifie scripts/lint-shell.sh, lint du template lui-même, selon les critères
# CA23 et CA24 de la spec
# https://github.com/yanis-vroland/agentic-dev-workflow/blob/main/docs/specs/006-revue-securite-et-hooks-qualite.md
# Propre au template : ce test n'est pas copié par scripts/init.sh.
# Les fonctions de vérification sont appelées via check, que shellcheck ne suit pas.
# Le code d'avertissement dépend de la version : SC2317 avant 0.11, SC2329 ensuite.
# shellcheck disable=SC2317,SC2329
set -u

template="$(cd "$(dirname "$0")/.." && pwd -P)"
script="$template/scripts/lint-shell.sh"
fail=0

if [ ! -f "$script" ]; then
  echo "ÉCHEC  $script est absent : toutes les vérifications vont échouer"
  fail=1
fi

# Un échec de mktemp arrête le test : sinon « cd "" » laisserait $work sur le
# dossier courant, que le trap effacerait.
if ! work=$(mktemp -d) || ! work=$(cd "$work" && pwd -P); then
  echo "Erreur : mktemp -d a échoué" >&2
  exit 1
fi
trap 'rm -rf "$work"' EXIT

code=0

pass() {
  echo "OK     $1"
}

failed() {
  echo "ÉCHEC  $1${2:+ ($2)}"
  fail=1
}

check() {
  local description=$1
  shift
  if "$@"; then
    pass "$description"
  else
    failed "$description"
  fi
}

check_code() {
  local expected=$1 description=$2
  if [ "$code" -eq "$expected" ]; then
    pass "$description"
  else
    failed "$description" "attendu $expected, obtenu $code"
  fi
}

# Code non nul dû au lint : 126 et 127 (script non exécutable ou introuvable)
# ne comptent pas, sinon la vérification passerait sans scripts/lint-shell.sh
check_nonzero() {
  local description=$1
  if [ "$code" -ne 0 ] && [ "$code" -ne 126 ] && [ "$code" -ne 127 ]; then
    pass "$description"
  else
    failed "$description" "obtenu $code"
  fi
}

# run_lint <fichier> [PATH] : lance le script depuis la racine du template,
# comme le hook de lint, avec le chemin absolu du fichier
run_lint() {
  local file=$1 path=${2:-$PATH}
  (cd "$template" && PATH="$path" "$script" "$file") >/dev/null 2>&1
  code=$?
}

not_exists() {
  [ ! -e "$1" ] && [ ! -L "$1" ]
}

trace_has() {
  grep -qxF -- "$2" "$1" 2>/dev/null
}

# Faux shellcheck en tête de PATH : note ses arguments et échoue
fake_bin="$work/faux-bin"
mkdir "$fake_bin"
trace="$work/shellcheck-trace"
cat >"$fake_bin/shellcheck" <<EOF
#!/usr/bin/env bash
for arg in "\$@"; do printf '%s\n' "\$arg" >>"$trace"; done
exit 1
EOF
chmod +x "$fake_bin/shellcheck"
fake_path="$fake_bin:$PATH"

# Contenu shell avec une erreur shellcheck (variable non définie, non protégée).
# Guillemets simples voulus : la variable reste telle quelle dans le fichier.
# shellcheck disable=SC2016
bad_body='echo $variable_jamais_definie'

if ! command -v shellcheck >/dev/null 2>&1; then
  failed "Spec 006 CA24 : précondition, shellcheck installé"
fi

# --- CA24 : script shell avec une erreur shellcheck -------------------------

printf '#!/usr/bin/env bash\n%s\n' "$bad_body" >"$work/mauvais.sh"
run_lint "$work/mauvais.sh"
check_nonzero "Spec 006 CA24 : script .sh avec une erreur shellcheck, code non nul"
rm -f "$trace"
run_lint "$work/mauvais.sh" "$fake_path"
check "Spec 006 CA24 : script .sh, shellcheck reçoit le fichier" \
  trace_has "$trace" "$work/mauvais.sh"

# Témoin : un script shell correct passe
printf '#!/usr/bin/env bash\necho "ok"\n' >"$work/correct.sh"
run_lint "$work/correct.sh"
check_code 0 "Spec 006 CA24 : témoin, script .sh correct, code 0"

# --- CA24 : fichier Markdown, sans lancer shellcheck ------------------------

rm -f "$trace"
printf '# Titre\n\n%s\n' "$bad_body" >"$work/notes.md"
run_lint "$work/notes.md" "$fake_path"
check_code 0 "Spec 006 CA24 : fichier Markdown, code 0"
# Garde : vérification négative, vraie aussi sans script
check "Spec 006 CA24 : fichier Markdown, shellcheck non lancé (garde)" not_exists "$trace"

# --- CA23 : filtre des fichiers shell ---------------------------------------

# Extension .sh sans ligne #! : shellcheck lancé sur le fichier
rm -f "$trace"
printf '%s\n' "$bad_body" >"$work/sans-shebang.sh"
run_lint "$work/sans-shebang.sh" "$fake_path"
check_nonzero "Spec 006 CA23 : extension .sh sans #!, échec de shellcheck propagé"
check "Spec 006 CA23 : extension .sh sans #!, shellcheck reçoit le fichier" \
  trace_has "$trace" "$work/sans-shebang.sh"

# Sans extension, première ligne #! qui cite bash
printf '#!/usr/bin/env bash\n%s\n' "$bad_body" >"$work/script-bash"
run_lint "$work/script-bash"
check_nonzero "Spec 006 CA23 : sans extension, #! bash, erreur détectée"
rm -f "$trace"
run_lint "$work/script-bash" "$fake_path"
check "Spec 006 CA23 : sans extension, #! bash, shellcheck reçoit le fichier" \
  trace_has "$trace" "$work/script-bash"

# Sans extension, première ligne #! qui cite sh
printf '#!/bin/sh\n%s\n' "$bad_body" >"$work/script-sh"
run_lint "$work/script-sh"
check_nonzero "Spec 006 CA23 : sans extension, #!/bin/sh, erreur détectée"
rm -f "$trace"
run_lint "$work/script-sh" "$fake_path"
check "Spec 006 CA23 : sans extension, #!/bin/sh, shellcheck reçoit le fichier" \
  trace_has "$trace" "$work/script-sh"

# Sans extension, autre interpréteur : rien n'est lancé
rm -f "$trace"
printf '#!/usr/bin/env python3\nprint("ok")\n' >"$work/script-python"
run_lint "$work/script-python" "$fake_path"
check_code 0 "Spec 006 CA23 : #! python3, code 0"
check "Spec 006 CA23 : #! python3, shellcheck non lancé (garde)" not_exists "$trace"

# Mention de bash ailleurs que sur la première ligne : pas un fichier shell
rm -f "$trace"
printf 'Notes\n#!/bin/bash\n%s\n' "$bad_body" >"$work/notes.txt"
run_lint "$work/notes.txt" "$fake_path"
check_code 0 "Spec 006 CA23 : #! bash hors de la première ligne, code 0"
check "Spec 006 CA23 : #! bash hors de la première ligne, shellcheck non lancé (garde)" \
  not_exists "$trace"

# Non-régression (vu par le hook de lint sur ce template) : lancé sur un seul
# fichier, le lint doit suivre un fichier sourcé déclaré par une directive
# « shellcheck source= », comme le fait shellcheck sur l'ensemble des hooks en CI
run_lint "$template/.claude/hooks/lint.sh"
check_code 0 "Spec 006 CA23 : hook qui source quality-common.sh, lint seul au vert"

exit $fail
