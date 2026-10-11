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

## 2026-10-11 21:18

### Fait

- Spec 005 validée par Yanis, avec les trois propositions retenues (section « Décisions »).
- Tests committés en échec : `tests/init-script.sh` (CA1 et CA2 échouent, CA3 passe déjà) et étape CI « Outils du subagent learning-curator » (CA4, échoue tant que le subagent n'existe pas).

### Décisions

- Le test humain s'applique aussi aux corrections ; CA12 conditionne le statut « livrée », pas le merge ; pas de piège d'exemple dans le template (Yanis).
- Spec, tests et implémentation dans la même PR #35, comme pour la spec 004 (agent).

### Corrections et limites

- Tests écrits par l'agent principal, pas par le subagent `test-writer` : il n'est pas invocable dans cette session (lancée depuis le dossier parent, les subagents du dépôt ne sont pas chargés).
- CA3 passe sans implémentation : c'est une garde de non-régression (le comportement « jamais écrasé » existe déjà pour les autres dossiers), pas un test du nouveau code.

### Prochaine étape

- Implémenter : `init.sh`, subagent `learning-curator`, `/implement`, `/spec`, `reviewer`, `CLAUDE.md`, modèle de PR, README. Puis contrôle par mutation de l'étape CI.
