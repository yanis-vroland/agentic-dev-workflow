# Journal : spec 005, test humain et capitalisation des pièges

Branche `docs/spec-005-capitalisation-des-pieges`.

## 2026-10-11 21:14

### Fait

- Spec 005 rédigée au statut « brouillon » : test humain non délégable dans `/implement`, pièges capitalisés dans `docs/learnings/` (un fichier par piège), subagent `learning-curator` sans `Bash`, relecture des pièges par `/spec`, `/implement` et le `reviewer`.

### Décisions

- Périmètre retenu par Yanis : test humain et capitalisation des pièges. Relecteur strictement en lecture seule et cadrage par l'existant reportés.
- Un fichier par piège plutôt qu'un fichier par domaine, pour éviter les conflits entre PR (même principe que la spec 004) (proposition de l'agent, à valider).
- Démonstration réelle sur FieldOps exigée avant le statut « livrée » (CA12) (proposition de l'agent, à valider).

### Corrections et limites

- Rien.

### Prochaine étape

- Attendre la validation de la spec par Yanis et ses réponses aux trois questions ouvertes. Ensuite : tests (CA1 à CA4) committés en échec, puis implémentation.
