# Journal : contrôle avant publication (spec 010, CA9 à CA11)

Branche `feat/verifier-avant-public`.

## 2026-11-05 19:40

### Fait

- Branche créée depuis `main` à jour (`affa75a`), pour la seconde PR de la spec 010 : `scripts/verifier-avant-public.sh` et la skill `/publier` (CA9 à CA11).
- Spec 010 : ligne « Design : sans objet » ajoutée ; trois précisions dans « Cas limites et erreurs » (références de PR, `.env` suivi, socle).
- `docs/learnings/` n'existe pas dans le template : aucun piège à relire.

### Décisions

- Yanis : Design « sans objet » ; contrôle des `refs/pull/*` par récupération dans un espace temporaire puis contrôle des noms sur les commits qu'aucune branche n'atteint ; `.env` regardé dans les fichiers suivis seulement ; script et test copiés par `init.sh` avec la skill.

### Corrections et limites

- Aucune pour l'instant.

### Prochaine étape

- Tests par le subagent `test-writer`, vérification de leur échec, puis accord de Yanis avant l'implémentation.

## 2026-11-05 20:00

### Fait

- Tests écrits par `test-writer` : `tests/verifier-avant-public.sh` (55 vérifications, CA9 à CA11 et cas limites) et bloc « Spec 010 Socle » dans `tests/init-script.sh` (11 vérifications).
- Échec vérifié pour la bonne raison : 54 sur 55 échouent parce que le script et la skill sont absents (la seule qui passe est une précondition indépendante du script) ; seules les 11 vérifications du socle échouent dans `init-script.sh`. shellcheck sans avertissement.

### Décisions

- Contrat proposé par l'agent, à valider par Yanis : sans liste de noms, sans `origin`, le script sort en 1 (dépôt non déclaré publiable).

### Corrections et limites

- Aucune.

### Prochaine étape

- Accord de Yanis sur le contrat, puis implémentation.
