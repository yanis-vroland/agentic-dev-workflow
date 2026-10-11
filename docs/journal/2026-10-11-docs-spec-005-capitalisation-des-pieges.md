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

## 2026-10-11 21:20

### Fait

- Implémentation : `init.sh` crée `docs/learnings/` ; subagent `learning-curator` (sans `Bash`) ; `/implement` (relecture des pièges, test humain avec boucle, capitalisation) ; `/spec` (relecture des pièges) ; `reviewer` (pièges enfreints ou doublons) ; définition du « done » de `CLAUDE.md` ; modèle de PR ; README (garde-fous, limites, structure, fichiers à retirer).
- `tests/init-script.sh` : 225 vérifications au vert. Étape CI CA4 au vert. shellcheck au vert.
- Contrôle par mutation : `Bash` ajouté aux outils de `learning-curator` → détecté par l'étape CI ; `docs/learnings` retiré de `init.sh` → 2 échecs (CA1, CA2).

### Décisions

- Rien de nouveau.

### Corrections et limites

- Le premier passage des tests échouait sur CA1 : `init.sh` ne copie que les fichiers suivis par Git, il fallait indexer le nouveau subagent. Comportement voulu (spec 001, CA22), pas un défaut.
- CA5 à CA11 sont des consignes, vérifiées par relecture humaine. CA12 (vrai piège sur FieldOps) reste à faire : la spec n'est pas « livrée » tant qu'il manque.

### Prochaine étape

- Relecture de la PR #35 par Yanis, puis merge.
- Reporter la chaîne dans FieldOps (`init.sh --force` sur les fichiers de la chaîne) et y exercer CA12 sur la prochaine fonctionnalité.

## 2026-10-11 21:27

### Fait

- Exemples de pièges de la spec 005 et de `learning-curator` remplacés par des exemples tirés du glossaire de FieldOps (réservation, quantité disponible, pagination, migration, code de machine).

### Décisions

- Exemples ancrés dans FieldOps plutôt qu'abstraits (Yanis).

### Corrections et limites

- Les exemples précédents étaient génériques mais inspirés d'un cas observé hors de ce dépôt : remplacés pour qu'aucune ressemblance ne subsiste.

### Prochaine étape

- Relecture de la PR #35 par Yanis, puis merge.
