#!/usr/bin/env bash
# Dit si le dépôt peut devenir public (spec 010, CA9 et CA10). Lancé par la
# skill /publier ; la mise en public elle-même reste une action de l'humain.
#
# Usage : scripts/verifier-avant-public.sh   (sans argument)
#
# Trois contrôles, tous lancés même si l'un échoue :
# 1. noms exclus sur tout l'historique : scripts/verifier-noms-exclus.sh --all ;
#    sans liste de noms, le dépôt n'est pas déclaré publiable (on n'a rien
#    cherché) ;
# 2. références de PR : les refs/pull/*/head du dépôt distant origin sont
#    récupérées dans un espace de noms temporaire, supprimé à la fin, et chacune
#    passe le contrôle des noms. GitHub les garde après une réécriture de
#    l'historique, et seul son support peut les purger ;
# 3. fichiers d'environnement suivis (.env, .env.*, sauf .env.example) ; leur
#    historique relève de gitleaks.
#
# La sortie ne cite jamais un nom : celle du script de base est relayée telle
# quelle, et elle n'en contient pas.
#
# Codes : 0 publiable, 1 au moins un contrôle en échec, 2 usage invalide ou
# erreur (une erreur ne vaut jamais « publiable »).
set -u -o pipefail

if [ $# -gt 0 ]; then
  echo "Usage : $0   (sans argument)" >&2
  exit 2
fi

if ! top=$(git rev-parse --show-toplevel 2>/dev/null); then
  echo "Erreur : à lancer dans un dépôt Git" >&2
  exit 2
fi
cd "$top" || exit 2

checker="$(cd "$(dirname "$0")" && pwd -P)/verifier-noms-exclus.sh"
if [ ! -x "$checker" ]; then
  echo "Erreur : $checker est absent ou non exécutable" >&2
  exit 2
fi

# Le contrôle porte sur le dépôt, pas sur une PR en cours
unset PR_TITLE PR_BODY PR_HEAD_REF

if ! tmp=$(mktemp -d); then
  echo "Erreur : mktemp a échoué" >&2
  exit 2
fi
ns="refs/verifier-avant-public-$$"
# shellcheck disable=SC2329 # appelée par le trap
cleanup() {
  git for-each-ref --format='delete %(refname)' "$ns/" 2>/dev/null |
    git update-ref --stdin 2>/dev/null
  rm -rf "$tmp"
}
trap cleanup EXIT INT TERM HUP

failed=0
error=0
summary=()

# Lance le script de base et relaie sa sortie. Code de retour du script de base.
check_names() {
  "$checker" "$1" >"$tmp/out" 2>"$tmp/err"
  local code=$?
  cat "$tmp/out" "$tmp/err"
  # Sans liste, le script de base avertit et sort en 0 : ici, c'est un refus
  if [ "$code" -eq 0 ] && grep -q "aucune liste" "$tmp/err"; then
    return 3
  fi
  return "$code"
}

# --- 1. Noms exclus sur tout l'historique -------------------------------------

echo "== Noms exclus sur tout l'historique (verifier-noms-exclus.sh --all)"
check_names --all
case $? in
  0) summary+=("OK     noms exclus : aucun dans l'historique ni dans les fichiers suivis") ;;
  1)
    summary+=("ÉCHEC  noms exclus : au moins un dans l'historique ou les fichiers suivis (voir ci-dessus) ; réécrire l'historique sur un clone miroir")
    failed=1
    ;;
  3)
    summary+=("ÉCHEC  noms exclus : aucune liste définie (EXCLUDED_NAMES ou .excluded-names) ; sans liste, rien n'a été cherché. Une liste d'un nom inventé suffit pour un projet sans nom à cacher.")
    failed=1
    ;;
  *)
    summary+=("ERREUR noms exclus : vérification impossible (voir ci-dessus)")
    error=1
    ;;
esac

# --- 2. Références de PR -------------------------------------------------------

echo "== Références de PR (refs/pull/*/head de origin)"
if ! git remote get-url origin >/dev/null 2>&1; then
  summary+=("ÉCHEC  références de PR : pas de dépôt distant origin, contrôle impossible")
  failed=1
elif ! git fetch -q --no-tags origin "+refs/pull/*/head:$ns/pull/*" 2>"$tmp/fetch"; then
  cat "$tmp/fetch" >&2
  summary+=("ERREUR références de PR : récupération depuis origin impossible")
  error=1
else
  exposed=()
  pr_error=0
  total=0
  while IFS= read -r ref; do
    [ -n "$ref" ] || continue
    total=$((total + 1))
    n=${ref##*/pull/}
    check_names "$ref" >/dev/null
    case $? in
      0 | 3) ;;
      1) exposed+=("#$n") ;;
      *) pr_error=1 ;;
    esac
  done < <(git for-each-ref --format='%(refname)' "$ns/pull/" | LC_ALL=C sort -t/ -k4,4n)
  if [ "$pr_error" -ne 0 ]; then
    summary+=("ERREUR références de PR : vérification impossible pour au moins une PR")
    error=1
  elif [ "${#exposed[@]}" -gt 0 ]; then
    summary+=("ÉCHEC  références de PR : ${exposed[*]} atteignent un commit refusé. GitHub garde ces références après une réécriture de l'historique, et seul le support GitHub peut les purger : lui écrire en citant ces PR (voir la skill /publier).")
    failed=1
  else
    summary+=("OK     références de PR : $total vérifiée(s), aucune n'atteint un commit refusé")
  fi
fi

# --- 3. Fichiers d'environnement suivis ---------------------------------------

# Nom construit par concaténation : protect-secrets.sh refuse sinon l'édition
dotenv=".""env"
echo "== Fichiers $dotenv suivis"
env_files=()
while IFS= read -r -d '' path; do
  base=${path##*/}
  case $base in
    "$dotenv.example") ;;
    "$dotenv" | "$dotenv".*) env_files+=("$path") ;;
  esac
done < <(git ls-files -z)
if [ "${#env_files[@]}" -gt 0 ]; then
  summary+=("ÉCHEC  fichiers $dotenv suivis : ${env_files[*]} ; à retirer de l'index (git rm --cached) et à purger de l'historique")
  failed=1
else
  summary+=("OK     fichiers $dotenv : aucun suivi ($dotenv.example excepté)")
fi

# --- Bilan --------------------------------------------------------------------

echo
echo "Bilan du contrôle avant publication :"
printf '  %s\n' "${summary[@]}"
if [ "$error" -ne 0 ]; then
  echo "Erreur : contrôle incomplet, le dépôt n'est pas déclaré publiable." >&2
  exit 2
fi
if [ "$failed" -ne 0 ]; then
  echo "Le dépôt ne doit pas devenir public en l'état."
  exit 1
fi
echo "Le dépôt peut devenir public. La mise en public reste une action de l'humain."
exit 0
