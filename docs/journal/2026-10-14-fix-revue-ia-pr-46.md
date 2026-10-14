# Journal : suites de la revue IA de la PR #46

Branche `fix/revue-ia-pr-46`.

## 2026-10-14 20:22

### Fait

- Points mineurs de la revue IA de la PR #46 corrigés : `reviewer.md` vérifie les cases et les écarts du plan (point 3) ; modèle de PR qui cite le plan (point 4) ; message de fin d'`init.sh` « remplit docs/plan.md » (point 7) ; suggestions 5 (espace en trop dans l'ADR-004) et 7 (« si `docs/plan.md` existe » dans la définition du done).
- Issues ouvertes avec l'accord de Yanis (point 6) : #47 (CA20 à vérifier), #48 (aucune skill pour les ADR), #49 (branche de spec sur `docs/cadrage`).
- Description de la PR #46 complétée : ajouts à la spec validée (CA22, CA23, trois cas limites) signalés (point 5), ligne de test humain au format du modèle (suggestion 6).
- `tests/init-script.sh` : 283 OK ; shellcheck sans avertissement.

### Décisions

- Points 1 (aucun push pendant le cadrage avant l'accord) et 2 (confidentialité étendue aux branches, commits et PR) reportés, sans issue pour l'instant (Yanis).
- Suggestions non suivies dans cette PR : 1 (`init.sh` crée un plan sur un projet déjà cadré, ce qui masque le cas CA21 : changement de comportement, à spécifier), 2 (troncature selon la locale), 3 (documents de besoin déposés dans le dépôt) ; 4 sans objet (journal déjà mergé) (agent).

### Corrections et limites

- Les ajouts CA22 et CA23 à la spec 008 attendent toujours une validation explicite de Yanis.

### Prochaine étape

Yanis relit et merge. Ensuite : décision sur les points 1 et 2 de la revue, puis implémentation de la spec 009.
