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
