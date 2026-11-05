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

## 2026-11-05 20:30

### Fait

- `scripts/verifier-avant-public.sh` : trois contrôles lancés même si l'un échoue (noms exclus avec `--all`, références de PR récupérées dans `refs/verifier-avant-public-<pid>/` puis supprimées, fichiers d'environnement suivis), bilan final, codes 0, 1 et 2.
- `.claude/skills/publier/SKILL.md` : lance le script, refuse de proposer la mise en public tant qu'il échoue, donne la marche à suivre par échec, ne lance jamais la commande de mise en public.
- Socle : script et test ajoutés à la liste de `init.sh` ; test branché dans `garde-fous.yml` (shellcheck et étape dédiée) et dans le shellcheck de `template-ci.yml`. README : deux lignes dans le tableau des fichiers.
- Résultats : 66 vérifications de `tests/verifier-avant-public.sh`, 318 de `init-script.sh`, 74 de `verifier-noms-exclus.sh`, 52 de `hooks.sh`, tout au vert ; shellcheck sans avertissement.

### Décisions

- Yanis : contrat validé (sans liste ou sans `origin`, sortie 1 ; argument inattendu, sortie 2).
- Agent : l'absence de liste est détectée par l'avertissement du script de base plutôt qu'en dupliquant sa logique de lecture de la liste.

### Corrections et limites

- Une seule correction pendant l'implémentation : la skill disait « Tu ne lances jamais », que le test de CA11 ne reconnaît pas ; reformulée en « Ne lance jamais ».
- Limite : le contrôle d'une référence de PR relit aussi les fichiers suivis de `HEAD` ; si ceux-ci contiennent un nom, toutes les PR sont citées. Le premier contrôle le signale déjà.

### Prochaine étape

- Revues `security-reviewer` et `reviewer`, puis test humain par Yanis.
