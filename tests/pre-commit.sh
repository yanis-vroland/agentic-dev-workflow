#!/usr/bin/env bash
# Vérifie que le hook pre-commit bloque un secret indexé et laisse passer le reste.
set -u

hooks_dir="$(cd "$(dirname "$0")/../.githooks" && pwd)"
fail=0

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

repo="$work/repo"
git init -q "$repo"

commit() {
  git -C "$repo" -c core.hooksPath="$hooks_dir" \
    -c user.name=test -c user.email=test@example.com \
    commit -q -m "test" >/dev/null 2>&1
}

check() {
  local expected=$1 description=$2 code=$3
  if [ "$code" -eq "$expected" ]; then
    echo "OK     $description"
  else
    echo "ÉCHEC  $description (attendu $expected, obtenu $code)"
    fail=1
  fi
}

# Faux jeton GitHub construit à l'exécution : il ne doit jamais apparaître
# en clair dans ce fichier, sinon le job gitleaks de la CI le détecterait.
prefix="ghp"
suffix=$(LC_ALL=C tr -dc 'A-Za-z0-9' </dev/urandom | head -c 36)
printf 'github = "%s_%s"\n' "$prefix" "$suffix" >"$repo/config.txt"
git -C "$repo" add config.txt
commit
check 1 "Commit avec un secret : refusé" $?

git -C "$repo" rm -q --cached config.txt
rm "$repo/config.txt"

echo "Bonjour" >"$repo/README.md"
git -C "$repo" add README.md
commit
check 0 "Commit sans secret : accepté" $?

# Sans gitleaks dans le PATH, le hook doit refuser avec un message explicite
fake_bin="$work/bin"
mkdir "$fake_bin"
for cmd in bash git; do
  ln -s "$(command -v "$cmd")" "$fake_bin/$cmd"
done
echo "Encore" >>"$repo/README.md"
git -C "$repo" add README.md
output=$(cd "$repo" && PATH="$fake_bin" "$hooks_dir/pre-commit" 2>&1)
check 1 "Sans gitleaks : refusé" $?
if grep -q "gitleaks n'est pas installé" <<<"$output"; then
  echo "OK     Sans gitleaks : message explicite"
else
  echo "ÉCHEC  Sans gitleaks : message absent (sortie : $output)"
  fail=1
fi

exit $fail
