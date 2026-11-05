#!/usr/bin/env bash
# Refuse les noms exclus (clients et employeurs réels) dans les fichiers suivis
# et dans les commits d'une plage (spec 010).
#
# Usage : scripts/verifier-noms-exclus.sh [plage | --all]
#   plage   défaut origin/main..HEAD
#   --all   tout l'historique (toutes les références), avant le passage en public
#
# Liste : variable EXCLUDED_NAMES (noms séparés par des virgules ; secret de CI).
# Hors CI seulement, à défaut, fichier local non versionné .excluded-names à la
# racine du dépôt (un nom par ligne ou séparés par des virgules). Comparaison
# insensible à la casse, par sous-chaîne ; un nom fait au moins 3 caractères.
#
# Ce qui est cherché :
# - contenu et chemin des fichiers suivis ;
# - pour chaque commit de la plage : message, nom et e-mail d'auteur et de
#   committer, lignes ajoutées par son diff ;
# - titre, description et branche de la PR, s'ils sont fournis par PR_TITLE,
#   PR_BODY et PR_HEAD_REF.
#
# La sortie ne cite jamais un nom : seulement le fichier (ou son objet Git si le
# chemin contient lui-même un nom) et le SHA du commit. Les journaux de CI sont
# publics.
#
# Liste vide ou absente : avertissement et succès, en CI comme en local. Un
# projet sans nom à cacher n'a donc rien à configurer. Limite assumée : un secret
# EXCLUDED_NAMES supprimé par erreur passe inaperçu (décision de Yanis,
# 2026-10-20).
#
# Codes : 0 rien trouvé ou liste absente, 1 nom trouvé, 2 usage invalide
# ou erreur de Git (une erreur ne vaut jamais « rien trouvé »).
set -u -o pipefail

# Casse des lettres accentuées (É et é). macOS ne fournit pas C.UTF-8 : sans
# repli, la locale retombe sur C et grep -i cesse de replier les accents.
# Liste lue une fois, hors tuyau : sous pipefail, « locale -a | grep -q » échoue
# dès que grep s'arrête avant la fin (SIGPIPE de locale -a).
locales=$(locale -a 2>/dev/null)
for loc in C.UTF-8 en_US.UTF-8 fr_FR.UTF-8; do
  if grep -qix "${loc/UTF-8/utf8}\|$loc" <<<"$locales"; then
    export LC_ALL=$loc
    break
  fi
done
if [ -z "${LC_ALL:-}" ]; then
  echo "Avertissement : aucune locale UTF-8 disponible ; un nom accentué écrit dans une autre casse peut passer." >&2
  export LC_ALL=C
fi

if [ $# -gt 1 ]; then
  echo "Usage : $0 [plage | --all]   (défaut : origin/main..HEAD)" >&2
  exit 2
fi
range=${1:-origin/main..HEAD}

if ! top=$(git rev-parse --show-toplevel 2>/dev/null); then
  echo "Erreur : à lancer dans un dépôt Git" >&2
  exit 2
fi
cd "$top" || exit 2

if ! tmp=$(mktemp -d); then
  echo "Erreur : mktemp a échoué" >&2
  exit 2
fi
# INT TERM HUP aussi : sans eux, une interruption laisserait la liste des noms
# en clair dans $tmp/patterns.
trap 'rm -rf "$tmp"' EXIT INT TERM HUP
patterns="$tmp/patterns"

in_ci() {
  case ${CI:-} in
    "" | false | 0) return 1 ;;
    *) return 0 ;;
  esac
}

# Erreur de Git : jamais « rien trouvé »
git_error() {
  echo "Erreur : git $1 a échoué : vérification impossible." >&2
  exit 2
}

# Un nom par ligne, sans espaces autour ni entrée vide : une ligne vide dans le
# fichier de motifs ferait correspondre tout le dépôt.
normalize() {
  tr -d '\r' | tr ',' '\n' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' | { grep -v '^$' || true; }
}

# Avant toute chose, et quelle que soit la liste : un .excluded-names suivi par
# Git publierait les noms qu'il protège. Ce contrôle précède la sortie anticipée
# « aucune liste », sans quoi le cas le plus grave passerait au vert en CI.
if git ls-files --error-unmatch -- .excluded-names >/dev/null 2>&1; then
  echo "Échec : .excluded-names est suivi par Git ; il contient la liste des noms. À retirer de l'index : git rm --cached .excluded-names" >&2
  exit 1
fi

printf '%s' "${EXCLUDED_NAMES:-}" | normalize >"$patterns"
source_name="la variable EXCLUDED_NAMES"
# En CI, seul le secret compte : un fichier local ne doit pas en tenir lieu
if [ ! -s "$patterns" ] && ! in_ci && [ -f .excluded-names ]; then
  normalize <.excluded-names >"$patterns"
  source_name="le fichier .excluded-names"
fi

if [ ! -s "$patterns" ]; then
  echo "Avertissement : aucune liste de noms exclus (variable EXCLUDED_NAMES ou fichier .excluded-names) : vérification sautée." >&2
  exit 0
fi

# Un motif trop court ferait échouer presque tout le dépôt ; le motif n'est pas cité
while IFS= read -r name; do
  if [ "${#name}" -lt 3 ]; then
    echo "Erreur : un nom de la liste ($source_name) fait moins de 3 caractères." >&2
    exit 2
  fi
done <"$patterns"

# matches : l'entrée standard contient-elle un nom de la liste ?
#
# Toujours alimentée par un fichier, jamais par un tuyau : « grep -q » sort à la
# première correspondance, ce qui tue le producteur par SIGPIPE ; avec pipefail,
# le tuyau rend alors 141 et la correspondance passe pour une absence. Un diff de
# quelques centaines de kilooctets dont le nom est en tête suffisait à passer
# inaperçu (revue de sécurité de la PR de la spec 010).
matches() {
  grep -qiF -f "$patterns"
}

# matches_text <texte> : même contrôle sur une chaîne, via un fichier
matches_text() {
  printf '%s\n' "$1" >"$tmp/text"
  matches <"$tmp/text"
}

# La plage peut contenir un nom (branche « feat/<nom>-fix ») : ne jamais la
# recopier telle quelle dans la sortie.
safe_range() {
  if matches_text "$range"; then
    echo "la plage demandée (masquée : elle contient un nom exclu)"
  else
    echo "$range"
  fi
}

# --all est compris tel quel par git rev-list
if ! commits=$(git rev-list "$range" 2>/dev/null); then
  echo "Erreur : plage de commits invalide : $(safe_range)" >&2
  exit 2
fi

found=0
report() {
  echo "$1"
  found=1
}

g() {
  git -c core.quotePath=false "$@"
}

# Fichiers suivis, séparés par NUL
g ls-files -z >"$tmp/files" || git_error ls-files
tr '\0' '\n' <"$tmp/files" >"$tmp/files-lines"

# Fichier à citer : son chemin, ou son objet si le chemin contient un nom.
# Appelée dans une substitution de commande : un exit n'y tuerait que le
# sous-shell, donc une erreur de Git se signale sans prétendre « rien trouvé ».
describe_file() {
  local blob
  if matches_text "$1"; then
    if ! g ls-files -s -z -- ":(literal)$1" >"$tmp/entry"; then
      echo "objet indéterminé (git ls-files a échoué ; chemin masqué : il contient lui-même un nom exclu)"
      return
    fi
    blob=$(tr '\0' '\n' <"$tmp/entry" | awk 'NR == 1 { print $2 }')
    echo "objet ${blob:-indéterminé} (chemin masqué : il contient lui-même un nom exclu)"
  else
    echo "$1"
  fi
}

# Contenu des fichiers suivis (binaires compris) ; code 1 : rien trouvé
g grep -l -z -i -F -f "$patterns" >"$tmp/content"
case $? in
  0 | 1) ;;
  *) git_error grep ;;
esac
while IFS= read -r -d '' path; do
  report "Nom exclu dans le contenu de : $(describe_file "$path")"
done <"$tmp/content"

# Chemins des fichiers suivis
while IFS= read -r -d '' path; do
  if matches_text "$path"; then
    report "Nom exclu dans le chemin du fichier : $(describe_file "$path")"
  fi
done <"$tmp/files"

# Commits de la plage
relus=0
for sha in $commits; do
  relus=$((relus + 1))
  g log -1 --format=%B "$sha" >"$tmp/message" || git_error log
  if matches <"$tmp/message"; then
    report "Nom exclu dans le message du commit : $sha"
  fi
  g log -1 --format='%an%n%ae%n%cn%n%ce' "$sha" >"$tmp/identity" || git_error log
  if matches <"$tmp/identity"; then
    report "Nom exclu dans l'auteur ou le committer du commit : $sha"
  fi
  # Lignes ajoutées seulement : une PR qui retire un nom doit passer.
  # --diff-merges=first-parent : sans lui, un commit de fusion n'affiche aucun
  # diff, et un nom introduit en résolvant un conflit passerait inaperçu.
  g show --format= --no-color --no-ext-diff --diff-merges=first-parent "$sha" >"$tmp/diff" ||
    git_error show
  grep '^+' "$tmp/diff" >"$tmp/added"
  case $? in
    0 | 1) ;;
    *) git_error grep ;;
  esac
  if matches <"$tmp/added"; then
    report "Nom exclu dans les lignes ajoutées par le commit : $sha"
  fi
  # Chemins touchés : un renommage vers un chemin qui contient un nom ne produit
  # aucune ligne « + », et disparaîtrait des fichiers suivis s'il est défait.
  g log -1 --format= --name-only --diff-merges=first-parent -z "$sha" >"$tmp/paths" ||
    git_error log
  while IFS= read -r -d '' path; do
    [ -n "$path" ] || continue
    if matches_text "$path"; then
      report "Nom exclu dans un chemin touché par le commit : $sha"
      break
    fi
  done <"$tmp/paths"
done

# Titre, description et branche de la PR (fournis par la CI)
check_text() {
  if [ -n "$2" ] && matches_text "$2"; then
    report "Nom exclu dans $1"
  fi
}
check_text "le titre de la PR" "${PR_TITLE:-}"
check_text "la description de la PR" "${PR_BODY:-}"
check_text "le nom de la branche de la PR" "${PR_HEAD_REF:-}"

if [ "$found" -ne 0 ]; then
  echo "Échec : un nom exclu (liste lue dans $source_name) apparaît ci-dessus. Corrige le fichier, ou réécris le commit avant le merge (git rebase), sans jamais citer le nom dans la PR." >&2
  exit 1
fi
echo "Aucun nom exclu dans les fichiers suivis ni dans les ${relus:-0} commit(s) de $(safe_range)."
exit 0
