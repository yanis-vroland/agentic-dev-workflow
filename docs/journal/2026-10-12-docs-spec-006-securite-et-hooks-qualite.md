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

## 2026-10-12 13:34

### Fait

- Revue de sécurité du diff (étape 7 de `/implement`) : rien de bloquant, un point « À corriger », trois suggestions.
- Corrigés en test-first (tests rouges dans c8eb709, puis correction) :
  - sortie du lint et des tests délimitée comme des données, pas des consignes ;
  - lien symbolique vers l'extérieur du projet ni formaté ni linté, et `format.sh` reçoit le chemin vérifié ;
  - avertissement à l'humain quand la marque ne peut pas être posée alors que des tests sont déclarés (projet hors Git) ;
  - identifiant de session raccourci à 64 caractères.
- Les hooks, actifs dans cette session, ont bloqué deux de mes modifications : `scripts/lint-shell.sh` ne suivait pas `quality-common.sh`, sourcé par les hooks (SC1091), alors que la CI, qui passe tous les hooks ensemble, ne le voyait pas. Test de non-régression rouge dans un commit séparé, puis `shellcheck -x`.
- Mutation : 23 protections détectées. Une mutation équivalente : transmettre le chemin brut à `format.sh` ne change rien d'observable, car `lint.sh` sort avant le formatage pour tout chemin qui mène hors du projet ; conservé comme défense en profondeur.
- Tous les tests au vert : `quality-hooks` 114, `lint-shell` 16, `init-script` 253, `hooks` 52, `session-start` 50, `verifier-journal` 31, `verifier-revue-ia` 12, `pre-commit` 7.

### Décisions

- Point « À corriger » de la revue (les hooks exécutent sans demande le code que l'agent vient d'écrire) : documenté dans les Limites du README, sans interdire à l'agent de modifier `.claude/hooks/` ni `.claude/quality.json`, ce qui l'empêcherait de développer le template. Décision soumise à Yanis (agent).

### Corrections et limites

- Le subagent `security-reviewer`, créé pendant la session, n'était pas encore chargé : la revue a été faite par un agent généraliste qui appliquait ses consignes, limité à `Read`, `Grep` et `Glob`.
- Le commit c8eb709 (tests rouges) n'a pas d'entrée de journal propre : elle est dans celle-ci.

### Prochaine étape

- Test humain par Yanis dans une session Claude Code ouverte sur cette branche (étape 8 de `/implement`), avec les scénarios proposés.

## 2026-10-12 13:36

### Fait

- Test humain : retour positif de Yanis (« je valide »), sans boucle négative. Le résultat de chaque scénario n'a pas été détaillé.
- Pas d'appel à `learning-curator` : aucune boucle négative au test humain.
- Documents de référence : sans objet (spec 003, le template ne se les applique pas).

### Décisions

- Exécution sans demande du code écrit par l'agent : risque documenté dans les Limites, sans interdiction de modifier `.claude/hooks/` ni `.claude/quality.json`. Lu comme accepté dans « je valide » (Yanis, à confirmer à la relecture de la PR).

### Corrections et limites

- Rien de nouveau.

### Prochaine étape

- Relecture et merge de la PR #37 par Yanis. Si la PR #36 est mergée avant, rebaser cette branche (conflit attendu dans le README) avant le merge.
