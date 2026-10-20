# Journal : fix/journal-depot-cree-par-template

## 2026-10-20 11:17

### Fait

- Spec 004 complétée : CA9 bis et exception dans « Contrôle en CI ». La suppression d'un journal présent dans le commit racine du dépôt est acceptée ; sa modification ou son renommage restent refusés.

### Décisions

- Cas remonté depuis `workflow-editorial-agents` (PR #1) : dans un dépôt créé par « Use this template », l'étape 3 de la procédure « Nouveau projet » (vider le journal du template) est refusée par `verifier-journal.sh`, le job « Journal » est rouge.
- Correctif : exception limitée aux journaux du commit racine, plutôt qu'une procédure qui garderait les journaux du template dans chaque projet. Proposé par l'agent, CA9 bis validé par Yanis.

### Corrections et limites

- Un dépôt existant outillé par `init.sh` dont le commit racine contiendrait déjà des journaux pourrait les supprimer : cas jugé improbable, la modification reste refusée.

### Prochaine étape

Test de non-régression du CA9 bis, puis correctif de `verifier-journal.sh`.

## 2026-10-20 11:17

### Fait

- Tests du CA9 bis dans `tests/verifier-journal.sh` : suppression des journaux du commit racine acceptée (seule, ou avec l'ajout du journal de la branche) ; modification et renommage refusés ; journal ajouté après le commit racine toujours protégé, sans citer à tort ceux du template.
- Échec vérifié avant correctif, pour la bonne raison : 3 tests rouges, refus « fichier de journal déjà mergé » sur les journaux du commit racine.

### Décisions

- Aucune nouvelle.

### Corrections et limites

- **Fixture modifiée** : `new_repo` mettait le journal mergé dans le commit racine. Il est désormais ajouté dans un second commit, sinon le test CA9 de suppression contredirait le CA9 bis. Les assertions du CA9 sont inchangées.

### Prochaine étape

Correctif de `verifier-journal.sh`, puis contrôle par mutation.
