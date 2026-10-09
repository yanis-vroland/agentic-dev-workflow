# Démonstration du template agentic-dev-workflow (issue #19).
# Générer le GIF depuis la racine du dépôt : vhs docs/demo/demo.tape
# Prérequis : vhs (et ses dépendances ttyd, ffmpeg), jq, gitleaks.
# Tout se passe dans un dossier temporaire : le dépôt n'est pas modifié.

Output docs/demo/demo.gif

Set Shell "bash"
Set FontSize 16
Set Width 1200
Set Height 720
Set Theme "Catppuccin Mocha"
Set TypingSpeed 40ms
Set Padding 20
Set Framerate 12

# Préparation invisible : projet Git vide, identité Git locale, faux jeton
# assemblé à l'exécution (il n'apparaît jamais en clair dans ce fichier).
Hide
Type `export TEMPLATE="$PWD" PS1='$ ' GIT_PAGER=cat PAGER=cat && cd "$(mktemp -d)" && git init -q projet`
Enter
Type `git -C projet config user.name demo && git -C projet config user.email demo@example.com && git -C projet config commit.gpgsign false`
Enter
Type `FAKE="ghp""_""R7xK2mQ9vL4tW8nB3c""Y6pZ1sD5fH0jG7aE2u" && clear`
Enter
Show

# 1. Application du template à un projet existant
Type "# 1. Appliquer le template à un projet Git vide"
Enter
Sleep 1s
Type `"$TEMPLATE"/scripts/init.sh projet | tail -n 12`
Enter
Sleep 5s
Type "ls -A projet"
Enter
Sleep 2s
Type `cd projet && git add -A && git commit -qm "chore: application du template" && git log --oneline`
Enter
Sleep 3s
Type "clear"
Enter

# 2. Le pre-commit gitleaks refuse un secret
Type "# 2. Un commit qui contient un jeton est refusé"
Enter
Sleep 1s
Hide
Type `printf 'github = "%s"\n' "$FAKE" > config.txt`
Enter
Show
Type `git add config.txt && git commit -m "feat: configuration"`
Enter
Sleep 5s
Hide
Type `git rm -q --cached config.txt && rm config.txt`
Enter
Show
Type "clear"
Enter

# 3. Le hook protect-secrets de Claude Code
Type "# 3. L'agent ne peut pas lire un fichier .env ..."
Enter
Sleep 1s
Type `echo '{"tool_name":"Read","tool_input":{"file_path":".env"}}' | .claude/hooks/protect-secrets.sh; echo "code $?"`
Enter
Sleep 3s
Type "# ... mais peut le citer dans un message de commit"
Enter
Sleep 1s
Type `echo '{"tool_name":"Bash","tool_input":{"command":"git commit -m \"chore: ignorer .env.local\""}}' | .claude/hooks/protect-secrets.sh; echo "code $?"`
Enter
Sleep 4s
