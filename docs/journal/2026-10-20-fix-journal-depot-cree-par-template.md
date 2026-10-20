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
