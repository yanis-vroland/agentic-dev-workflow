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
