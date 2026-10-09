# Journal : règles de PR issues de la mémoire locale

Branche `docs/regles-pr`.

## 2026-10-09 16:50

### Fait

- `CLAUDE.md`, règle n°6 : PR toujours basée sur `main` et jamais empilée, rebase par l'agent quand une autre PR touche les mêmes fichiers, tous les commits poussés avant d'annoncer qu'une PR est prête, dernier commit vérifié sur `main` après le merge.

### Décisions

- Règles reprises de la mémoire locale de l'agent sur FieldOps (incidents des PR #7 et #9 de FieldOps) et de la perte constatée au merge de #32 du template. La mémoire locale des deux projets est supprimée une fois les règles versionnées (spec 004).

### Corrections et limites

- Ces règles n'ont pas de test : ce sont des consignes. Le ruleset de `main` n'empêche pas une PR empilée.

### Prochaine étape

- Aucune sur le template. Reprendre la phase 1 de FieldOps (spec 002).
