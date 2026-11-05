#!/usr/bin/env bash
# Vérifie scripts/verifier-avant-public.sh et la skill /publier selon la spec
# docs/specs/010-noms-exclus.md (CA9, CA10, CA11, et les cas limites « Références de
# PR », « Fichier .env suivi » et « Socle »), sur des dépôts temporaires.
#
# Contrat du script (validé par Yanis le 2026-11-05) :
# - `scripts/verifier-avant-public.sh`, sans argument, lancé dans un dépôt Git ;
# - il s'appuie sur `scripts/verifier-noms-exclus.sh` du même dépôt (le test copie
#   les deux scripts sous scripts/ dans chaque dépôt temporaire) ;
# - liste des noms : EXCLUDED_NAMES ou .excluded-names, comme le script de base ;
# - sortie 0 : dépôt publiable ; 1 : au moins un contrôle en échec ; 2 : usage ou
#   erreur (hors dépôt Git, argument inattendu). Une erreur ne vaut jamais succès ;
# - il dit ce qu'il a vérifié, en succès comme en échec. Fragments cherchés, sans
#   tenir compte de la casse : « noms exclus » et « historique » (noms sur tout
#   l'historique), « refs/pull » ou « références de PR », « .env » (fichiers suivis) ;
# - échec sur les références de PR : cite chaque PR concernée sous la forme « #7 »,
#   « PR 7 » ou « pull/7 », ne cite pas les PR propres, et renvoie vers le « support
#   GitHub » (marche à suivre) ;
# - échec sur un .env suivi : cite le chemin du fichier, jamais son contenu ;
# - les refs récupérées depuis origin sont temporaires : aucune ref locale nouvelle
#   ne reste après le script, en succès comme en échec ;
# - sans dépôt distant origin : le contrôle des refs de PR ne peut pas se faire, le
#   script le dit (mot « origin ») et sort en 1 (pas publiable) ;
# - sans liste de noms (verifier-noms-exclus.sh sortirait 0 avec un avertissement) :
#   sortie 1 et message « aucune liste » : on ne déclare pas publiable un dépôt
#   dans lequel on n'a rien cherché (principe 4 de la spec) ;
# - .excluded-names suivi par Git : sortie 1, le fichier est cité (hérité du script
#   de base).
#
# Contrôle par mutation (règle 2 de CLAUDE.md) : chaque protection (noms, refs de PR,
# .env, absence de liste, absence d'origin, nettoyage des refs) a un scénario qui
# échoue si on la désactive, et chaque scénario d'échec est précédé d'une
# précondition : le même dépôt, sans le défaut, doit réussir (sortie 0). Si le script
# est absent ou échoue toujours, la précondition échoue : aucun test ne passe à vide.
#
# CA11 : test de contenu de .claude/skills/publier/SKILL.md, pas de comportement.
#
# Seuls des noms inventés sont utilisés : Zorglub, Quibbler, Vantablex. Les fichiers
# d'environnement ont un contenu factice, et leur nom est construit par
# concaténation (hook protect-secrets.sh).
set -u

template="$(cd "$(dirname "$0")/.." && pwd -P)"
script="$template/scripts/verifier-avant-public.sh"
base_script="$template/scripts/verifier-noms-exclus.sh"
skill="$template/.claude/skills/publier/SKILL.md"
fail=0

if [ ! -f "$script" ]; then
  echo "ÉCHEC  $script est absent : toutes les vérifications du script vont échouer"
  fail=1
elif [ ! -x "$script" ]; then
  echo "ÉCHEC  $script n'est pas exécutable : toutes les vérifications du script vont échouer"
  fail=1
fi

if ! work=$(mktemp -d) || ! work=$(cd "$work" && pwd -P); then
  echo "Erreur : mktemp -d a échoué" >&2
  exit 1
fi
trap 'rm -rf "$work"' EXIT

unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE CI EXCLUDED_NAMES
unset GIT_AUTHOR_NAME GIT_AUTHOR_EMAIL GIT_COMMITTER_NAME GIT_COMMITTER_EMAIL
cat >"$work/gitconfig" <<'CONF'
[user]
	name = Test
	email = test@example.com
[init]
	defaultBranch = main
[commit]
	gpgsign = false
[protocol "file"]
	allow = always
CONF
export GIT_CONFIG_GLOBAL="$work/gitconfig"
export GIT_CONFIG_NOSYSTEM=1

names=(Zorglub Quibbler Vantablex)
list=$'Zorglub\nQuibbler\nVantablex'
neutral_list=$'Frobnitz\nGlorpax'

# Nom des fichiers d'environnement, par concaténation
dotenv=".""env"

# --- Outils de vérification -------------------------------------------------

stdout_file="$work/stdout"
stderr_file="$work/stderr"
output=""
code=0
refs_before=""
refs_after=""

pass() {
  echo "OK     $1"
}

failed() {
  echo "ÉCHEC  $1${2:+ ($2)}"
  fail=1
}

all_refs() {
  git -C "$1" for-each-ref --format='%(refname) %(objectname)'
}

# run_avp <dépôt> <liste> [arguments] : lance la copie du script du dépôt, hors CI
run_avp() {
  local repo=$1 names_list=$2
  shift 2
  refs_before=$(all_refs "$repo")
  (cd "$repo" && env -u CI EXCLUDED_NAMES="$names_list" scripts/verifier-avant-public.sh "$@") \
    >"$stdout_file" 2>"$stderr_file"
  code=$?
  output=$(cat "$stdout_file" "$stderr_file")
  refs_after=$(all_refs "$repo")
}

# Idem, sans variable EXCLUDED_NAMES du tout
run_avp_unset() {
  local repo=$1
  shift
  refs_before=$(all_refs "$repo")
  (cd "$repo" && env -u CI -u EXCLUDED_NAMES scripts/verifier-avant-public.sh "$@") \
    >"$stdout_file" 2>"$stderr_file"
  code=$?
  output=$(cat "$stdout_file" "$stderr_file")
  refs_after=$(all_refs "$repo")
}

file_leaks_a_name() {
  local file=$1 name
  for name in "$@"; do
    [ "$name" = "$file" ] && continue
    if grep -qiF -- "$name" "$file"; then
      echo "$name"
      return 0
    fi
  done
  return 1
}

write_file() {
  mkdir -p "$(dirname "$1/$2")"
  printf '%s\n' "$3" >"$1/$2"
}

commit_all() {
  git -C "$1" add -A
  git -C "$1" commit -q -m "$2"
}

# Dépôt propre sur main, avec les deux scripts copiés et suivis, et un dépôt nu
# origin qui a reçu main. Les chemins sont : dépôt et $repo.origin
new_repo() {
  local r bare
  r=$(mktemp -d "$work/repo.XXXXXX")
  bare="$r.origin"
  git init -q -b main "$r"
  write_file "$r" README.md "Projet de test"
  mkdir -p "$r/scripts"
  cp "$base_script" "$r/scripts/" 2>/dev/null || true
  cp "$script" "$r/scripts/" 2>/dev/null || true
  commit_all "$r" "chore: initialisation"
  git init -q --bare -b main "$bare"
  git -C "$r" remote add origin "$bare"
  git -C "$r" push -q origin main
  echo "$r"
}

# push_pr <dépôt> <numéro> <chemin> <contenu> : crée dans origin refs/pull/<n>/head
# sur un commit qu'aucune branche n'atteint, ni dans origin ni dans le dépôt local
push_pr() {
  local r=$1 n=$2
  git -C "$r" checkout -q -b tmp-pr
  write_file "$r" "$3" "$4"
  commit_all "$r" "docs: contenu de la PR $n"
  git -C "$r" push -q origin "HEAD:refs/pull/$n/head"
  git -C "$r" checkout -q main
  git -C "$r" branch -q -D tmp-pr
}

# expect_code <libellé> <code attendu>
expect_code() {
  if [ "$code" -eq "$2" ]; then
    pass "$1"
  else
    failed "$1" "attendu $2, obtenu $code : $(head -n 1 <<<"$output")"
  fi
}

# precondition <libellé> <dépôt> : le dépôt réussit avec une liste neutre
precondition() {
  run_avp "$2" "$neutral_list"
  expect_code "Mutation : précondition, dépôt sans défaut accepté ($1)" 0
}

# output_has <libellé> <regex étendue> : insensible à la casse
output_has() {
  if grep -qiE -- "$2" <<<"$output"; then
    pass "$1"
  else
    failed "$1" "motif « $2 » absent de la sortie : $(head -n 1 <<<"$output")"
  fi
}

# verify_refused <CA> <libellé> [regex...] : sortie 1 exactement, chaque motif
# présent dans la sortie, aucun nom divulgué (sortie non vide exigée)
verify_refused() {
  local ca=$1 label=$2 pattern leaked
  shift 2
  if [ "$code" -ne 1 ]; then
    failed "$ca : $label" "attendu 1, obtenu $code : $(head -n 1 <<<"$output")"
    failed "$ca : $label, aucun nom divulgué" "pas d'échec (code $code) : contrôle sans objet"
    return
  fi
  pass "$ca : $label, code 1"
  for pattern in "$@"; do
    output_has "$ca : $label, la sortie contient « $pattern »" "$pattern"
  done
  if [ -z "$output" ]; then
    failed "$ca : $label, aucun nom divulgué" "sortie vide : le script doit dire ce qu'il a trouvé"
  elif leaked=$(file_leaks_a_name "$stdout_file" "${names[@]}"); then
    failed "$ca : $label, aucun nom divulgué" "le nom $leaked apparaît dans la sortie standard"
  elif leaked=$(file_leaks_a_name "$stderr_file" "${names[@]}"); then
    failed "$ca : $label, aucun nom divulgué" "le nom $leaked apparaît dans la sortie d'erreur"
  else
    pass "$ca : $label, aucun nom divulgué"
  fi
}

# Les refs récupérées depuis origin ne restent pas dans le dépôt. Exige le code de
# sortie attendu du script : sans lui, « rien n'a changé » ne prouverait rien.
# verify_refs_clean <libellé> <code attendu>
verify_refs_clean() {
  if [ "$code" -ne "$2" ]; then
    failed "$1 : aucune ref ne reste dans le dépôt après le script" "script non abouti (code $code, attendu $2) : contrôle sans objet"
  elif [ -n "$refs_before" ] && [ "$refs_before" = "$refs_after" ]; then
    pass "$1 : aucune ref ne reste dans le dépôt après le script"
  else
    failed "$1 : aucune ref ne reste dans le dépôt après le script" \
      "refs avant et après différentes : $(diff <(echo "$refs_before") <(echo "$refs_after") | head -n 3 | tr '\n' ' ')"
  fi
}

# --- CA9 : dépôt publiable ---------------------------------------------------

r=$(new_repo)
push_pr "$r" 8 docs/pr-8.md "Contenu neutre de la PR 8"
push_pr "$r" 9 docs/pr-9.md "Contenu neutre de la PR 9"
run_avp "$r" "$list"
expect_code "CA9 : dépôt propre, refs de PR propres, sortie 0" 0
output_has "CA9 : la sortie dit que les noms exclus ont été vérifiés sur l'historique" \
  "noms exclus.*historique|historique.*noms exclus"
output_has "CA9 : la sortie dit que les références de PR ont été vérifiées" \
  "références de PR|refs/pull"
output_has "CA9 : la sortie dit que les fichiers .env suivis ont été vérifiés" "\\.env"
# Lignes du bilan, pas seulement les en-têtes de section
output_has "CA9 : bilan, ligne OK des noms exclus" "^ *OK +noms exclus"
output_has "CA9 : bilan, ligne OK des références de PR" "^ *OK +références de PR : 2 PR"
output_has "CA9 : bilan, ligne OK des fichiers .env" "^ *OK +fichiers \\.env"
verify_refs_clean "CA9 (succès)" 0

# --- CA9 : noms exclus dans l'historique -------------------------------------

r=$(new_repo)
git -C "$r" checkout -q -b feat/non-fusionnee
write_file "$r" docs/notes.md "Réunion avec Vantablex demain"
commit_all "$r" "docs: notes"
sha=$(git -C "$r" rev-parse HEAD)
git -C "$r" checkout -q main
precondition "nom sur une branche non fusionnée" "$r"
run_avp "$r" "$list"
verify_refused CA9 "nom sur une branche non fusionnée" "noms exclus" "${sha:0:7}"
verify_refs_clean "CA9 (échec noms)" 1

# --- CA9 : fichier .env suivi ------------------------------------------------

for rel in "$dotenv" "$dotenv.local" "config/$dotenv"; do
  r=$(new_repo)
  precondition "avant l'ajout de $rel" "$r"
  write_file "$r" "$rel" "FAKE_VALUE=valeur-factice"
  commit_all "$r" "chore: fichier ajouté par erreur"
  run_avp "$r" "$list"
  verify_refused CA9 "fichier $rel suivi, chemin cité" "$rel"
  if [ "$code" -ne 1 ]; then
    failed "CA9 : fichier $rel suivi, contenu non affiché" "pas d'échec (code $code) : contrôle sans objet"
  elif grep -qF -- "valeur-factice" <<<"$output"; then
    failed "CA9 : fichier $rel suivi, contenu non affiché" "le contenu du fichier apparaît dans la sortie"
  else
    pass "CA9 : fichier $rel suivi, contenu non affiché"
  fi
done

# Seul le modèle est suivi : publiable
r=$(new_repo)
write_file "$r" "$dotenv.example" "FAKE_VALUE=remplacez-moi"
commit_all "$r" "chore: modèle d'environnement"
run_avp "$r" "$list"
expect_code "Cas limite : $dotenv.example seul est suivi, sortie 0" 0

# --- CA10 : références de PR qui exposent un ancien commit -------------------

r=$(new_repo)
push_pr "$r" 7 docs/ancien.md "Ancienne réunion avec Quibbler"
push_pr "$r" 8 docs/pr-8.md "Contenu neutre de la PR 8"
old_sha=$(git -C "$r.origin" rev-parse refs/pull/7/head)
if [ -z "$(git -C "$r.origin" branch --contains "$old_sha")" ] &&
  ! git -C "$r" rev-list --all | grep -qx "$old_sha"; then
  pass "CA10 : précondition, aucune branche ni locale ni distante n'atteint l'ancien commit"
else
  failed "CA10 : précondition, aucune branche ni locale ni distante n'atteint l'ancien commit"
fi
precondition "refs de PR avec un nom, liste neutre" "$r"
run_avp "$r" "$list"
verify_refused CA10 "historique propre, PR 7 expose un nom" \
  "(#|PR |pull/)7([^0-9]|$)" "support GitHub"
if [ "$code" -ne 1 ]; then
  failed "CA10 : la PR propre 8 n'est pas citée" "pas d'échec (code $code) : contrôle sans objet"
elif grep -qiE -- "(#|PR |pull/)8([^0-9]|$)" <<<"$output"; then
  failed "CA10 : la PR propre 8 n'est pas citée" "la PR 8 apparaît dans la sortie"
else
  pass "CA10 : la PR propre 8 n'est pas citée"
fi
# L'historique est propre : seule la purge des références règle le cas, pas une
# réécriture
if [ "$code" -eq 1 ] && grep -qE -- "^ *OK +noms exclus" <<<"$output" &&
  ! grep -qi -- "réécrire l'historique" <<<"$output"; then
  pass "CA10 : historique propre, le contrôle des noms exclus reste OK"
else
  failed "CA10 : historique propre, le contrôle des noms exclus reste OK" "code $code ou réécriture demandée à tort"
fi
verify_refs_clean "CA10 (échec)" 1

# Seuls les commits qu'aucune branche n'atteint sont attribués à une PR : un nom
# dans un ancien commit de main ne fait pas citer une PR propre dérivée de main
r=$(new_repo)
write_file "$r" docs/vieux.md "Ancien compte rendu Quibbler"
commit_all "$r" "docs: compte rendu"
git -C "$r" rm -q docs/vieux.md
commit_all "$r" "docs: retrait du compte rendu"
git -C "$r" push -q origin main
push_pr "$r" 8 docs/pr-8.md "Contenu neutre de la PR 8"
run_avp "$r" "$list"
verify_refused "Cas limite" "nom dans un ancien commit de main" "noms exclus"
if [ "$code" -eq 1 ] && ! grep -qiE -- "(#|PR |pull/)8([^0-9]|$)" <<<"$output"; then
  pass "Cas limite : nom dans main, la PR propre 8 n'est pas citée"
else
  failed "Cas limite : nom dans main, la PR propre 8 n'est pas citée" "code $code ou PR 8 citée"
fi

# Un nom dans un fichier suivi ne fait pas citer les PR propres
r=$(new_repo)
write_file "$r" docs/actuel.md "Contrat Zorglub"
commit_all "$r" "docs: contrat"
git -C "$r" push -q origin main
push_pr "$r" 8 docs/pr-8.md "Contenu neutre de la PR 8"
run_avp "$r" "$list"
verify_refused "Cas limite" "nom dans un fichier suivi" "noms exclus"
if [ "$code" -eq 1 ] && ! grep -qiE -- "(#|PR |pull/)8([^0-9]|$)" <<<"$output"; then
  pass "Cas limite : nom dans un fichier suivi, la PR propre 8 n'est pas citée"
else
  failed "Cas limite : nom dans un fichier suivi, la PR propre 8 n'est pas citée" "code $code ou PR 8 citée"
fi

# --- Cas limite : pas de dépôt distant origin --------------------------------

r=$(new_repo)
precondition "avec origin" "$r"
git -C "$r" remote remove origin
run_avp "$r" "$list"
verify_refused "Cas limite" "sans origin, contrôle des refs de PR non fait" "pas de dépôt (distant )?origin"

# Récupération impossible depuis origin : erreur, et l'URL n'est pas affichée
r=$(new_repo)
git -C "$r" remote set-url origin "$work/inexistant-zorglub"
run_avp "$r" "$list"
expect_code "Cas limite : origin injoignable, sortie 2" 2
if leaked=$(file_leaks_a_name "$stdout_file" "${names[@]}") ||
  leaked=$(file_leaks_a_name "$stderr_file" "${names[@]}"); then
  failed "Cas limite : origin injoignable, l'URL n'est pas affichée" "le nom $leaked apparaît"
elif [ "$code" -eq 2 ]; then
  pass "Cas limite : origin injoignable, l'URL n'est pas affichée"
else
  failed "Cas limite : origin injoignable, l'URL n'est pas affichée" "pas d'erreur (code $code) : contrôle sans objet"
fi

# Script de base absent : erreur, jamais un succès
r=$(new_repo)
rm -f "$r/scripts/verifier-noms-exclus.sh"
run_avp "$r" "$list"
expect_code "Cas limite : verifier-noms-exclus.sh absent, sortie 2" 2

# --- Cas limite : pas de liste de noms ---------------------------------------

r=$(new_repo)
precondition "avec une liste" "$r"
push_pr "$r" 8 docs/pr-8.md "Contenu neutre de la PR 8"
run_avp_unset "$r"
verify_refused "Cas limite" "sans liste de noms" "aucune liste"
# Sans liste, rien n'a été cherché dans les PR non plus : pas de ligne « OK »
if [ "$code" -eq 1 ] && ! grep -qE -- "^ *OK +références de PR" <<<"$output"; then
  pass "Cas limite : sans liste, les références de PR ne sont pas déclarées vérifiées"
else
  failed "Cas limite : sans liste, les références de PR ne sont pas déclarées vérifiées" "code $code ou ligne OK présente"
fi
run_avp "$r" $'\n  \n'
verify_refused "Cas limite" "liste faite de lignes blanches" "aucune liste"
(cd "$r" && CI=true env -u EXCLUDED_NAMES scripts/verifier-avant-public.sh) \
  >"$stdout_file" 2>"$stderr_file"
code=$?
output=$(cat "$stdout_file" "$stderr_file")
verify_refused "Cas limite" "sans liste en CI" "aucune liste"
# Une liste dans .excluded-names (non suivi) est une liste
printf 'Frobnitz\n' >"$r/.excluded-names"
run_avp_unset "$r"
expect_code "Cas limite : liste lue dans .excluded-names non suivi, sortie 0" 0

# --- .excluded-names suivi (hérité de verifier-noms-exclus.sh) ---------------

r=$(new_repo)
precondition "avant l'ajout de .excluded-names" "$r"
write_file "$r" .excluded-names "$list"
commit_all "$r" "chore: fichier ajouté par erreur"
run_avp "$r" "$neutral_list"
verify_refused "Cas limite" ".excluded-names suivi par Git" "\\.excluded-names"

# --- Usage et erreurs : jamais un succès --------------------------------------

r=$(new_repo)
run_avp "$r" "$neutral_list" argument-inattendu
expect_code "Cas limite : argument inattendu, sortie 2" 2

not_repo=$(mktemp -d "$work/hors-depot.XXXXXX")
(cd "$not_repo" && env -u CI EXCLUDED_NAMES="$neutral_list" "$script") >"$stdout_file" 2>"$stderr_file"
code=$?
output=$(cat "$stdout_file" "$stderr_file")
expect_code "Cas limite : hors dépôt Git, sortie 2" 2

# --- Revue de sécurité : ce que le dépôt distant expose -----------------------

# Branche présente seulement dans origin (poussée d'un autre poste) : c'est le
# dépôt distant qui devient public, pas le clone local
r=$(new_repo)
precondition "avant la branche distante" "$r"
git -C "$r" checkout -q -b autre-poste
write_file "$r" docs/autre.md "Compte rendu Zorglub"
commit_all "$r" "docs: notes d'un autre poste"
remote_sha=$(git -C "$r" rev-parse HEAD)
git -C "$r" push -q origin autre-poste
git -C "$r" checkout -q main
git -C "$r" branch -q -D autre-poste
git -C "$r" update-ref -d refs/remotes/origin/autre-poste 2>/dev/null
if git -C "$r" cat-file -e "$remote_sha" 2>/dev/null &&
  git -C "$r" rev-list --all | grep -qx "$remote_sha"; then
  failed "Revue sécurité : précondition, le commit n'est atteint par aucune ref locale"
else
  pass "Revue sécurité : précondition, le commit n'est atteint par aucune ref locale"
fi
run_avp "$r" "$list"
verify_refused "Revue sécurité" "nom sur une branche présente seulement dans origin" "noms exclus"
verify_refs_clean "Revue sécurité (branche distante)" 1

# Étiquette présente seulement dans origin
r=$(new_repo)
git -C "$r" checkout -q -b tmp-tag
write_file "$r" docs/tag.md "Livraison Quibbler"
commit_all "$r" "docs: livraison"
git -C "$r" push -q origin "HEAD:refs/tags/v0.1"
git -C "$r" checkout -q main
git -C "$r" branch -q -D tmp-tag
git -C "$r" tag -d v0.1 >/dev/null 2>&1
run_avp "$r" "$list"
verify_refused "Revue sécurité" "nom sur une étiquette présente seulement dans origin" "noms exclus"

# Clone superficiel : rev-list --all s'y arrête sans erreur, jamais un succès
r=$(new_repo)
shallow=$(mktemp -d "$work/shallow.XXXXXX")
rmdir "$shallow"
git clone -q --depth 1 "file://$r.origin" "$shallow" 2>/dev/null
run_avp "$shallow" "$neutral_list"
expect_code "Revue sécurité : clone superficiel, sortie 2" 2
output_has "Revue sécurité : clone superficiel, la sortie le dit" "superficiel|shallow"

# refs/pull/N/merge seule atteint le commit refusé
r=$(new_repo)
git -C "$r" checkout -q -b tmp-merge
write_file "$r" docs/fusion.md "Fusion pour Vantablex"
commit_all "$r" "docs: fusion de test"
git -C "$r" push -q origin "HEAD:refs/pull/12/merge"
git -C "$r" checkout -q main
git -C "$r" branch -q -D tmp-merge
precondition "refs/pull/12/merge, liste neutre" "$r"
run_avp "$r" "$list"
verify_refused "Revue sécurité" "refs/pull/12/merge expose un nom" "(#|PR |pull/)12([^0-9]|$)"
if [ "$code" -eq 1 ] && grep -qE -- "#12/" <<<"$output"; then
  failed "Revue sécurité : numéro de PR cité sans suffixe" "« #12/... » dans la sortie"
elif [ "$code" -eq 1 ]; then
  pass "Revue sécurité : numéro de PR cité sans suffixe"
else
  failed "Revue sécurité : numéro de PR cité sans suffixe" "pas d'échec (code $code) : contrôle sans objet"
fi

# Aucune référence de PR : pas présenté comme « vérifiées »
r=$(new_repo)
run_avp "$r" "$list"
expect_code "Revue sécurité : aucune référence de PR, sortie 0" 0
output_has "Revue sécurité : aucune référence de PR, la sortie le dit" "aucune référence de PR"

# Chemin d'un fichier d'environnement qui contient un nom : jamais affiché
r=$(new_repo)
write_file "$r" "config/zorglub/$dotenv.local" "FAKE_VALUE=valeur-factice"
commit_all "$r" "chore: fichier ajouté par erreur"
run_avp "$r" "$list"
verify_refused "Revue sécurité" "nom dans le chemin d'un fichier $dotenv suivi" "$dotenv"

# Ce que le script ne vérifie pas est dit, en succès comme en échec
r=$(new_repo)
run_avp "$r" "$list"
output_has "Revue sécurité : le bilan liste ce qui n'est pas vérifié" "non vérifié"
output_has "Revue sécurité : le bilan cite les titres et descriptions de PR et les issues" \
  "issues"

# Refs temporaires laissées par un lancement interrompu : supprimées au départ
r=$(new_repo)
git -C "$r" update-ref refs/verifier-avant-public-99999/pull/1/head HEAD
run_avp "$r" "$list"
if git -C "$r" for-each-ref --format='%(refname)' | grep -q '^refs/verifier-avant-public-'; then
  failed "Revue sécurité : refs temporaires orphelines supprimées"
else
  pass "Revue sécurité : refs temporaires orphelines supprimées"
fi
# ... et supprimées avant le contrôle : une ancienne ref de PR orpheline ne doit
# pas être relue comme un historique à réécrire
r=$(new_repo)
git -C "$r" checkout -q -b tmp-orpheline
write_file "$r" docs/orphelin.md "Note Vantablex"
commit_all "$r" "docs: note"
git -C "$r" update-ref refs/verifier-avant-public-99999/pull/3/head HEAD
git -C "$r" checkout -q main
git -C "$r" branch -q -D tmp-orpheline
run_avp "$r" "$list"
expect_code "Revue sécurité : ref orpheline supprimée avant le contrôle, sortie 0" 0

# --- CA11 : skill /publier (test de contenu) ----------------------------------

if [ -f "$skill" ]; then
  pass "CA11 : .claude/skills/publier/SKILL.md existe"
else
  failed "CA11 : .claude/skills/publier/SKILL.md existe"
fi

# Front-matter : première ligne « --- », name et description avant la fermeture
front=$(awk 'NR == 1 && $0 != "---" { exit } NR > 1 && $0 == "---" { exit } NR > 1 { print }' "$skill" 2>/dev/null)
if grep -qx 'name: publier' <<<"$front"; then
  pass "CA11 : front-matter, name: publier"
else
  failed "CA11 : front-matter, name: publier"
fi
if grep -qE '^description: *[^ ]' <<<"$front"; then
  pass "CA11 : front-matter, description non vide"
else
  failed "CA11 : front-matter, description non vide"
fi

skill_has() {
  [ -f "$skill" ] && grep -qiE -- "$2" "$skill"
}
if skill_has x 'scripts/verifier-avant-public\.sh'; then
  pass "CA11 : la skill cite scripts/verifier-avant-public.sh"
else
  failed "CA11 : la skill cite scripts/verifier-avant-public.sh"
fi
if skill_has x 'refuse|ne propose (jamais|pas)|ne jamais proposer'; then
  pass "CA11 : la skill refuse de proposer la mise en public"
else
  failed "CA11 : la skill refuse de proposer la mise en public" "ni « refuse » ni « ne propose pas »"
fi
if skill_has x 'tant qu.*(échou|échec)'; then
  pass "CA11 : le refus vaut « tant que » le script échoue"
else
  failed "CA11 : le refus vaut « tant que » le script échoue" "aucune ligne « tant qu... échoue/échec »"
fi

# Chaque ligne qui cite la commande de mise en public a, à deux lignes près,
# une interdiction explicite (« jamais ») ; aucune exécution automatique ni
# autorisation d'outil
if [ -f "$skill" ] && grep -qF -- "gh repo edit" "$skill"; then
  pass "CA11 : la skill cite la commande gh repo edit (action de l'humain)"
else
  failed "CA11 : la skill cite la commande gh repo edit (action de l'humain)"
fi
unguarded=$(awk '
  { line[NR] = $0 }
  END {
    for (i = 1; i <= NR; i++) {
      if (index(line[i], "gh repo edit") == 0) continue
      ok = 0
      for (j = i - 2; j <= i + 2; j++) {
        if (j >= 1 && j <= NR && tolower(line[j]) ~ /jamais/) ok = 1
      }
      if (!ok) print i
    }
  }' "$skill" 2>/dev/null)
if [ -f "$skill" ] && [ -z "$unguarded" ]; then
  pass "CA11 : chaque mention de gh repo edit est encadrée par un « jamais »"
else
  failed "CA11 : chaque mention de gh repo edit est encadrée par un « jamais »" "lignes sans interdiction : ${unguarded:-fichier absent}"
fi
if skill_has x 'ne lance jamais|ne (la )?lance (jamais|pas)|ne jamais lancer'; then
  pass "CA11 : phrase explicite « ne lance jamais » la commande"
else
  failed "CA11 : phrase explicite « ne lance jamais » la commande"
fi
if [ -f "$skill" ] && ! grep -qE -- '!`.*gh repo edit|allowed-tools:.*gh repo edit' "$skill"; then
  pass "CA11 : la skill n'exécute ni n'autorise gh repo edit"
else
  failed "CA11 : la skill n'exécute ni n'autorise gh repo edit"
fi

# Revue de sécurité : la liste est l'affaire de l'humain, jamais de l'agent
if skill_has x "seul l.humain (crée|cré|remplit|écrit)"; then
  pass "Revue sécurité : seul l'humain crée la liste des noms"
else
  failed "Revue sécurité : seul l'humain crée la liste des noms"
fi
if skill_has x "un nom inventé suffit"; then
  failed "Revue sécurité : la skill n'invite pas à une liste factice"
else
  pass "Revue sécurité : la skill n'invite pas à une liste factice"
fi
# Le dépôt à rendre public est nommé, pas laissé au choix de gh
if [ -f "$skill" ] && grep -qE -- 'gh repo edit [A-Z<]' "$skill"; then
  pass "Revue sécurité : la commande de mise en public nomme le dépôt"
else
  failed "Revue sécurité : la commande de mise en public nomme le dépôt"
fi
if skill_has x "non vérifié"; then
  pass "Revue sécurité : la skill fait relire ce qui n'est pas vérifié"
else
  failed "Revue sécurité : la skill fait relire ce qui n'est pas vérifié"
fi

# Garantie technique, pas seulement le texte de la skill : l'agent ne peut ni
# lire la liste des noms ni changer la visibilité du dépôt (deny de settings.json)
settings="$template/.claude/settings.json"
for rule in 'Read(./.excluded-names)' 'Edit(./.excluded-names)' 'Bash(gh repo edit *)'; do
  # Dans permissions.deny précisément : ailleurs (allow), la règle autoriserait
  if [ -f "$settings" ] && jq -e --arg r "$rule" '.permissions.deny | index($r)' "$settings" >/dev/null 2>&1; then
    pass "Revue sécurité : $rule interdit dans .claude/settings.json"
  else
    failed "Revue sécurité : $rule interdit dans .claude/settings.json"
  fi
done

exit $fail
