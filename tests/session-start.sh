#!/usr/bin/env bash
# Vérifie le hook .claude/hooks/session-start.sh selon la spec
# docs/specs/004-reprise-de-session.md (CA1 à CA7 et cas limites), complétée par
# les critères CA1 à CA5 de docs/specs/008-cadrage-et-plan-global.md (état du cadrage).
# Chaque cas monte un dépôt « distant » bare local, un dépôt amont qui y pousse
# de nouveaux commits, et un clone : le dépôt de travail sur lequel le hook agit.
# Les fragments de message sont comparés sans tenir compte de la casse.
# Les fonctions de vérification sont appelées via check, que shellcheck ne suit pas.
# Le code d'avertissement dépend de la version : SC2317 avant 0.11, SC2329 ensuite.
# shellcheck disable=SC2317,SC2329
set -u

template="$(cd "$(dirname "$0")/.." && pwd -P)"
hook="$template/.claude/hooks/session-start.sh"
fail=0

if [ ! -f "$hook" ]; then
  echo "ÉCHEC  $hook est absent : toutes les vérifications vont échouer"
  fail=1
fi

# Chemin canonique : sous macOS, /var est un lien vers /private/var
# Un échec de mktemp arrête le test : sinon « cd "" » laisserait $work sur le
# dossier courant, que le trap effacerait.
if ! work=$(mktemp -d) || ! work=$(cd "$work" && pwd -P); then
  echo "Erreur : mktemp -d a échoué" >&2
  exit 1
fi
trap 'rm -rf "$work"' EXIT

# Isole les tests de la configuration Git de l'utilisateur et de l'appelant
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE
cat >"$work/gitconfig" <<'EOF'
[user]
	name = Test
	email = test@example.com
[init]
	defaultBranch = main
[commit]
	gpgsign = false
[advice]
	detachedHead = false
EOF
export GIT_CONFIG_GLOBAL="$work/gitconfig"
export GIT_CONFIG_NOSYSTEM=1

# Répertoire courant neutre, hors de tout dépôt
neutral="$work/cwd"
mkdir "$neutral"

# gh remplacé par un stub qui échoue : ni réseau ni compte réel
stub_bin="$work/stub-bin"
mkdir "$stub_bin"
printf '#!/bin/sh\nexit 1\n' >"$stub_bin/gh"
chmod +x "$stub_bin/gh"

hook_input='{"hook_event_name":"SessionStart","source":"startup"}'

# --- Outils de vérification -------------------------------------------------

output=""
errors=""
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
    failed "$description" "attendu $expected, obtenu $code : $(head -n 1 <<<"$errors")"
  fi
}

# Vérifie qu'un fragment apparaît dans la sortie (insensible à la casse)
check_output_i() {
  local description=$1 fragment=$2
  if grep -qiF -- "$fragment" <<<"$output"; then
    pass "$description"
  else
    failed "$description" "fragment « $fragment » absent de la sortie"
  fi
}

# Vérifie qu'un fragment n'apparaît pas dans la sortie (insensible à la casse)
check_no_output_i() {
  local description=$1 fragment=$2
  if grep -qiF -- "$fragment" <<<"$output"; then
    failed "$description" "fragment « $fragment » présent dans la sortie"
  else
    pass "$description"
  fi
}

equal() {
  [ "$1" = "$2" ]
}

# Une même ligne de la sortie contient les deux fragments (insensible à la casse)
output_line_has() {
  grep -iF -- "$1" <<<"$output" | grep -qiF -- "$2"
}

# Une même ligne contient le fragment et le mot (nombre isolé, par exemple)
output_line_has_word() {
  grep -iF -- "$1" <<<"$output" | grep -qw -- "$2"
}

not_inside_git() {
  ! git -C "$1" rev-parse --is-inside-work-tree >/dev/null 2>&1
}

same_file() {
  cmp -s "$1" "$2"
}

not_exists() {
  [ ! -e "$1" ] && [ ! -L "$1" ]
}

# Le texte ne contient pas le fragment (insensible à la casse)
not_grep_i() {
  ! grep -qiF -- "$1" <<<"$2"
}

# Lance le hook sur un projet, depuis le répertoire courant neutre
run_hook() {
  output=$(cd "$neutral" && printf '%s\n' "$hook_input" |
    CLAUDE_PROJECT_DIR="$1" PATH="$stub_bin:$PATH" "$hook" 2>"$work/stderr")
  code=$?
  errors=$(cat "$work/stderr")
}

# --- Mise en place des dépôts -----------------------------------------------

sha() {
  git -C "$1" rev-parse "$2"
}

# commit_file <dépôt> <chemin> <contenu> <message>
commit_file() {
  local repo=$1 path=$2 content=$3 message=$4
  mkdir -p "$(dirname "$repo/$path")"
  printf '%s\n' "$content" >"$repo/$path"
  git -C "$repo" add -- "$path"
  git -C "$repo" commit -q -m "$message"
}

# Nouveau cas : <cas>/remote.git (bare), <cas>/upstream et <cas>/clone, tous sur main
new_case() {
  local c
  c=$(mktemp -d "$work/case.XXXXXX")
  git init -q --bare -b main "$c/remote.git"
  git clone -q "$c/remote.git" "$c/upstream" 2>/dev/null
  commit_file "$c/upstream" README.md "Projet de test" "chore: initialisation"
  git -C "$c/upstream" push -q origin main
  git clone -q "$c/remote.git" "$c/clone"
  echo "$c"
}

# push_upstream <cas> <nombre> : pousse <nombre> nouveaux commits sur origin/main
push_upstream() {
  local c=$1 n=$2 i
  for i in $(seq 1 "$n"); do
    commit_file "$c/upstream" "distant-$i-$RANDOM.txt" "commit distant $i" "feat: commit distant $i"
  done
  git -C "$c/upstream" push -q origin main
}

# --- CA1 : branche propre en retard, avance rapide --------------------------

c=$(new_case)
push_upstream "$c" 1
before=$(sha "$c/clone" HEAD)
run_hook "$c/clone"
check_code 0 "CA1 : code de sortie 0"
check "CA1 : précondition, le distant a avancé" \
  test "$before" != "$(sha "$c/remote.git" main)"
check "CA1 : HEAD avancé jusqu'au SHA distant" \
  equal "$(sha "$c/remote.git" main)" "$(sha "$c/clone" HEAD)"
check "CA1 : arbre de travail mis à jour (fichier du commit distant présent)" \
  test -n "$(cd "$c/clone" && find . -maxdepth 1 -name 'distant-1-*.txt' -print)"
check "CA1 : arbre de travail propre après l'avance" \
  equal "" "$(git -C "$c/clone" status --porcelain)"
check_output_i "CA1 : la sortie dit que la branche est avancée" "avancée"

# --- Limite : gh non authentifié (stub qui échoue, même cas que CA1) ---------
# Fragment non convenu : on suppose que la ligne cite la commande gh.
check "Limite : gh indisponible, une ligne le dit (mot « gh »)" \
  grep -qiw gh <<<"$output"

# --- CA2 : modifications non committées, en retard --------------------------

c=$(new_case)
push_upstream "$c" 1
printf 'Modification locale non committée\n' >>"$c/clone/README.md"
cp "$c/clone/README.md" "$work/readme-before"
before=$(sha "$c/clone" HEAD)
run_hook "$c/clone"
check_code 0 "CA2 : code de sortie 0"
check "CA2 : HEAD inchangé" equal "$before" "$(sha "$c/clone" HEAD)"
check "CA2 : fichier modifié inchangé" same_file "$work/readme-before" "$c/clone/README.md"
check "CA2 : origin/main récupéré (le fetch a eu lieu)" \
  equal "$(sha "$c/remote.git" main)" "$(sha "$c/clone" origin/main)"
check_output_i "CA2 : la sortie signale les modifications non committées" "non committées"
check "CA2 : une même ligne signale le retard et les modifications non committées" \
  output_line_has "retard" "non committées"

# --- CA3 : branche divergente ------------------------------------------------

c=$(new_case)
push_upstream "$c" 1
commit_file "$c/clone" local.txt "travail local" "feat: travail local"
before=$(sha "$c/clone" HEAD)
run_hook "$c/clone"
check_code 0 "CA3 : code de sortie 0"
check "CA3 : HEAD inchangé" equal "$before" "$(sha "$c/clone" HEAD)"
check "CA3 : arbre de travail propre, rien modifié" \
  equal "" "$(git -C "$c/clone" status --porcelain)"
check "CA3 : origin/main récupéré (le fetch a eu lieu)" \
  equal "$(sha "$c/remote.git" main)" "$(sha "$c/clone" origin/main)"
check_output_i "CA3 : la sortie signale la divergence" "diverg"

# --- CA4 : branche de travail en retard sur origin/main ---------------------

c=$(new_case)
git -C "$c/clone" checkout -q -b feat/travail
commit_file "$c/clone" travail.txt "travail" "feat: travail"
git -C "$c/clone" push -q -u origin feat/travail 2>/dev/null
push_upstream "$c" 3
before=$(sha "$c/clone" HEAD)
run_hook "$c/clone"
check_code 0 "CA4 : code de sortie 0"
check "CA4 : HEAD inchangé (ni rebase ni merge)" equal "$before" "$(sha "$c/clone" HEAD)"
check "CA4 : toujours sur feat/travail" \
  equal "feat/travail" "$(git -C "$c/clone" symbolic-ref --short HEAD)"
check "CA4 : origin/main récupéré (le fetch a eu lieu)" \
  equal "$(sha "$c/remote.git" main)" "$(sha "$c/clone" origin/main)"
check "CA4 : une ligne cite origin/main et les 3 commits de retard" \
  output_line_has_word "origin/main" 3

# --- CA5 : remote injoignable -----------------------------------------------

c=$(new_case)
git -C "$c/clone" remote set-url origin "$c/absent.git"
run_hook "$c/clone"
check_code 0 "CA5 : code de sortie 0"
check_output_i "CA5 : la sortie signale l'échec de la récupération" "récupération impossible"

# --- CA6 : dernière entrée du journal de la branche --------------------------

c=$(new_case)
# Journal d'une autre branche déjà mergée, plus récent par son nom
commit_file "$c/clone" docs/journal/2026-10-08-feat-autre.md "# Journal : feat/autre

## 2026-10-08 18:00

- Fait : marqueur-autre-branche" "docs: journal d'une autre branche"
git -C "$c/clone" push -q origin main
git -C "$c/clone" checkout -q -b feat/journal-test
commit_file "$c/clone" docs/journal/2026-10-07-feat-journal-test.md "# Journal : feat/journal-test

## 2026-10-07 09:15

### Fait

- marqueur-entree-ancienne

### Prochaine étape

- marqueur-suite-ancienne

## 2026-10-07 16:42

### Fait

- marqueur-entree-recente

### Prochaine étape

- marqueur-suite-recente" "docs: journal de la branche"
git -C "$c/clone" push -q -u origin feat/journal-test 2>/dev/null
run_hook "$c/clone"
check_code 0 "CA6 : code de sortie 0"
check_output_i "CA6 : titre de la dernière entrée affiché" "2026-10-07 16:42"
check_output_i "CA6 : contenu de la dernière entrée affiché (Fait)" "marqueur-entree-recente"
check_output_i "CA6 : contenu de la dernière entrée affiché (Prochaine étape)" "marqueur-suite-recente"
check_no_output_i "CA6 : titre de l'entrée précédente absent" "2026-10-07 09:15"
check_no_output_i "CA6 : contenu de l'entrée précédente absent" "marqueur-entree-ancienne"
check_no_output_i "CA6 : journal d'une autre branche absent" "marqueur-autre-branche"

# --- CA7 : dossier qui n'est pas un dépôt Git --------------------------------

d=$(mktemp -d "$work/hors-git.XXXXXX")
check "CA7 : précondition, dossier hors de tout dépôt Git" not_inside_git "$d"
run_hook "$d"
check_code 0 "CA7 : code de sortie 0"
check "CA7 : aucune erreur affichée (stderr vide)" equal "" "$errors"

# --- Limite : HEAD détaché ---------------------------------------------------

c=$(new_case)
push_upstream "$c" 1
git -C "$c/clone" checkout -q --detach HEAD
before=$(sha "$c/clone" HEAD)
run_hook "$c/clone"
check_code 0 "Limite : HEAD détaché, code de sortie 0"
check "Limite : HEAD détaché, HEAD inchangé" equal "$before" "$(sha "$c/clone" HEAD)"
check_output_i "Limite : HEAD détaché, signalé" "détaché"

# --- Limite : pas de remote origin -------------------------------------------

d=$(mktemp -d "$work/sans-remote.XXXXXX")
git init -q -b main "$d"
commit_file "$d" README.md "Sans remote" "chore: initialisation"
run_hook "$d"
check_code 0 "Limite : pas de remote origin, code de sortie 0"
check_output_i "Limite : pas de remote origin, origin mentionné" "origin"

# --- Limite : branche sans fichier de journal --------------------------------

c=$(new_case)
git -C "$c/clone" checkout -q -b feat/sans-journal
git -C "$c/clone" push -q -u origin feat/sans-journal 2>/dev/null
run_hook "$c/clone"
check_code 0 "Limite : branche sans journal, code de sortie 0"
check_output_i "Limite : branche sans journal, journal mentionné" "journal"
check "Limite : branche sans journal, nom de fichier attendu cité (slug de la branche)" \
  output_line_has "docs/journal/" "-feat-sans-journal.md"

# --- Limite : plusieurs fichiers de journal pour une même branche -------------

c=$(new_case)
git -C "$c/clone" checkout -q -b feat/multi
commit_file "$c/clone" docs/journal/2026-10-01-feat-multi.md "# Journal

## 2026-10-01 10:00

- Fait : marqueur-ancien-fichier" "docs: premier journal"
commit_file "$c/clone" docs/journal/2026-10-05-feat-multi.md "# Journal

## 2026-10-05 10:00

- Fait : marqueur-fichier-recent" "docs: second journal"
git -C "$c/clone" push -q -u origin feat/multi 2>/dev/null
run_hook "$c/clone"
check_code 0 "Limite : plusieurs journaux, code de sortie 0"
check_output_i "Limite : plusieurs journaux, le plus récent par son nom affiché" "marqueur-fichier-recent"
check_no_output_i "Limite : plusieurs journaux, l'ancien non affiché" "marqueur-ancien-fichier"

# --- État affiché sur main : dernière entrée du journal le plus récent -------

c=$(new_case)
commit_file "$c/clone" docs/journal/2026-10-02-feat-a.md "# Journal

## 2026-10-02 10:00

- Fait : marqueur-journal-a" "docs: journal a"
commit_file "$c/clone" docs/journal/2026-10-06-feat-b.md "# Journal

## 2026-10-06 09:00

- Fait : marqueur-journal-b-ancienne

## 2026-10-06 17:30

- Fait : marqueur-journal-b-recente" "docs: journal b"
git -C "$c/clone" push -q origin main
run_hook "$c/clone"
check_code 0 "Spec 004 (main) : code de sortie 0"
check_output_i "Spec 004 (main) : dernière entrée du journal le plus récent affichée" \
  "marqueur-journal-b-recente"
check_no_output_i "Spec 004 (main) : entrée précédente absente" "marqueur-journal-b-ancienne"
check_no_output_i "Spec 004 (main) : journal plus ancien absent" "marqueur-journal-a"

# --- Spec 008 : état du cadrage et du plan ------------------------------------
# Les critères cités ici sont ceux de docs/specs/008-cadrage-et-plan-global.md.
# Les dépôts de test ne contiennent aucun titre de PR ni de journal qui citerait
# « cadrage » ou « plan » : la sortie existante n'en contient pas non plus.

filled_cahier="# Cahier des charges fonctionnel

## Objectif et périmètre

Suivi de maintenance des machines d'un atelier."

# Ajoute un cahier des charges rempli (sans « À ADAPTER ») sur main
add_filled_cahier() {
  commit_file "$1/clone" docs/cahier-des-charges-fonctionnel.md "$filled_cahier" "docs: cahier des charges"
  git -C "$1/clone" push -q origin main
}

# Lignes de la sortie courante absentes de la sortie de référence (hors lignes vides)
lines_not_in_baseline() {
  grep -vxF -f "$work/baseline-output" <<<"$output" | grep -v '^[[:space:]]*$'
}

# CA1 : cahier des charges du modèle, avec ses « À ADAPTER »
c=$(new_case)
commit_file "$c/clone" docs/cahier-des-charges-fonctionnel.md \
  "$(cat "$template/docs/templates/cahier-des-charges-fonctionnel.md")" "docs: cahier des charges"
git -C "$c/clone" push -q origin main
check "Spec 008 CA1 : précondition, le cahier des charges contient « À ADAPTER »" \
  grep -qF "À ADAPTER" "$c/clone/docs/cahier-des-charges-fonctionnel.md"
run_hook "$c/clone"
check_code 0 "Spec 008 CA1 : code de sortie 0"
check_output_i "Spec 008 CA1 : la sortie contient « Cadrage à faire »" "Cadrage à faire"

# CA2 : cahier des charges rempli, aucun plan (sert aussi de référence pour CA4)
c=$(new_case)
add_filled_cahier "$c"
check "Spec 008 CA2 : précondition, pas de docs/plan.md" not_exists "$c/clone/docs/plan.md"
run_hook "$c/clone"
printf '%s\n' "$output" >"$work/baseline-output"
check_code 0 "Spec 008 CA2 : code de sortie 0"
check_output_i "Spec 008 CA2 : la sortie contient « Plan absent »" "Plan absent"
check_no_output_i "Spec 008 CA2 : la sortie ne contient pas « Cadrage à faire »" "Cadrage à faire"

# CA3 : plan avec des cases cochées avant et après la première case ouverte
c=$(new_case)
add_filled_cahier "$c"
commit_file "$c/clone" docs/plan.md "# Plan

## Tâches

- [x] marqueur-cochee-avant-1
- [X] marqueur-cochee-avant-2
- [ ] marqueur-premiere-ouverte
- [x] marqueur-cochee-apres
- [ ] marqueur-seconde-ouverte" "docs: plan"
git -C "$c/clone" push -q origin main
run_hook "$c/clone"
check_code 0 "Spec 008 CA3 : code de sortie 0"
check "Spec 008 CA3 : la sortie contient la première ligne « - [ ] » du plan" \
  grep -qxF -- "- [ ] marqueur-premiere-ouverte" <<<"$output"
check_no_output_i "Spec 008 CA3 : aucune ligne cochée (avant)" "marqueur-cochee-avant"
check_no_output_i "Spec 008 CA3 : aucune ligne cochée (après)" "marqueur-cochee-apres"
check_no_output_i "Spec 008 CA3 : aucune case cochée « [x] »" "[x]"
check_no_output_i "Spec 008 CA3 : seule la première case ouverte est affichée" "marqueur-seconde-ouverte"
check_no_output_i "Spec 008 CA3 : ni « Plan absent » ni « Cadrage à faire » (plan présent)" "Plan absent"
check_no_output_i "Spec 008 CA3 : pas de « Cadrage à faire » (cahier rempli)" "Cadrage à faire"

# CA4 : plan sans aucune case ouverte, puis plan au format libre sans case
# Le libellé exact n'est pas imposé : au moins une ligne non vide en plus de la
# sortie de référence (CA2), sans « - [ ] », sans erreur, code 0.
for variant in "toutes cochées" "format libre"; do
  c=$(new_case)
  add_filled_cahier "$c"
  if [ "$variant" = "toutes cochées" ]; then
    plan_content="# Plan

- [x] marqueur-cochee-1
- [x] marqueur-cochee-2"
  else
    plan_content="# Plan de route

Phase 1 : socle. Phase 2 : écrans. Pas de liste à cocher."
  fi
  commit_file "$c/clone" docs/plan.md "$plan_content" "docs: plan"
  git -C "$c/clone" push -q origin main
  run_hook "$c/clone"
  check_code 0 "Spec 008 CA4 : code de sortie 0 ($variant)"
  extra=$(lines_not_in_baseline)
  check "Spec 008 CA4 : une ligne non vide dit l'état du plan ($variant)" \
    test -n "$extra"
  check "Spec 008 CA4 : aucune case ouverte « - [ ] » affichée ($variant)" \
    not_grep_i "- [ ]" "$output"
  check "Spec 008 CA4 : aucune erreur (stderr vide) ($variant)" equal "" "$errors"
  check "Spec 008 CA4 : aucun message d'erreur dans la sortie ($variant)" \
    not_grep_i "erreur" "$output"
  check_no_output_i "Spec 008 CA4 : pas de « Plan absent » ($variant)" "Plan absent"
  check_no_output_i "Spec 008 CA4 : pas de « Cadrage à faire » ($variant)" "Cadrage à faire"
done

# Revue de sécurité du 2026-10-14 : la case affichée est tronquée à 200 caractères
c=$(new_case)
add_filled_cahier "$c"
long_line="- [ ] marqueur-longue $(printf 'x%.0s' $(seq 1 300))"
commit_file "$c/clone" docs/plan.md "# Plan

$long_line" "docs: plan"
git -C "$c/clone" push -q origin main
run_hook "$c/clone"
check_code 0 "Spec 008 (revue de sécurité) : code de sortie 0"
shown=$(grep -F -- "- [ ] marqueur-longue" <<<"$output")
check "Spec 008 (revue de sécurité) : la case affichée est tronquée à 200 caractères" \
  test -n "$shown" -a "${#shown}" -le 200

# CA5 : aucun cahier des charges. Un journal sans les mots visés est présent pour
# que la sortie comporte une partie après le journal.
c=$(new_case)
git -C "$c/clone" checkout -q -b feat/sans-cahier
commit_file "$c/clone" docs/journal/2026-10-14-feat-sans-cahier.md "# Journal

## 2026-10-14 10:00

- Fait : marqueur-journal-sans-cahier" "docs: journal"
git -C "$c/clone" push -q -u origin feat/sans-cahier 2>/dev/null
check "Spec 008 CA5 : précondition, pas de cahier des charges" \
  not_exists "$c/clone/docs/cahier-des-charges-fonctionnel.md"
run_hook "$c/clone"
check_code 0 "Spec 008 CA5 : code de sortie 0"
check_output_i "Spec 008 CA5 : précondition, le journal est affiché" "marqueur-journal-sans-cahier"
check_no_output_i "Spec 008 CA5 : la sortie ne parle pas de cadrage" "cadrage"
check_no_output_i "Spec 008 CA5 : la sortie ne parle pas de plan" "plan"

exit $fail
