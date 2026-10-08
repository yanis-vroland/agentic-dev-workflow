#!/usr/bin/env bash
# Applique le template agentic-dev-workflow à un projet existant.
# Spec : docs/specs/001-script-init.md
set -euo pipefail

template="$(cd "$(dirname "$0")/.." && pwd -P)"

usage() {
  echo "Usage : scripts/init.sh <chemin-du-projet> [--force]" >&2
  echo "  --force  écrase les fichiers du template déjà présents dans le projet" >&2
  exit 2
}

# --- Arguments ---------------------------------------------------------------

target=""
force=0
for arg in "$@"; do
  case "$arg" in
    --force) force=1 ;;
    -*)
      echo "Option inconnue : $arg" >&2
      usage
      ;;
    *)
      [ -z "$target" ] || usage
      target=$arg
      ;;
  esac
done
[ -n "$target" ] || usage

if [ ! -d "$target" ]; then
  echo "Erreur : le dossier $target n'existe pas." >&2
  exit 1
fi
target="$(cd "$target" && pwd -P)"

if [ "$target" = "$template" ]; then
  echo "Erreur : la cible est le template lui-même." >&2
  exit 1
fi

is_git=0
if git -C "$target" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  root="$(cd "$(git -C "$target" rev-parse --show-toplevel)" && pwd -P)"
  if [ "$root" != "$target" ]; then
    echo "Erreur : $target est dans le dépôt Git $root sans en être la racine." >&2
    echo "Relance le script sur la racine du dépôt : scripts/init.sh $root" >&2
    exit 2
  fi
  is_git=1
fi

warnings=()
steps=()

# --- Fichiers copiés depuis le template ------------------------------------

files=(
  CLAUDE.md
  tests/hooks.sh
  tests/pre-commit.sh
  .github/workflows/garde-fous.yml
  .github/workflows/ai-review.yml
  .github/pull_request_template.md
  .github/scripts/verifier-revue-ia.sh
  tests/verifier-revue-ia.sh
)
while IFS= read -r file; do
  files+=("$file")
done < <(cd "$template" && find .claude .githooks docs/templates -type f \
  ! -path .claude/settings.local.json | LC_ALL=C sort)

for file in "${files[@]}"; do
  dest="$target/$file"
  if [ -e "$dest" ] && [ "$force" -eq 0 ]; then
    echo "Ignoré (existe déjà) : $file"
    if [ "$file" = .claude/settings.json ]; then
      warnings+=("Attention : .claude/settings.json existe déjà, garde-fous NON installés : fusionne manuellement les permissions et les hooks du template.")
      steps+=("Fusionner .claude/settings.json avec celui du template (permissions et hooks), ou relancer avec --force.")
    fi
    continue
  fi
  mkdir -p "$(dirname "$dest")"
  cp -p "$template/$file" "$dest"
  echo "Copié : $file"
done

# --- Dossiers et journal du projet (jamais écrasés) --------------------------

for dir in docs/adr docs/specs; do
  mkdir -p "$target/$dir"
  if [ -z "$(ls -A "$target/$dir")" ]; then
    : >"$target/$dir/.gitkeep"
    echo "Créé : $dir/.gitkeep"
  fi
done

journal="$target/docs/journal.md"
if [ ! -e "$journal" ]; then
  cat >"$journal" <<'EOF'
# Journal de bord

Ce que l'agent a bien fait, ce que j'ai corrigé et pourquoi, les limites observées.
EOF
  echo "Créé : docs/journal.md"
fi

# --- .gitignore (complété, jamais remplacé) ----------------------------------
# La dernière règle qui correspond l'emporte : !.env.example doit rester après .env.*

gitignore="$target/.gitignore"
[ -e "$gitignore" ] || : >"$gitignore"

has_line() {
  grep -qxF -- "$1" "$gitignore"
}

last_line_of() {
  grep -nxF -- "$1" "$gitignore" | tail -n 1 | cut -d: -f1 || true
}

append_line() {
  # Évite de coller l'entrée à une dernière ligne sans saut de ligne final
  if [ -s "$gitignore" ] && [ -n "$(tail -c 1 "$gitignore")" ]; then
    printf '\n' >>"$gitignore"
  fi
  printf '%s\n' "$1" >>"$gitignore"
  echo ".gitignore : ajout de $1"
}

missing=()
for entry in .env '.env.*'; do
  has_line "$entry" || missing+=("$entry")
done
if [ "${#missing[@]}" -gt 0 ]; then
  if has_line '!.env.example'; then
    # Insère les entrées manquantes juste avant la première négation
    tmp=$(mktemp)
    # Passées par l'environnement : awk -v refuse les sauts de ligne
    lines="$(printf '%s\n' "${missing[@]}")" \
      awk '!done && $0 == "!.env.example" { print ENVIRON["lines"]; done = 1 } { print }' \
      "$gitignore" >"$tmp"
    cat "$tmp" >"$gitignore"
    rm -f "$tmp"
    for entry in "${missing[@]}"; do
      echo ".gitignore : ajout de $entry (avant !.env.example)"
    done
  else
    for entry in "${missing[@]}"; do
      append_line "$entry"
    done
  fi
fi

last_negation=$(last_line_of '!.env.example')
last_pattern=$(last_line_of '.env.*')
if [ -z "$last_negation" ] || [ "$last_negation" -lt "$last_pattern" ]; then
  append_line '!.env.example'
fi

has_line .claude/settings.local.json || append_line .claude/settings.local.json

# --- Activation du pre-commit ------------------------------------------------

if [ "$is_git" -eq 1 ]; then
  current=$(git -C "$target" config --local --get core.hooksPath || true)
  if [ -z "$current" ]; then
    git -C "$target" config core.hooksPath .githooks
    echo "Git : core.hooksPath = .githooks"
  elif [ "$current" != .githooks ]; then
    if [ "$force" -eq 1 ]; then
      git -C "$target" config core.hooksPath .githooks
      warnings+=("Attention : core.hooksPath valait « $current », remplacé par .githooks : les hooks de $current ne sont plus exécutés.")
    else
      warnings+=("Attention : core.hooksPath vaut déjà « $current », valeur conservée : le pre-commit gitleaks n'est pas actif. Appelle .githooks/pre-commit depuis tes hooks, ou relance avec --force.")
    fi
  fi
else
  steps+=("Initialiser Git (git init), puis activer le pre-commit : git config core.hooksPath .githooks")
fi

# --- Outils requis -------------------------------------------------------------

if ! command -v gitleaks >/dev/null 2>&1; then
  steps+=("Installer gitleaks : tant qu'il est absent, le pre-commit bloquera tous les commits.")
fi
if ! command -v jq >/dev/null 2>&1; then
  steps+=("Installer jq : sans lui, les hooks de Claude Code ne fonctionnent pas. protect-secrets.sh échoue sans bloquer : l'accès de l'agent aux .env n'est plus protégé.")
fi

# --- Bilan -----------------------------------------------------------------------

steps+=(
  "Ajouter le secret CLAUDE_CODE_OAUTH_TOKEN au dépôt GitHub (Settings > Secrets and variables > Actions), pour la revue IA."
  "Installer l'application GitHub Claude sur le dépôt (dans Claude Code : /install-github-app)."
  "Créer un ruleset sur main : PR obligatoire, vérifications requises « Tests des garde-fous » et « Détection de secrets »."
  "Créer le label agent-corrigé : gh label create agent-corrigé --color D93F0B --description \"Code de l'agent refusé ou corrigé par l'humain\""
  "Compléter les sections « À ADAPTER » du CLAUDE.md."
)

echo
for warning in "${warnings[@]+"${warnings[@]}"}"; do
  echo "$warning"
done
echo "Étapes manuelles restantes :"
for step in "${steps[@]}"; do
  echo "- $step"
done
