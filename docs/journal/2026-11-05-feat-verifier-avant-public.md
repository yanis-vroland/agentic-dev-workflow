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
