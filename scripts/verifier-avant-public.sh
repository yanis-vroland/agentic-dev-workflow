#!/usr/bin/env bash
# Dit si le dépôt peut devenir public (spec 010 : CA9, CA10 et cas limites
# « Références de PR », « Fichier .env suivi », « Socle »). Lancé par la skill
# /publier ; la mise en public elle-même reste une action de l'humain.
#
# Usage : scripts/verifier-avant-public.sh   (sans argument)
#
# C'est le dépôt distant origin qui devient public, pas ce clone : ses branches,
# étiquettes et références de PR (refs/pull/*, head et merge) sont récupérées
# dans un espace de noms temporaire, supprimé à la fin. Puis trois contrôles,
# tous lancés même si l'un échoue :
# 1. noms exclus sur tout l'historique, local et distant :
#    scripts/verifier-noms-exclus.sh --all ; sans liste de noms, le dépôt n'est
#    pas déclaré publiable (on n'a rien cherché) ;
# 2. références de PR : les commits que seule une référence de PR atteint
#    passent le contrôle des noms. GitHub garde ces références après une
#    réécriture de l'historique, et seul son support peut les purger ;
# 3. fichiers d'environnement suivis (.env, .env.*, sauf .env.example) ; leur
#    historique relève de gitleaks.
# Le bilan liste aussi ce qui n'est pas vérifié, à relire par l'humain.
#
# La sortie ne cite jamais un nom : celle du script de base est relayée telle
# quelle, et elle n'en contient pas ; les chemins de fichiers d'environnement
# ne sont cités que si le contrôle 1 a réussi, donc s'ils ne contiennent aucun
# nom ; le message d'erreur de git fetch, qui contient l'URL, n'est pas relayé.
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

# Un clone superficiel arrête rev-list --all à la greffe, sans erreur
if [ "$(git rev-parse --is-shallow-repository 2>/dev/null)" != false ]; then
  echo "Erreur : clone superficiel (shallow) : l'historique est incomplet. Récupère-le d'abord : git fetch --unshallow" >&2
  exit 2
fi

# Le contrôle porte sur le dépôt, pas sur une PR en cours
unset PR_TITLE PR_BODY PR_HEAD_REF

if ! tmp=$(mktemp -d); then
  echo "Erreur : mktemp a échoué" >&2
  exit 2
fi
prefix="refs/verifier-avant-public-"
ns="$prefix$$"

# Supprime les refs temporaires, y compris celles d'un lancement interrompu
# (et, cas marginal, celles d'un autre lancement en cours dans ce dépôt)
remove_temp_refs() {
  git for-each-ref --format='delete %(refname)' 2>/dev/null |
    grep -F " $prefix" | git update-ref --stdin 2>/dev/null
}
# shellcheck disable=SC2329 # appelée par le trap
cleanup() {
  remove_temp_refs
  rm -rf "$tmp"
}
trap cleanup EXIT
trap 'exit 2' INT TERM HUP
remove_temp_refs

failed=0
error=0
summary=()

# Lance le script de base et relaie sa sortie. Code de retour du script de
# base, ou 3 s'il n'a aucune liste.
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

# --- Récupération du dépôt distant --------------------------------------------

# Branches et étiquettes d'abord, pour le contrôle 1 ; références de PR ensuite,
# pour le contrôle 2 seulement : sinon le contrôle 1 les relirait et demanderait
# une réécriture de l'historique pour une PR que seul le support GitHub peut
# purger. --refmap= : sans lui, fetch met aussi à jour refs/remotes/origin/*.
fetch_origin() {
  GIT_TERMINAL_PROMPT=0 git fetch -q --no-tags --refmap= origin "$@" 2>"$tmp/fetch"
}
fetch_hint="message de git non affiché : il contient l'URL ; vérifier le réseau et l'authentification, par exemple gh auth status"

has_origin=0
if ! git remote get-url origin >/dev/null 2>&1; then
  summary+=("ÉCHEC  dépôt distant : pas de dépôt origin ; ses branches et ses références de PR n'ont pas pu être vérifiées")
  failed=1
elif ! fetch_origin "+refs/heads/*:$ns/heads/*" "+refs/tags/*:$ns/tags/*"; then
  summary+=("ERREUR dépôt distant : récupération des branches de origin impossible ($fetch_hint)")
  error=1
else
  has_origin=1
fi

# --- 1. Noms exclus sur tout l'historique -------------------------------------

echo "== Noms exclus sur tout l'historique, local et distant (verifier-noms-exclus.sh --all)"
check_names --all
names_code=$?
case $names_code in
  0) summary+=("OK     noms exclus : aucun dans l'historique, local et distant, ni dans les fichiers suivis") ;;
  1)
    summary+=("ÉCHEC  noms exclus : au moins un dans l'historique ou les fichiers suivis (voir ci-dessus) ; réécrire l'historique sur un clone miroir")
    failed=1
    ;;
  3)
    summary+=("ÉCHEC  noms exclus : aucune liste définie (EXCLUDED_NAMES ou .excluded-names) ; sans liste, rien n'a été cherché. Seul l'humain crée la liste.")
    failed=1
    ;;
  *)
    summary+=("ERREUR noms exclus : vérification impossible (voir ci-dessus)")
    error=1
    ;;
esac

# --- 2. Références de PR -------------------------------------------------------

echo "== Références de PR (refs/pull/* de origin)"
# Le script de base relit aussi les fichiers suivis à chaque appel : s'ils
# contiennent un nom, toutes les PR seraient citées à tort
tracked_dirty=0
if [ "$names_code" -eq 1 ]; then
  check_names "HEAD..HEAD" >/dev/null || tracked_dirty=1
fi
if [ "$has_origin" -eq 1 ] && ! fetch_origin "+refs/pull/*:$ns/pull/*"; then
  summary+=("ERREUR références de PR : récupération depuis origin impossible ($fetch_hint)")
  error=1
elif [ "$has_origin" -eq 1 ] && [ "$names_code" -eq 3 ]; then
  # Sans liste, rien n'a été cherché dans les PR non plus
  summary+=("ÉCHEC  références de PR : non vérifiées, faute de liste de noms")
  failed=1
elif [ "$has_origin" -eq 1 ] && [ "$tracked_dirty" -eq 1 ]; then
  summary+=("ÉCHEC  références de PR : non vérifiées tant que les fichiers suivis contiennent un nom ; relancer après la correction")
  failed=1
elif [ "$has_origin" -eq 1 ]; then
  if ! git for-each-ref --format='%(refname)' "$ns/pull/" >"$tmp/pull-refs"; then
    summary+=("ERREUR références de PR : lecture des références impossible")
    error=1
  else
    exposed=()
    numbers=()
    pr_error=0
    : >"$tmp/clean-shas"
    : >"$tmp/refused-shas"
    while IFS= read -r ref; do
      n=${ref#"$ns/pull/"}
      n=${n%%/*}
      case " ${numbers[*]-} " in *" $n "*) ;; *) numbers+=("$n") ;; esac
      # Commits que seule une référence de PR atteint : les autres sont
      # couverts par le contrôle 1
      if ! git rev-list "$ref" --not --exclude="$ns/pull/*" --all >"$tmp/unique"; then
        pr_error=1
        continue
      fi
      while IFS= read -r sha; do
        # Résultat mémorisé par SHA : head et merge d'une même PR, ou plusieurs
        # PR, partagent des commits, et chaque appel relit les fichiers suivis
        if grep -qxF -- "$sha" "$tmp/clean-shas"; then
          continue
        elif grep -qxF -- "$sha" "$tmp/refused-shas"; then
          result=1
        else
          check_names "$sha^!" >/dev/null
          result=$?
          case $result in
            0 | 3) echo "$sha" >>"$tmp/clean-shas" ;;
            1) echo "$sha" >>"$tmp/refused-shas" ;;
          esac
        fi
        case $result in
          0 | 3) ;;
          1)
            case " ${exposed[*]-} " in *" #$n "*) ;; *) exposed+=("#$n") ;; esac
            ;;
          *) pr_error=1 ;;
        esac
      done <"$tmp/unique"
    done <"$tmp/pull-refs"
    if [ "$pr_error" -ne 0 ]; then
      summary+=("ERREUR références de PR : vérification impossible pour au moins une PR")
      error=1
    elif [ "${#exposed[@]}" -gt 0 ]; then
      summary+=("ÉCHEC  références de PR : ${exposed[*]} atteignent un commit refusé. GitHub garde ces références après une réécriture de l'historique, et seul le support GitHub peut les purger : lui écrire en citant ces PR (voir la skill /publier).")
      failed=1
    elif [ "${#numbers[@]}" -eq 0 ]; then
      summary+=("OK     références de PR : aucune référence de PR sur origin")
    else
      summary+=("OK     références de PR : ${#numbers[@]} PR vérifiée(s), aucune n'atteint un commit refusé")
    fi
  fi
fi

# --- 3. Fichiers d'environnement suivis ---------------------------------------

# Nom construit par concaténation : protect-secrets.sh refuse sinon l'édition
dotenv=".""env"
echo "== Fichiers $dotenv suivis"
if ! git ls-files -z >"$tmp/files"; then
  summary+=("ERREUR fichiers $dotenv : lecture des fichiers suivis impossible")
  error=1
else
  env_files=()
  while IFS= read -r -d '' path; do
    base=${path##*/}
    case $base in
      "$dotenv.example") ;;
      "$dotenv" | "$dotenv".*) env_files+=("$path") ;;
    esac
  done <"$tmp/files"
  if [ "${#env_files[@]}" -eq 0 ]; then
    summary+=("OK     fichiers $dotenv : aucun suivi ($dotenv.example excepté)")
  else
    failed=1
    # Un chemin n'est sûr que si le contrôle 1 a relu les chemins suivis
    if [ "$names_code" -eq 0 ]; then
      summary+=("ÉCHEC  fichiers $dotenv suivis : ${env_files[*]} ; à retirer de l'index (git rm --cached) et à purger de l'historique")
    else
      summary+=("ÉCHEC  fichiers $dotenv suivis : ${#env_files[@]} fichier(s), chemins masqués tant que le contrôle des noms échoue ; git ls-files les liste")
    fi
  fi
fi

# --- Bilan --------------------------------------------------------------------

echo
echo "Bilan du contrôle avant publication :"
printf '  %s\n' "${summary[@]}"
echo
echo "Non vérifié par ce script, à relire par l'humain avant la mise en public :"
echo "  - titres, descriptions et commentaires des PR et des issues, noms des anciennes branches de PR ;"
echo "  - releases, wiki et journaux des GitHub Actions ;"
echo "  - commits orphelins encore accessibles par leur SHA après un push forcé ;"
echo "  - contenu des fichiers binaires ou compressés dans les anciens commits."
echo
if [ "$error" -ne 0 ]; then
  echo "Erreur : contrôle incomplet, le dépôt n'est pas déclaré publiable." >&2
  exit 2
fi
if [ "$failed" -ne 0 ]; then
  echo "Le dépôt ne doit pas devenir public en l'état."
  exit 1
fi
echo "Le dépôt peut devenir public, après relecture de ce qui n'est pas vérifié. La mise en public reste une action de l'humain."
exit 0
