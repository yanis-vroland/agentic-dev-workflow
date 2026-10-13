#!/usr/bin/env bash
# Lint du template (spec 006, CA23) : shellcheck sur un fichier shell, rien sur les
# autres. Fichier shell : extension .sh, ou première ligne #! qui cite sh ou bash.
# Déclaré dans .claude/quality.json du template ; non copié par init.sh.
set -u

file=${1:?usage : lint-shell.sh <fichier>}

is_shell=0
case "$file" in
  *.sh) is_shell=1 ;;
  *)
    first_line=$(head -n 1 -- "$file" 2>/dev/null)
    if [[ "$first_line" =~ ^#!.*[/[:space:]](ba)?sh([[:space:]]|$) ]]; then
      is_shell=1
    fi
    ;;
esac

[ "$is_shell" -eq 1 ] || exit 0
# -x : suit les fichiers sourcés déclarés par « shellcheck source= », comme en CI
exec shellcheck -x -- "$file"
