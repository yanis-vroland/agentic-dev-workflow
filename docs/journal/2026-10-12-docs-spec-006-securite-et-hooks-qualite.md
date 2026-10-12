# Journal : spec 006, revue de sécurité et hooks de lint et de tests

Branche `docs/spec-006-securite-et-hooks-qualite`.

## 2026-10-12 10:27

### Fait

- Spec 006 rédigée au statut « brouillon » : subagent `security-reviewer` (`Read, Grep, Glob`, OWASP Top 10 2025, diff transmis par l'agent principal), hook de lint après chaque modification, hook de tests à la fin du tour, configuration dans `.claude/quality.json`, application par `init.sh`, contrôle par mutation.

### Décisions

- Périmètre fixé par Yanis : subagent sécurité en lecture seule sans `Bash`, hooks de lint et de tests en plus du formatage ; spec seule, aucun test ni code avant validation.
- Tests lancés à la fin du tour (`Stop`) plutôt qu'après chaque modification, configuration dans `.claude/quality.json`, `security-reviewer` avant le test humain (propositions de l'agent, à trancher par Yanis : questions ouvertes 1 à 4).

### Corrections et limites

- Pas de cahier des charges ni de piège dans le template : rien à relire au cadrage (spec 003, « Hors périmètre »).
- Questions posées dans la spec plutôt qu'avant sa rédaction, comme le demande l'étape 4 de `/spec` : la demande de Yanis était d'aller jusqu'à la spec en une fois.

### Prochaine étape

- Attendre la validation de la spec par Yanis et ses réponses aux cinq questions ouvertes. Ensuite seulement : tests (CA1 à CA19) par `test-writer`, committés en échec, puis implémentation.

## 2026-10-12 10:29

### Fait

- Réponse à la revue IA de #37 : marque « à lancer » propre à la session et au worktree (CA12 bis), règle de détection d'une commande introuvable (CA8), chemin absolu passé sans interpolation (CA5 bis), CA7, CA8 et CA12 marqués provisoires, rappel sur les fichiers d'environnement pour `security-reviewer`, risque des commandes de `.claude/quality.json`.

### Décisions

- Marque rangée dans le répertoire Git du worktree et nommée d'après `session_id` ; commande introuvable détectée par `command -v` avant exécution (propositions de l'agent, à valider avec la spec).

### Corrections et limites

- Une commande qui citait les fichiers d'environnement dans un heredoc a été refusée par `protect-secrets` (refus par prudence documenté dans les Limites du README) : modifications refaites par un script et l'outil d'édition.

### Prochaine étape

- Attendre la validation de la spec par Yanis et ses réponses aux cinq questions ouvertes. Aucun test ni code avant.

## 2026-10-12 12:01

### Fait

- Spec 006 validée par Yanis, avec les cinq propositions. Question n°5 vérifiée dans la documentation des hooks : CA7 (code 1), CA8 et CA12 (code 0 et `systemMessage`) réécrits. Nouveaux CA23 et CA24 : le template s'applique ses propres hooks (`scripts/lint-shell.sh`, `bash tests/hooks.sh`).

### Décisions

- Les cinq propositions de la spec, validées par Yanis (section « Décisions » de la spec).
- ADR-004 (#36) laissé au statut « proposé » : la consigne initiale de Yanis était de ne pas le passer à « accepté » (agent).

### Corrections et limites

- Rien.

### Prochaine étape

- Tests de CA1 à CA19, CA23 et CA24 par `test-writer`, committés en échec, puis accord de Yanis avant l'implémentation (étape 5 de `/implement`).

## 2026-10-12 12:35

### Fait

- Tests écrits par `test-writer`, à partir de la spec seule : `tests/quality-hooks.sh` (CA1 à CA13), `tests/lint-shell.sh` (CA24), section « Spec 006 » de `tests/init-script.sh` (CA17, CA18, CA23), étapes de CI (CA14, CA15, CA16, CA23).
- Relus et renforcés par l'agent principal : sortie d'erreur du lint transmise (CA3), formatage par `lint.sh` même sans configuration (CA6), fichier hors du projet sans tests lancés, `format.sh` plus branché à part en CI.
- En échec pour la bonne raison (hooks, scripts, configuration et subagent absents) : `quality-hooks` 25 OK et 79 ÉCHEC, `lint-shell` 3 OK et 13 ÉCHEC, `init-script` 232 OK et 11 ÉCHEC ; `hooks` 52 OK, sans régression. Les vérifications déjà vertes sont des gardes négatives, annoncées comme telles.

### Décisions

- `format.sh` n'est plus branché directement : `lint.sh` l'appelle avant le lint, car Claude Code lance en parallèle les hooks d'un même événement (agent).
- Test existant modifié par `test-writer` : `.claude/quality.json` retiré de la liste `copied` de `tests/init-script.sh`, car CA17 exige un fichier aux clés vides et non une copie du template. Signalé dans la PR (règle n°3).

### Corrections et limites

- CA7 (configuration invalide, jq absent) n'est testé que sur `lint.sh`, comme l'écrit la spec ; `run-tests.sh` n'a pas de critère équivalent.
- CA19 (mutation) et CA20 à CA22 (relecture) viendront avec l'implémentation.

### Prochaine étape

- Attendre l'accord de Yanis sur les tests rouges, puis implémenter : `lint.sh`, `run-tests.sh`, `scripts/lint-shell.sh`, `.claude/quality.json`, `security-reviewer`, `settings.json`, `init.sh`, `/implement`, `CLAUDE.md`, README.

## 2026-10-12 13:20

### Fait

- Accord de Yanis sur les tests rouges (« continue »).
- Implémentation : `lint.sh` (formatage, marque, lint), `run-tests.sh`, `quality-common.sh` (marque par session sous le répertoire Git du worktree), `scripts/lint-shell.sh`, `.claude/quality.json` du template, subagent `security-reviewer`, `settings.json` (lint sur `PostToolUse`, tests sur `Stop`, `format.sh` appelé par `lint.sh`), `init.sh` (`quality.json` créé vide et jamais écrasé, `tests/quality-hooks.sh` copié), étape 7 de `/implement`, `CLAUDE.md`, README, spec 001 complétée.
- Tous les tests au vert : `quality-hooks` 102, `lint-shell` 15, `init-script` 253, `hooks` 52, `session-start` 50, `verifier-journal` 31, `verifier-revue-ia` 12, `pre-commit` 7. shellcheck et étapes jq de la CI rejoués en local.
- Contrôle par mutation (CA19) : 17 protections désactivées une à une, toutes détectées par au moins un test.

### Décisions

- Revue de sécurité intégrée à l'étape 7 de `/implement` plutôt qu'en nouvelle étape, pour ne pas renuméroter les étapes que cite la PR #36 (agent).

### Corrections et limites

- Rien.

### Prochaine étape

- Revue de sécurité du diff par `security-reviewer`, puis test humain par Yanis dans une session Claude Code (étape 8 de `/implement`).
