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

## 2026-10-20 11:20

### Fait

- Correctif dans `.github/scripts/verifier-journal.sh` : une suppression (statut D) est acceptée si le fichier existe dans un commit racine de `<head>` (`git rev-list --max-parents=0`, toutes les racines). Une suppression dont le contenu est réajouté sous un autre nom dans la même PR reste refusée : avec `--no-renames`, un renommage apparaît comme D + A.
- Tests : `tests/verifier-journal.sh` au vert (37 OK) ; shellcheck et autres tests des garde-fous au vert.
- Contrôle par mutation, chaque protection désactivée une fois :
  - toute suppression acceptée : 2 tests échouent (CA9 suppression, CA9 bis journal ajouté après le commit racine) ;
  - contrôle du renommage désactivé : 1 test échoue (CA9 bis renommage) ;
  - exception du commit racine désactivée : 3 tests échouent (CA9 bis).
- Vérifié sur le cas réel : le script corrigé accepte le diff de la PR #1 de `workflow-editorial-agents` (303f679...1ea05ef), que la version de `main` refuse.

### Décisions

- Détection du renommage par comparaison des contenus (blobs) : nécessaire pour tenir le CA9 bis tel que validé (agent).

### Corrections et limites

- Premier correctif sans le contrôle du renommage : le test CA9 bis du renommage l'a détecté (D accepté + A au nom valide).
- Limite : un journal du commit racine supprimé et réajouté avec un contenu modifié sous un autre nom n'est pas vu comme un renommage ; le nouveau fichier passe alors les contrôles d'un journal ajouté (nom et entrées datés).

### Prochaine étape

README, procédure « Nouveau projet » : fichiers à retirer et journal du template.

## 2026-10-20 11:20

### Fait

- README, procédure « Nouveau projet » : l'étape 2 retire aussi les fichiers qu'`init.sh` ne copie pas (ADR 002 à 005, `docs/demo/`, `docs/guide-adoption.md`, `renovate.json`), liste vérifiée contre `scripts/init.sh` ; l'étape 3 indique que le job « Journal » accepte la suppression (CA9 bis).
- `docs/guide-adoption.md` renvoie au README pour la procédure : rien à aligner.

### Décisions

- Aucune nouvelle.

### Corrections et limites

- La PR #58, encore ouverte, ajoute `docs/specs/010-noms-exclus.md` au même `git rm` du README : conflit attendu, à résoudre par un rebase de cette PR après le merge de la #58.

### Prochaine étape

Yanis relit et merge. Après le merge de la #58 : rebase de cette PR par l'agent.
