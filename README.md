# agentic-dev-workflow

Template de développement agentique pour les développeurs qui confient du code à Claude Code : de la spec validée à la PR mergée, avec des garde-fous locaux, une CI et une revue IA de chaque PR.

**Statut : en construction, pas encore éprouvé sur un projet réel. Il le sera d'abord sur le projet FieldOps.**
Version de Claude Code testée : **2.1.291**, le 2026-10-08.

## Prérequis

| Outil | Rôle | Sans lui |
| --- | --- | --- |
| [Claude Code](https://claude.com/claude-code) | l'agent de code | — |
| [jq](https://jqlang.org) | lu par les hooks de Claude Code | les hooks refusent **toutes** les actions surveillées (Read, Edit, Write, Bash) |
| [gitleaks](https://github.com/gitleaks/gitleaks), même version que la CI (`GITLEAKS_VERSION` dans `garde-fous.yml`) | détection de secrets avant chaque commit | le hook pre-commit refuse **tous** les commits |
| [shellcheck](https://www.shellcheck.net) | vérification des scripts shell | seule la CI les vérifie |
| [gh](https://cli.github.com) | GitHub en ligne de commande | configuration GitHub à faire dans l'interface web |

La CI installe elle-même gitleaks en version fixée, avec vérification de sa somme de contrôle.

## Installation

### Nouveau projet

1. Sur GitHub, cliquer sur **« Use this template »** pour créer le dépôt, puis le cloner.
2. Supprimer les fichiers propres au template :

   ```bash
   git rm docs/adr/001-authentification-ci.md docs/specs/001-script-init.md \
     docs/specs/002-hook-protect-secrets.md scripts/init.sh tests/init-script.sh \
     .github/workflows/template-ci.yml
   ```

3. Remplacer `docs/journal.md` par un journal vide :

   ```bash
   cat > docs/journal.md <<'EOF'
   # Journal de bord

   Ce que l'agent a bien fait, ce que j'ai corrigé et pourquoi, les limites observées.
   EOF
   ```

4. Activer le hook pre-commit (une fois par clone) :

   ```bash
   git config core.hooksPath .githooks
   ```

5. Remplacer ce `README.md` par celui du projet, en gardant si besoin un lien vers le template :

   ```bash
   printf '# <nom du projet>\n\nInitialisé avec https://github.com/yanis-vroland/agentic-dev-workflow\n' > README.md
   ```

6. Committer ce nettoyage, puis passer à la [configuration GitHub](#configuration-github), à suivre depuis le README du template.

### Projet existant

Cloner ce template n'importe où, puis lancer le script depuis ce clone :

```bash
git clone https://github.com/yanis-vroland/agentic-dev-workflow.git
agentic-dev-workflow/scripts/init.sh <chemin-du-projet> [--force]
```

Le script :

- copie les garde-fous, les skills, les workflows génériques, le modèle de PR et `CLAUDE.md` ;
- n'écrase aucun fichier existant sans `--force`, et liste ceux qu'il a ignorés ;
- crée `docs/adr/`, `docs/specs/` et `docs/journal.md` ;
- complète le `.gitignore` (`.env`, `.env.*`, `!.env.example`, `.claude/settings.local.json`) ;
- active `core.hooksPath` ;
- affiche à la fin les étapes manuelles restantes.

Il refuse de cibler un sous-dossier d'un dépôt Git : il faut viser la racine. Comportement détaillé : [`docs/specs/001-script-init.md`](docs/specs/001-script-init.md).

Si le projet a déjà un `.claude/settings.json`, le script ne l'écrase pas, et **les garde-fous ne sont alors pas installés** : il faut fusionner à la main les permissions et les hooks du template.

### Dans les deux cas

Compléter les sections **« À ADAPTER »** de `CLAUDE.md` : description du projet, commandes, architecture.

## Configuration GitHub

1. **Application GitHub Claude** : dans Claude Code, lancer `/install-github-app` et suivre les étapes.
2. **Secret `CLAUDE_CODE_OAUTH_TOKEN`** : générer un jeton avec `claude setup-token`. L'ajouter ensuite au dépôt, dans *Settings > Secrets and variables > Actions*, ou avec `gh secret set CLAUDE_CODE_OAUTH_TOKEN`. La revue IA s'authentifie avec ce jeton ; le choix d'un jeton d'abonnement plutôt que d'une clé API est expliqué dans l'[ADR-001](docs/adr/001-authentification-ci.md).
3. **Ruleset sur `main`** (*Settings > Rules > Rulesets*) :
   - PR obligatoire ;
   - suppression et force-push interdits ;
   - vérifications requises : « Tests des garde-fous » et « Détection de secrets ». Sur ce template, s'y ajoute « Vérifications du template ».
4. **Label `agent-corrigé`**, qui marque les PR où du code de l'agent a été refusé ou corrigé :

   ```bash
   gh label create agent-corrigé --color D93F0B --description "Code de l'agent refusé ou corrigé par l'humain"
   ```

## Garde-fous

- **Hook `protect-secrets.sh`** (Claude Code) : refuse à l'agent l'accès aux fichiers `.env` et `.env.*`, sauf `.env.example`. Une simple mention dans un message de commit ou un corps de PR reste permise. En cas de doute (commande non analysable, erreur interne, jq absent), il refuse. Comportement détaillé : [`docs/specs/002-hook-protect-secrets.md`](docs/specs/002-hook-protect-secrets.md).
- **Hook `pre-commit`** (Git) : gitleaks analyse les fichiers indexés et refuse le commit si un secret est détecté. Il se contourne avec `git commit --no-verify` : le vrai filet de sécurité est le job CI « Détection de secrets », qui analyse tout l'historique.
- **Revue IA** : chaque PR ouverte est relue selon `.claude/agents/reviewer.md`, et le rapport est publié en commentaire. Le job échoue si la revue n'a pas tourné ou si des actions ont été refusées pendant la revue. Une PR qui modifie `ai-review.yml` ne peut pas être relue par l'IA (protection de `claude-code-action`) : son job « Revue IA » est rouge, et elle se relit à la main.

## Structure

| Élément | Rôle |
| --- | --- |
| `CLAUDE.md` | règles de travail de l'agent : langue, spec avant code, test-first, définition du « done », interdits |
| `.claude/settings.json` | permissions refusées à l'agent et branchement des hooks |
| `.claude/hooks/protect-secrets.sh` | refus des accès aux fichiers `.env` |
| `.claude/hooks/format.sh` | formatage par Prettier après chaque modification, s'il est installé dans le projet |
| `.claude/skills/spec/` | `/spec` : rédiger une spec à partir d'un besoin |
| `.claude/skills/implement/` | `/implement` : implémenter une spec validée en test-first |
| `.claude/skills/review/` | `/review` : relire la branche avant la PR |
| `.claude/agents/reviewer.md` | subagent de revue, utilisé aussi par la revue IA en CI |
| `.claude/agents/test-writer.md` | subagent qui écrit les tests à partir des critères d'acceptation |
| `.githooks/pre-commit` | détection de secrets avant chaque commit |
| `.github/workflows/garde-fous.yml` | CI générique : tests des hooks, test du pre-commit, détection de secrets |
| `.github/workflows/ai-review.yml` | revue IA de chaque PR |
| `.github/workflows/template-ci.yml` | CI propre au template, non copiée par `init.sh` |
| `.github/scripts/verifier-revue-ia.sh` | fait échouer la revue IA si elle n'a pas tourné ou a subi des refus |
| `.github/pull_request_template.md` | modèle de PR : spec liée, critères couverts, vérifications humaines, corrections |
| `docs/templates/spec.md` | modèle de spec |
| `docs/specs/` | specs du projet |
| `docs/adr/` | décisions d'architecture |
| `docs/journal.md` | journal de bord : ce que l'agent a bien fait, ce qui a été corrigé, les limites |
| `docs/guide-adoption.md` | introduire le template dans une équipe : rôles, rituels, démarrage progressif |
| `scripts/init.sh` | application du template à un projet existant |
| `tests/` | tests des hooks, du pre-commit, de la vérification de la revue et de `init.sh` |

## Licence

MIT, voir [LICENSE](LICENSE).
