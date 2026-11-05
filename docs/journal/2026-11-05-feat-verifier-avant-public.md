# Journal : contrôle avant publication (spec 010, CA9 à CA11)

Branche `feat/verifier-avant-public`.

## 2026-11-05 19:36

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

## 2026-11-05 19:42

### Fait

- Tests écrits par `test-writer` : `tests/verifier-avant-public.sh` (55 vérifications, CA9 à CA11 et cas limites) et bloc « Spec 010 Socle » dans `tests/init-script.sh` (11 vérifications).
- Échec vérifié pour la bonne raison : 54 sur 55 échouent parce que le script et la skill sont absents (la seule qui passe est une précondition indépendante du script) ; seules les 11 vérifications du socle échouent dans `init-script.sh`. shellcheck sans avertissement.

### Décisions

- Contrat proposé par l'agent, à valider par Yanis : sans liste de noms, sans `origin`, le script sort en 1 (dépôt non déclaré publiable).

### Corrections et limites

- Aucune.

### Prochaine étape

- Accord de Yanis sur le contrat, puis implémentation.

## 2026-11-05 19:48

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

## 2026-11-05 20:11

### Fait

- Revues `security-reviewer` et `reviewer` sur `788588d`. Cinq points bloquants au total, tous corrigés, chacun avec un test committé rouge avant la correction (`115c8e8`, `213e9b0`) :
  - le contrôle ne lisait que le clone local, alors que c'est `origin` qui devient public : branches et étiquettes distantes désormais récupérées et relues ; clone superficiel refusé (sortie 2) ;
  - la skill invitait l'agent à créer une liste factice : seul l'humain crée la liste ;
  - chaque PR était relue sur tout son historique (lent, et toutes les PR citées pour un nom sur `main`) : seuls les commits qu'aucune branche n'atteint sont attribués à une PR ;
  - les références de PR, récupérées avant le contrôle 1, y étaient relues et faisaient demander une réécriture de l'historique pour CA10 : elles sont récupérées après ;
  - un nom dans un fichier suivi faisait citer toutes les PR : aucune PR n'est citée tant que les fichiers suivis échouent.
- Points « À corriger » traités : `refs/pull/*/merge` contrôlée ; chemin d'un fichier d'environnement masqué tant que le contrôle des noms échoue ; erreurs de Git lues depuis des fichiers et non plus des substitutions de processus ; « aucune référence de PR » distingué de « vérifiées » ; rubrique « Non vérifié » dans le bilan, relue par `/publier` ; commande de mise en public avec `OWNER/REPO` explicite ; message de `git fetch` masqué (il contient l'URL) avec une piste ; Ctrl-C sort en 2 ; refs orphelines d'un lancement interrompu supprimées au départ ; tests renforcés sur les lignes du bilan plutôt que sur les en-têtes.
- Contrôle par mutation : 12 protections du script désactivées une à une, au moins un test échoue pour chacune. Deux ont d'abord survécu : `--refmap=` (mutation mal appliquée, revérifiée) et la suppression des refs orphelines au départ (test ajouté).
- Spec 010 : ajouts après les revues consignés dans « Cas limites », marqués à valider par Yanis au merge. README : ligne spec 010 complétée.
- Heures des trois entrées précédentes corrigées sur celles des commits (elles avaient été écrites à l'avance).

### Décisions

- Agent, à valider par Yanis au merge : les ajouts de périmètre ci-dessus (spec 010, « Ajouts après les revues »).
- Non suivi, soumis à Yanis : ajouter `Read(./.excluded-names)` et `Bash(gh repo edit *)` aux `deny` de `.claude/settings.json` (revue de sécurité). L'agent ne modifie pas sa propre configuration de permissions sans accord.

### Corrections et limites

- La limite notée à 19:48 (toutes les PR citées si un fichier suivi contient un nom) est levée.
- Limite : la détection de l'absence de liste repose sur le texte de l'avertissement du script de base ; un test la couvre.
- Limite : seuls les fichiers d'environnement nommés exactement ou préfixés comme le prévoit la spec sont détectés ; `.envrc` ne l'est pas.
- Test humain non fait : à faire par Yanis sur ce dépôt, avec le vrai `origin` GitHub.

### Prochaine étape

- Test humain par Yanis, puis PR.

## 2026-11-05 20:14

### Fait

- Essai du script par l'agent sur ce dépôt et son vrai `origin` (40 PR, 2 s), sans liste : le bilan disait « 40 PR vérifiée(s) » alors que rien n'avait été cherché. Test rouge committé, puis correction : sans liste, la ligne des références de PR est « non vérifiées, faute de liste de noms ». 111 vérifications au vert.

### Décisions

- Aucune.

### Corrections et limites

- Cet essai n'est pas le test humain : il a tourné sans liste, donc sans rien chercher.

### Prochaine étape

- Test humain par Yanis, avec sa liste, puis PR.

## 2026-11-05 20:22

### Fait

- Test humain, scénario 1 (Yanis, avec sa liste) : positif sur le fond (183 commits, 40 PR, aucun nom affiché, sortie 0), mais avertissement « aucune locale UTF-8 disponible » sous macOS, qui en fournit pourtant.
- Cause : dans `scripts/verifier-noms-exclus.sh` (PR #58), `locale -a | grep -q` sous `pipefail` échoue toujours : `grep -q` s'arrête à la première correspondance et `locale -a` reçoit SIGPIPE. Reproduit 20 fois sur 20. Le script retombait sur la locale C : un nom accentué écrit dans une autre casse passait. Même piège que celui corrigé dans #58 pour les comparaisons.
- Test rouge committé (`tests/verifier-noms-exclus.sh`, cas limite « Locale » : pas d'avertissement quand une locale UTF-8 existe, et nom accentué trouvé dans une autre casse), puis correction : liste des locales lue une fois dans une variable, hors tuyau. Toutes les suites au vert.

### Décisions

- Agent : correction faite dans cette PR, puisqu'elle relève de la même spec et que le contrôle avant publication en dépend.

### Corrections et limites

- Boucle négative n° 1 du test humain : symptôme, cause et correctif ci-dessus. Le même script existe dans Tidemark : à reporter lors du rétroportage (spec 010, question 2).

### Prochaine étape

- Yanis relance le scénario 1 (avertissement disparu attendu), puis les scénarios 2 et 3.

## 2026-11-05 20:29

### Fait

- Test humain terminé par Yanis : scénario 1 relancé (185 commits, 40 PR, plus d'avertissement de locale, sortie 0), scénario 2 sans liste (sortie 1), scénario 3 `/publier` : « tout est good ».
- Piège capitalisé par `learning-curator` : `docs/learnings/pipefail-grep-q-sigpipe.md`. Règle appliquée aussitôt : recherche des tuyaux terminés par `grep -q` ou `head` dans tous les scripts en `pipefail` du dépôt : aucun autre cas.

### Décisions

- Aucune.

### Corrections et limites

- Test humain positif après 1 boucle négative (locale).

### Prochaine étape

- PR, revue IA et réponse à la revue ; merge par Yanis.

## 2026-11-05 20:35

### Fait

- PR #60 ouverte ; CI au vert (4 jobs) ; revue IA : rien de bloquant, 2 points à corriger, 5 suggestions.
- Corrigé : `/publier` ne consigne plus « dans le journal de la branche en cours » sur `main` (où l'on ne pousse jamais) : elle donne seulement le résultat ; résultat du contrôle 2 mémorisé par SHA (commits partagés entre `head` et `merge`, ou entre PR, relus une seule fois) ; test de contenu « aucun tuyau terminé par `grep -q` ou `head` » dans les deux scripts en `pipefail`, qui protège aussi sous Linux où le test de locale ne voit pas le SIGPIPE (mutation vérifiée sur trois formes de tuyau, après correction d'une regex qui ratait `-qi`) ; README : test du contrôle avant publication dans la ligne de `garde-fous.yml`.
- Constat : les revues IA de #58 et #59 ont échoué en 4 à 6 s le 2026-10-20, avant toute étape ; journaux expirés, cause inconnue. Ces deux PR ont été mergées sans revue IA.

### Décisions

- Agent : non suivi, l'option `--strict` du script de base pour détecter l'absence de liste par un code de sortie : change le contrat d'un script déjà mergé, hors du périmètre de cette PR ; un test couvre la détection actuelle.

### Corrections et limites

- En attente de Yanis : validation explicite des ajouts à la spec 010 (« Ajouts après les revues »), et décision sur les `deny` de `.claude/settings.json`.

### Prochaine étape

- Réponse à la revue IA dans la PR, puis décisions de Yanis.

## 2026-11-05 20:37

### Fait

- Réponse à la revue IA publiée dans la PR #60, et liée depuis sa description.
- Spec 010 : « à valider par Yanis au merge » remplacé par « Yanis, 2026-11-05 » sur les ajouts après les revues.

### Décisions

- Yanis : ajouts à la spec 010 après les revues validés.
- Yanis : `Read(./.excluded-names)` et `Bash(gh repo edit *)` à ajouter aux `deny` de `.claude/settings.json`, dans une PR séparée après #60.

### Corrections et limites

- Aucune.

### Prochaine étape

- Merge de #60 par Yanis, puis PR des `deny`.
