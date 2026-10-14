# ADR-004 : Choix de l'outil d'agent

Statut : proposé
Date : 2026-10-12

Contexte : le template repose sur un seul outil d'agent, Claude Code, sans que ce choix ait été écrit. Il a été fait au démarrage (2026-10-07), avant le premier ADR : l'ADR-001 le tient déjà pour acquis. Cet ADR le formalise après coup. Il dit sur quoi la chaîne dépend réellement de l'outil, et ce que coûterait d'en changer.

La chaîne utilise aujourd'hui, de Claude Code :
- **Fichier de contexte** : `CLAUDE.md`, lu à chaque session.
- **Hooks déterministes** : `PreToolUse` (`protect-secrets.sh` refuse une action par le code de sortie 2), `PostToolUse` (`format.sh`), `SessionStart` (`session-start.sh`), branchés dans `.claude/settings.json`.
- **Subagents aux outils restreints** : `learning-curator` sans `Bash`, ce que la CI vérifie ; `reviewer` et `test-writer`.
- **Skills** : `cadrage`, `spec`, `maquette`, `implement` et `review`. Les quatre premières sont lancées par l'agent après l'accord de l'humain, sur l'étape suivante du plan ([spec 008](../specs/008-cadrage-et-plan-global.md)). L'accord de l'humain avant de lancer une skill n'est plus une protection technique (`disable-model-invocation`) mais une consigne de `CLAUDE.md` et des skills : une consigne injectée (document de cadrage, ligne du plan) peut amener l'agent à lancer une skill sans accord ; les points de contrôle suivants (tests rouges, test humain, merge) restent humains. `review` garde son invocation automatique désactivée (`disable-model-invocation`) et tourne dans un contexte séparé (`context: fork`).
- **Réglages versionnés** : permissions refusées et mémoire locale désactivée (`autoMemoryEnabled`, spec 004).
- **Revue IA en CI** : `anthropics/claude-code-action`, qui applique les consignes du même `reviewer.md` qu'en local.
- **Authentification** : jeton d'abonnement en CI (ADR-001).

Options envisagées (fonctionnalités relevées dans la documentation de chaque outil le 2026-10-12, à revérifier avant validation) :
- **Claude Code** : couvre tous les points ci-dessus avec un seul outil, en local comme en CI. Il est lié aux modèles d'Anthropic, et son format (`CLAUDE.md`, `.claude/`) lui est propre.
- **Cursor (mode agent)** : règles de projet (`.cursor/rules`) et hooks de projet (`.cursor/hooks.json`, par exemple `beforeShellExecution`, `beforeReadFile`, `afterFileEdit`), repris par ses agents dans le cloud. Plusieurs modèles au choix. Il est centré sur un éditeur, qui deviendrait un prérequis du template.
- **GitHub Copilot (agent de code)** : agents personnalisés en Markdown avec frontmatter (`.github/agents/`), hooks (`.github/hooks/*.json`, dont `preToolUse` et `postToolUse`), intégration native aux issues et aux PR. Il travaille surtout de façon asynchrone dans GitHub Actions, et suppose un abonnement Copilot.
- **Aider** : open source, indépendant du modèle, commit de chaque modification, lint et tests lancés après chaque modification (`--lint-cmd`, `--test-cmd`, `--auto-test`). Il n'a ni subagents ni hook capable de refuser une action avant qu'elle ait lieu : le garde-fou sur les fichiers `.env` ne pourrait pas y être porté tel quel.

Décision proposée : garder Claude Code comme seul outil d'agent du template.
- Il porte toute la chaîne avec un seul format et un seul abonnement : hooks bloquants, subagents aux outils restreints, skills, et revue IA en CI qui lit les mêmes fichiers qu'en local.
- Les garde-fous ont été testés contre son contrat de hook (codes de sortie, JSON sur stdin) et contre une version précise (2.1.291, indiquée dans le README).
- Le but du template est de montrer une méthode, pas de comparer des outils : un deuxième outil doublerait la configuration et ses tests sans rien prouver de plus sur la méthode.
- Les principes restent indépendants de l'outil (spec validée, test-first, point de contrôle humain, journal, pièges) et sont écrits en Markdown et en shell.

Conséquences :
- **Dépendance assumée** à un fournisseur et à ses changements : un changement du contrat des hooks ou du format des subagents casse des garde-fous. Les tests des hooks (`tests/hooks.sh`) et l'étape de CI sur les outils de `learning-curator` le détectent ; la version testée est notée dans le README.
- **Portabilité partielle** : les specs, ADR, journaux, pièges et scripts shell se réutilisent tels quels. `CLAUDE.md`, `.claude/` et `ai-review.yml` seraient à traduire. Cursor et Copilot ont désormais des hooks comparables, la traduction serait donc surtout de forme ; avec Aider, le refus préalable d'une action serait perdu.
- **Pas de comparaison mesurée** : aucun autre outil n'a été essayé sur ce dépôt. Les options ci-dessus sont fondées sur la documentation, pas sur un usage. Un essai sur une fonctionnalité de FieldOps donnerait une base réelle, à décider par un nouvel ADR si le besoin apparaît.
- **Coût** : lié à l'abonnement Claude (ADR-001), sans chiffre par PR.
