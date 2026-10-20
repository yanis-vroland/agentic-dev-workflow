#!/usr/bin/env bash
# Vérifie scripts/verifier-noms-exclus.sh selon la spec docs/specs/010-noms-exclus.md
# (CA3 à CA8 et CA14), sur des dépôts temporaires. Chaque vérification cite le
# critère d'acceptation (CAn) ou le cas limite testé.
#
# Contrat attendu du script (spec 010) : lancé depuis la racine d'un dépôt,
# `scripts/verifier-noms-exclus.sh [plage | --all]`, liste dans EXCLUDED_NAMES
# (une par ligne) ou dans .excluded-names. Sortie 0 : rien trouvé ou pas de
# liste ; sortie 1 : nom trouvé ; sortie 2 : usage ou liste invalide (nom trop
# court). Le test exige 1 pour un nom trouvé, jamais « un code non nul ».
#
# CA14 : chaque scénario en échec est précédé d'une précondition, la même
# situation avec une liste neutre doit réussir (sortie 0). Si le script est
# absent, cassé, ou échoue toujours, la précondition échoue : aucun test ne peut
# passer à vide.
#
# Seuls des noms inventés sont utilisés : Zorglub, Quibbler, Vantablex.
set -u

template="$(cd "$(dirname "$0")/.." && pwd -P)"
script="$template/scripts/verifier-noms-exclus.sh"
fail=0

if [ ! -f "$script" ]; then
  echo "ÉCHEC  $script est absent : toutes les vérifications vont échouer"
  fail=1
elif [ ! -x "$script" ]; then
  echo "ÉCHEC  $script n'est pas exécutable : toutes les vérifications vont échouer"
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

# Isole les tests de la configuration Git et de l'environnement de l'appelant
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
CONF
export GIT_CONFIG_GLOBAL="$work/gitconfig"
export GIT_CONFIG_NOSYSTEM=1

# Noms inventés de la liste, et liste neutre qui ne correspond à rien
names=(Zorglub Quibbler Vantablex)
list=$'Zorglub\nQuibbler\nVantablex'
neutral_list=$'Frobnitz\nGlorpax'

# --- Outils de vérification -------------------------------------------------

stdout_file="$work/stdout"
stderr_file="$work/stderr"
output="" # sortie standard et sortie d'erreur réunies
code=0

pass() {
  echo "OK     $1"
}

failed() {
  echo "ÉCHEC  $1${2:+ ($2)}"
  fail=1
}

# Lance le script depuis la racine du dépôt, sans CI, avec la liste donnée
# run_script <dépôt> <liste> [arguments du script]
run_script() {
  local repo=$1 names_list=$2
  shift 2
  (cd "$repo" && env -u CI EXCLUDED_NAMES="$names_list" "$script" "$@") >"$stdout_file" 2>"$stderr_file"
  code=$?
  output=$(cat "$stdout_file" "$stderr_file")
}

# Idem, sans variable EXCLUDED_NAMES du tout
# run_script_unset <dépôt> [arguments du script]
run_script_unset() {
  local repo=$1
  shift
  (cd "$repo" && env -u CI -u EXCLUDED_NAMES "$script" "$@") >"$stdout_file" 2>"$stderr_file"
  code=$?
  output=$(cat "$stdout_file" "$stderr_file")
}

# Un nom de la liste apparaît-il, sans tenir compte de la casse, dans le fichier ?
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

# write_file <dépôt> <chemin> <contenu>
write_file() {
  mkdir -p "$(dirname "$1/$2")"
  printf '%s\n' "$3" >"$1/$2"
}

commit_all() {
  git -C "$1" add -A
  git -C "$1" commit -q -m "$2"
}

# Nouveau dépôt : main avec un README neutre ; affiche son chemin
new_repo() {
  local r
  r=$(mktemp -d "$work/repo.XXXXXX")
  git init -q -b main "$r"
  write_file "$r" README.md "Projet de test"
  commit_all "$r" "chore: initialisation"
  echo "$r"
}

# Dépôt dont main contient un fichier suivi ; la plage main..HEAD est vide, seule
# la recherche dans les fichiers suivis est exercée.
# repo_with_file <chemin> <contenu>
repo_with_file() {
  local r
  r=$(new_repo)
  write_file "$r" "$1" "$2"
  commit_all "$r" "docs: ajout de notes"
  echo "$r"
}

# Crée la branche feat/pr. Le SHA d'un commit se lit avec git rev-parse HEAD.
start_branch() {
  git -C "$1" checkout -q -b feat/pr
}

# precondition <libellé> <dépôt> [arguments du script]
# CA14 : le script tourne et réussit sur ce dépôt avec une liste neutre.
precondition() {
  local label=$1 repo=$2
  shift 2
  run_script "$repo" "$neutral_list" "$@"
  if [ "$code" -eq 0 ]; then
    pass "CA14 : précondition, liste neutre acceptée ($label)"
  else
    failed "CA14 : précondition, liste neutre acceptée ($label)" "attendu 0, obtenu $code : $(head -n 1 <<<"$output")"
  fi
}

# verify_refused <CA> <libellé> <fragment ou vide> : vérifie le dernier lancement
# Sortie 1 exactement, fragment (fichier ou identifiant de commit) cité, puis
# CA8 : aucun nom de la liste, ni dans la sortie standard ni dans la sortie
# d'erreur. Le contrôle CA8 exige un vrai échec avec une sortie non vide, sinon
# une sortie vide passerait sans rien prouver.
verify_refused() {
  local ca=$1 label=$2 fragment=$3 leaked
  if [ "$code" -ne 1 ]; then
    failed "$ca : $label" "attendu 1, obtenu $code : $(head -n 1 <<<"$output")"
    failed "CA8 : $label, aucun nom divulgué" "pas d'échec (code $code) : contrôle sans objet"
    return
  fi
  if [ -n "$fragment" ] && ! grep -qF -- "$fragment" <<<"$output"; then
    failed "$ca : $label" "fragment « $fragment » absent de la sortie : $(head -n 1 <<<"$output")"
  else
    pass "$ca : $label"
  fi
  if [ -z "$output" ]; then
    failed "CA8 : $label, aucun nom divulgué" "sortie vide : le script doit dire ce qu'il a trouvé"
    return
  fi
  if leaked=$(file_leaks_a_name "$stdout_file" "${names[@]}"); then
    failed "CA8 : $label, aucun nom divulgué" "le nom $leaked apparaît dans la sortie standard"
  elif leaked=$(file_leaks_a_name "$stderr_file" "${names[@]}"); then
    failed "CA8 : $label, aucun nom divulgué" "le nom $leaked apparaît dans la sortie d'erreur"
  else
    pass "CA8 : $label, aucun nom divulgué"
  fi
}

# refused_case <CA> <libellé> <dépôt> <fragment ou vide> [arguments du script]
# Précondition CA14 (liste neutre, réussite), puis lancement avec la vraie liste.
refused_case() {
  local ca=$1 label=$2 repo=$3 fragment=$4
  shift 4
  precondition "$label" "$repo" "$@"
  run_script "$repo" "$list" "$@"
  verify_refused "$ca" "$label" "$fragment"
}

# --- CA3 : pas de liste ------------------------------------------------------

# Dépôt qui contient un des noms : sans liste, il ne peut rien être reproché
r=$(repo_with_file docs/notes.md "Réunion avec Zorglub demain")
precondition "CA3, dépôt qui contient un nom" "$r" main..HEAD
run_script "$r" "Zorglub" main..HEAD
if [ "$code" -eq 1 ]; then
  pass "CA14 : précondition, le même dépôt est refusé avec la liste Zorglub (CA3)"
else
  failed "CA14 : précondition, le même dépôt est refusé avec la liste Zorglub (CA3)" "attendu 1, obtenu $code : $(head -n 1 <<<"$output")"
fi
run_script_unset "$r" main..HEAD
if [ "$code" -eq 0 ] && grep -qi -- "liste" <<<"$output"; then
  pass "CA3 : sans EXCLUDED_NAMES ni .excluded-names, avertissement et succès"
else
  failed "CA3 : sans EXCLUDED_NAMES ni .excluded-names, avertissement et succès" "code $code, sortie : $(head -n 1 <<<"$output")"
fi

# --- Cas limite : liste vide ou de lignes blanches = absence de liste --------

for blank in "" $'\n\n' $'  \n\t\n   '; do
  r=$(repo_with_file docs/notes.md "Réunion avec Zorglub demain")
  run_script "$r" "$blank" main..HEAD
  if [ "$code" -eq 0 ] && grep -qi -- "liste" <<<"$output"; then
    pass "Cas limite : EXCLUDED_NAMES vide ou blanche traitée comme absente (CA3)"
  else
    failed "Cas limite : EXCLUDED_NAMES vide ou blanche traitée comme absente (CA3)" "code $code, sortie : $(head -n 1 <<<"$output")"
  fi
done

r=$(repo_with_file docs/notes.md "Réunion avec Zorglub demain")
printf '\n  \n\n' >"$r/.excluded-names"
run_script_unset "$r" main..HEAD
if [ "$code" -eq 0 ] && grep -qi -- "liste" <<<"$output"; then
  pass "Cas limite : .excluded-names fait de lignes blanches traité comme absent (CA3)"
else
  failed "Cas limite : .excluded-names fait de lignes blanches traité comme absent (CA3)" "code $code, sortie : $(head -n 1 <<<"$output")"
fi

# --- Cas limite : nom de moins de 3 caractères -------------------------------

# Le dépôt ne contient aucun des noms passés : sans la protection, le script
# conclurait « rien trouvé » (code 0) et le test passerait à vide.
r=$(repo_with_file docs/notes.md "Contenu neutre, sans aucun nom de la liste")
precondition "nom court" "$r" main..HEAD
run_script "$r" $'Frobnitz\nqz' main..HEAD
if [ "$code" -eq 2 ] && grep -qF -- "moins de 3 caractères" <<<"$output"; then
  pass "Cas limite : nom de moins de 3 caractères refusé par le script (code 2)"
else
  failed "Cas limite : nom de moins de 3 caractères refusé par le script (code 2)" "attendu 2, obtenu $code : $(head -n 1 <<<"$output")"
fi
# Le refus est un échec : le nom court ne doit pas apparaître non plus (CA8)
if [ "$code" -eq 2 ] && [ -n "$output" ] && ! grep -qiF -- "qz" <<<"$output"; then
  pass "CA8 : nom trop court refusé, aucun nom divulgué"
else
  failed "CA8 : nom trop court refusé, aucun nom divulgué" "code $code, sortie : $(head -n 1 <<<"$output")"
fi

# --- CA4 : nom dans le contenu d'un fichier suivi ----------------------------

r=$(repo_with_file docs/notes.md "Réunion avec Zorglub demain")
refused_case CA4 "nom dans le contenu d'un fichier suivi, fichier nommé" "$r" "docs/notes.md" main..HEAD

# Plusieurs noms de la liste dans le même fichier
r=$(repo_with_file docs/notes.md "Zorglub, Quibbler et Vantablex dans le même fichier")
refused_case CA4 "plusieurs noms dans un fichier, fichier nommé" "$r" "docs/notes.md" main..HEAD

# Liste lue dans .excluded-names, non versionné
r=$(repo_with_file docs/notes.md "Réunion avec Quibbler demain")
printf 'Frobnitz\n\nQuibbler\n' >"$r/.excluded-names"
run_script_unset "$r" main..HEAD
if [ "$code" -eq 1 ] && grep -qF -- "docs/notes.md" <<<"$output"; then
  pass "CA4 : liste lue dans .excluded-names, fichier nommé"
else
  failed "CA4 : liste lue dans .excluded-names, fichier nommé" "code $code : $(head -n 1 <<<"$output")"
fi
if [ "$code" -eq 1 ] && ! grep -qi -- "quibbler" "$stdout_file" "$stderr_file"; then
  pass "CA8 : liste lue dans .excluded-names, aucun nom divulgué"
else
  failed "CA8 : liste lue dans .excluded-names, aucun nom divulgué" "code $code : $(head -n 1 <<<"$output")"
fi

# Casse et sous-chaîne (section « Le script » de la spec)
r=$(repo_with_file docs/notes.md "Le projet SUPERZORGLUBX avance")
refused_case "Script" "recherche insensible à la casse et par sous-chaîne" "$r" "docs/notes.md" main..HEAD

# Un fichier non suivi n'est pas lu (section « Le script » de la spec)
r=$(new_repo)
write_file "$r" docs/brouillon.md "Réunion avec Zorglub demain"
run_script "$r" "$list" main..HEAD
if [ "$code" -eq 0 ]; then
  pass "Script : un fichier non suivi contenant un nom est ignoré"
else
  failed "Script : un fichier non suivi contenant un nom est ignoré" "attendu 0, obtenu $code : $(head -n 1 <<<"$output")"
fi

# --- CA5 : un cas par vecteur ------------------------------------------------

# Chemin d'un fichier suivi, contenu neutre, plage vide
r=$(repo_with_file docs/zorglub-notes.md "Un contenu parfaitement neutre")
refused_case CA5 "nom dans le chemin d'un fichier suivi" "$r" "" main..HEAD

# Message de commit de la plage
r=$(new_repo)
start_branch "$r"
git -C "$r" commit -q --allow-empty -m "feat: travail pour Quibbler"
sha=$(git -C "$r" rev-parse HEAD)
refused_case CA5 "nom dans le message d'un commit de la plage, commit cité" "$r" "${sha:0:7}" main..HEAD

# Corps du message
r=$(new_repo)
start_branch "$r"
git -C "$r" commit -q --allow-empty -m "feat: ajout" -m "Corps du message : demande de Vantablex"
sha=$(git -C "$r" rev-parse HEAD)
refused_case CA5 "nom dans le corps du message d'un commit, commit cité" "$r" "${sha:0:7}" main..HEAD

# Auteur : nom, puis e-mail
r=$(new_repo)
start_branch "$r"
GIT_AUTHOR_NAME="Dev Zorglub" git -C "$r" commit -q --allow-empty -m "feat: travail neutre"
sha=$(git -C "$r" rev-parse HEAD)
refused_case CA5 "nom dans le nom de l'auteur, commit cité" "$r" "${sha:0:7}" main..HEAD

r=$(new_repo)
start_branch "$r"
GIT_AUTHOR_EMAIL="dev@quibbler.example" git -C "$r" commit -q --allow-empty -m "feat: travail neutre"
sha=$(git -C "$r" rev-parse HEAD)
refused_case CA5 "nom dans l'e-mail de l'auteur, commit cité" "$r" "${sha:0:7}" main..HEAD

# Committer : nom, puis e-mail
r=$(new_repo)
start_branch "$r"
GIT_COMMITTER_NAME="Ops Vantablex" git -C "$r" commit -q --allow-empty -m "feat: travail neutre"
sha=$(git -C "$r" rev-parse HEAD)
refused_case CA5 "nom dans le nom du committer, commit cité" "$r" "${sha:0:7}" main..HEAD

r=$(new_repo)
start_branch "$r"
GIT_COMMITTER_EMAIL="ops@zorglub.example" git -C "$r" commit -q --allow-empty -m "feat: travail neutre"
sha=$(git -C "$r" rev-parse HEAD)
refused_case CA5 "nom dans l'e-mail du committer, commit cité" "$r" "${sha:0:7}" main..HEAD

# Lignes ajoutées par un commit de la plage : nom ajouté puis retiré, donc absent
# de l'arbre final, mais présent dans l'historique qui sera publié
r=$(new_repo)
start_branch "$r"
write_file "$r" docs/notes.md "Réunion avec Quibbler demain"
commit_all "$r" "docs: notes"
sha=$(git -C "$r" rev-parse HEAD)
write_file "$r" docs/notes.md "Réunion demain"
commit_all "$r" "docs: notes revues"
refused_case CA5 "nom dans les lignes ajoutées par un commit de la plage (retiré ensuite), commit cité" \
  "$r" "${sha:0:7}" main..HEAD

# --- CA6 : un commit qui retire un nom ---------------------------------------

r=$(repo_with_file docs/notes.md "Réunion avec Zorglub demain")
# Précondition : avant le commit de retrait, le même dépôt est refusé
run_script "$r" "$list" main..HEAD
if [ "$code" -eq 1 ]; then
  pass "CA14 : précondition, le nom est détecté avant son retrait (CA6)"
else
  failed "CA14 : précondition, le nom est détecté avant son retrait (CA6)" "attendu 1, obtenu $code : $(head -n 1 <<<"$output")"
fi
start_branch "$r"
write_file "$r" docs/notes.md "Réunion demain"
commit_all "$r" "docs: retrait du nom"
run_script "$r" "$list" main..HEAD
if [ "$code" -eq 0 ]; then
  pass "CA6 : un commit qui retire un nom réussit sur sa plage"
else
  failed "CA6 : un commit qui retire un nom réussit sur sa plage" "attendu 0, obtenu $code : $(head -n 1 <<<"$output")"
fi

# --- CA7 : --all relit tout l'historique -------------------------------------

# Nom sur une branche non fusionnée ; HEAD revient sur main
r=$(new_repo)
git -C "$r" checkout -q -b feat/non-fusionnee
write_file "$r" docs/notes.md "Réunion avec Vantablex demain"
commit_all "$r" "docs: notes"
sha=$(git -C "$r" rev-parse HEAD)
git -C "$r" checkout -q main
precondition "branche non fusionnée, plage restreinte" "$r" main..HEAD
run_script "$r" "$list" main..HEAD
if [ "$code" -eq 0 ]; then
  pass "CA7 : une plage restreinte ne voit pas la branche non fusionnée (précondition)"
else
  failed "CA7 : une plage restreinte ne voit pas la branche non fusionnée (précondition)" "attendu 0, obtenu $code : $(head -n 1 <<<"$output")"
fi
precondition "branche non fusionnée, --all" "$r" --all
run_script "$r" "$list" --all
verify_refused CA7 "--all voit un nom sur une branche non fusionnée, commit cité" "${sha:0:7}"

# --all voit aussi un nom retiré depuis, sur main (historique de la branche courante)
r=$(new_repo)
write_file "$r" docs/notes.md "Réunion avec Zorglub demain"
commit_all "$r" "docs: notes"
sha=$(git -C "$r" rev-parse HEAD)
write_file "$r" docs/notes.md "Réunion demain"
commit_all "$r" "docs: notes revues"
run_script "$r" "$list" main..HEAD
if [ "$code" -eq 0 ]; then
  pass "CA7 : sans --all, l'historique de main n'est pas relu (précondition)"
else
  failed "CA7 : sans --all, l'historique de main n'est pas relu (précondition)" "attendu 0, obtenu $code : $(head -n 1 <<<"$output")"
fi
precondition "historique de main, --all" "$r" --all
run_script "$r" "$list" --all
verify_refused CA7 "--all relit l'historique de main, commit cité" "${sha:0:7}"

# --- CA15 : un fichier .excluded-names suivi par Git publierait la liste -------
# Ajouté pendant l'implémentation : le contrôle par mutation a montré que cette
# protection du script n'était couverte par aucun test (spec 010, CA14).

r=$(new_repo)
write_file "$r" .excluded-names $'Zorglub\nQuibbler\nVantablex'
commit_all "$r" "chore: fichier ajouté par erreur"
# Précondition : sans cette protection, le dépôt passerait avec une liste neutre,
# puisque aucun nom de la liste utilisée n'y figure.
run_script "$r" "$neutral_list" main..HEAD
if [ "$code" -eq 1 ] && grep -qF -- ".excluded-names" <<<"$output"; then
  pass "CA15 : un .excluded-names suivi par Git est refusé, quelle que soit la liste"
else
  failed "CA15 : un .excluded-names suivi par Git est refusé, quelle que soit la liste" \
    "attendu 1, obtenu $code : $(head -n 1 <<<"$output")"
fi
if [ "$code" -eq 1 ] && ! grep -qiE -- "zorglub|quibbler|vantablex" "$stdout_file" "$stderr_file"; then
  pass "CA8 : .excluded-names suivi, aucun nom divulgué"
else
  failed "CA8 : .excluded-names suivi, aucun nom divulgué" "code $code : $(head -n 1 <<<"$output")"
fi

# --- En CI, un .excluded-names local ne tient pas lieu de secret --------------
# Protection « ! in_ci » du script : sans elle, un fichier local ferait croire à
# une liste configurée alors que le secret manque.

r=$(repo_with_file docs/notes.md "Réunion avec Zorglub demain")
printf 'Zorglub\n' >"$r/.excluded-names"
# Précondition : hors CI, le fichier est bien lu et le dépôt refusé.
run_script_unset "$r" main..HEAD
if [ "$code" -eq 1 ]; then
  pass "CA14 : précondition, hors CI le fichier .excluded-names est lu"
else
  failed "CA14 : précondition, hors CI le fichier .excluded-names est lu" "attendu 1, obtenu $code : $(head -n 1 <<<"$output")"
fi
# En CI, sans secret : le fichier est ignoré, la vérification est sautée.
(cd "$r" && CI=true "$script" main..HEAD) >"$stdout_file" 2>"$stderr_file"
code=$?
output=$(cat "$stdout_file" "$stderr_file")
if [ "$code" -eq 0 ] && grep -qF -- "aucune liste" <<<"$output"; then
  pass "Script : en CI, un .excluded-names local ne tient pas lieu de secret"
else
  failed "Script : en CI, un .excluded-names local ne tient pas lieu de secret" "attendu 0 et un avertissement, obtenu $code : $(head -n 1 <<<"$output")"
fi

# --- CA15 (suite) : un .excluded-names suivi est refusé même sans liste -------
# Le contrôle précède la sortie anticipée « aucune liste » : en CI sans secret,
# le cas le plus grave passait au vert (revue de la PR).

r=$(new_repo)
write_file "$r" .excluded-names $'Zorglub\nQuibbler\nVantablex'
commit_all "$r" "chore: fichier ajouté par erreur"
(cd "$r" && CI=true env -u EXCLUDED_NAMES "$script" main..HEAD) >"$stdout_file" 2>"$stderr_file"
code=$?
output=$(cat "$stdout_file" "$stderr_file")
if [ "$code" -eq 1 ] && grep -qF -- ".excluded-names" <<<"$output"; then
  pass "CA15 : .excluded-names suivi refusé en CI même sans secret"
else
  failed "CA15 : .excluded-names suivi refusé en CI même sans secret" "attendu 1, obtenu $code : $(head -n 1 <<<"$output")"
fi
if [ "$code" -eq 1 ] && ! grep -qiE -- "zorglub|quibbler|vantablex" "$stdout_file" "$stderr_file"; then
  pass "CA8 : .excluded-names suivi en CI, aucun nom divulgué"
else
  failed "CA8 : .excluded-names suivi en CI, aucun nom divulgué" "code $code : $(head -n 1 <<<"$output")"
fi

# --- CA8 : une plage qui contient un nom n'est pas recopiée -------------------

r=$(repo_with_file docs/notes.md "Contenu neutre")
git -C "$r" checkout -q -b "feat/Zorglub-fix"
run_script "$r" "$list" "main..feat/Zorglub-fix"
if [ "$code" -eq 0 ] && ! grep -qiF -- "zorglub" "$stdout_file" "$stderr_file"; then
  pass "CA8 : succès, la plage contenant un nom n'est pas recopiée"
else
  failed "CA8 : succès, la plage contenant un nom n'est pas recopiée" "code $code : $(head -n 1 <<<"$output")"
fi
run_script "$r" "$list" "main..feat/Zorglub-absente"
if [ "$code" -eq 2 ] && ! grep -qiF -- "zorglub" "$stdout_file" "$stderr_file"; then
  pass "CA8 : plage invalide contenant un nom, nom non divulgué"
else
  failed "CA8 : plage invalide contenant un nom, nom non divulgué" "code $code : $(head -n 1 <<<"$output")"
fi

# --- CA8/CA5 : trous trouvés par la revue de sécurité de la PR ---------------

# Gros diff : « grep -q » dans un tuyau sortait à la première correspondance, le
# producteur recevait SIGPIPE, et pipefail transformait la trouvaille en absence.
r=$(new_repo)
start_branch "$r"
mkdir -p "$r/docs"
{
  echo "Zorglub en première ligne"
  i=0
  while [ "$i" -lt 60000 ]; do
    echo "ligne de remplissage $i"
    i=$((i + 1))
  done
} >"$r/docs/export.md"
commit_all "$r" "docs: export volumineux"
sha=$(git -C "$r" rev-parse HEAD)
# Le nom n'est plus dans l'arbre final : seules les lignes ajoutées le portent.
git -C "$r" rm -q docs/export.md
commit_all "$r" "docs: retrait de l'export"
precondition "gros diff" "$r" main..HEAD
run_script "$r" "$list" main..HEAD
verify_refused CA5 "nom en tête d'un diff volumineux, commit cité" "${sha:0:7}"

# Commit de fusion : git show n'affiche aucun diff sans --diff-merges
r=$(new_repo)
git -C "$r" checkout -q -b feat/autre
write_file "$r" docs/autre.md "Contenu neutre"
commit_all "$r" "docs: autre"
git -C "$r" checkout -q main
write_file "$r" docs/main.md "Contenu neutre"
commit_all "$r" "docs: main"
start_branch "$r"
git -C "$r" merge -q --no-ff feat/autre -m "merge: fusion" >/dev/null 2>&1
write_file "$r" docs/conflit.md "Résolution citant Quibbler"
git -C "$r" add -A
git -C "$r" commit -q --amend --no-edit
sha=$(git -C "$r" rev-parse HEAD)
precondition "commit de fusion" "$r" main..HEAD
run_script "$r" "$list" main..HEAD
verify_refused CA5 "nom introduit par un commit de fusion, commit cité" "${sha:0:7}"

# Renommage vers un chemin qui contient un nom, puis défait : aucune ligne « + »
r=$(repo_with_file docs/notes.md "Contenu neutre")
start_branch "$r"
git -C "$r" mv docs/notes.md docs/notes-vantablex.md
commit_all "$r" "docs: renommage"
sha=$(git -C "$r" rev-parse HEAD)
git -C "$r" mv docs/notes-vantablex.md docs/notes.md
commit_all "$r" "docs: renommage défait"
precondition "renommage défait" "$r" main..HEAD
run_script "$r" "$list" main..HEAD
verify_refused CA5 "nom dans un chemin renommé puis défait, commit cité" "${sha:0:7}"

exit $fail
