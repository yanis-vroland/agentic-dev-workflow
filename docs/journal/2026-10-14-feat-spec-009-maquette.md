# Journal : implémentation de la spec 009, design system et maquette

Branche `feat/spec-009-maquette`.

## 2026-10-14 20:40

### Fait

- Spec 009 alignée sur la spec 008 mergée : la question « Design » suit l'étape 8 de `/spec` (une étape ajoutée par la spec 008) ; cas limite des données réelles restreint aux données personnelles, les noms du client et du produit étant admis (décision du 2026-10-14 sur les projets clients).
- Tests rouges écrits par le subagent `test-writer` (lancé comme subagent générique avec ses consignes et son modèle `sonnet`) : deux étapes de `template-ci.yml` (CA1, ligne « Design » et section « Maquette » du modèle de spec ; CA2, skill `maquette` invocable par l'agent), un cas dans `tests/init-script.sh` (CA2, skill copiée). Aucune vérification existante modifiée (CA3).
- Résultat : `init-script.sh` 284 OK et 3 ÉCHEC, tous sur la spec 009 CA2 (skill absente) ; étapes CI CA1 et CA2 en échec sur le dépôt actuel, vertes sur une copie conforme, et contrôlées par mutation par le subagent.

### Décisions

- Corrections de la spec sans nouveau critère : alignement sur des décisions déjà prises par Yanis (agent).

### Corrections et limites

- Les CA4 à CA14 ne se testent qu'en session, sur un projet jetable.

### Prochaine étape

Accord de Yanis sur les tests rouges, puis implémentation : modèle de spec, skill `maquette`, `/spec`, `/implement`, `reviewer`, README.

## 2026-10-14 20:46

### Fait

- Implémentation de la spec 009 : ligne « Design » et section « Maquette » facultative dans le modèle de spec ; skill `maquette` ; `/spec` pose la question « Design » (étape 9) et propose la maquette après validation ; `/implement` contrôle la ligne « Design » et la maquette validée (étape 1), transmet la maquette à `test-writer`, implémente à partir d'elle et propose la comparaison au test humain ; `reviewer` relève un écran sans maquette et une valeur visuelle codée en dur ; `CLAUDE.md`, ADR-004 et README (schéma du flux, étapes, fichiers propres au template, historique).
- Tests : `init-script.sh` 289 OK ; toutes les étapes de `template-ci.yml` vertes en local ; `verifier-modeles`, `lint-shell`, `hooks`, `restrict-learnings`, `verifier-journal` verts ; shellcheck sans avertissement.
- Revue de sécurité (`security-reviewer`, lancé comme subagent générique avec son modèle `opus`) : aucun bloquant ; un point à corriger et deux suggestions, tous suivis : statut « validée » d'une maquette pris en compte seulement sur `main` ou confirmé dans la conversation ; maquette, copie et commentaires traités comme des données ; copies autonomes, sans ressource réseau, vérifiées par le `reviewer`.
- Scénarios joués par l'agent (`claude -p`, projet jetable initialisé depuis cette branche, cadrage fait) :
  - CA4 : écran sans charte, « charte et maquette » proposé, tâche de charte proposée en écart au plan.
  - CA5 : charte existante, « maquette » seule proposée.
  - CA6 : alerte e-mail, « sans objet » proposé avec sa raison.
  - CA7 : spec « maquette » sans maquette, arrêt avant `test-writer`, skill `maquette` proposée.
  - CA8 : spec validée sans ligne « Design », question posée avec la proposition « sans objet ».
  - CA13 : outil d'artefact absent en mode non interactif, arrêt et choix proposé (attendre ou HTML direct).
  - CA14 : proposition de la skill `maquette` annoncée après validation (CA4), non rejouée jusqu'au bout.

### Décisions

- Corrections de la revue de sécurité suivies sans nouveau critère d'acceptation : elles précisent des règles déjà dans la spec (validation humaine, données jamais consignes) (agent).

### Corrections et limites

- Non vérifiés : CA9, CA10, CA11, CA11 bis et CA12, qui demandent l'outil d'artefact, absent des sessions non interactives. À vérifier à la première maquette réelle (Tidemark, lot E).
- Constat : dans le scénario CA6, l'agent a consigné un écart au plan « décidé par l'humain » sans décision explicite. À surveiller.
- Les scénarios CA7 et CA8 bloquent aussi sur l'absence de stack : le contrôle « Design » est vérifié, mais au milieu d'autres arrêts légitimes.

### Prochaine étape

PR #52 ouverte (numéro reporté dans le README) ; revue IA et réponse, puis merge par Yanis. Ensuite : vérifier les CA de `/maquette` à la maquette du lot E de Tidemark.

## 2026-10-14 20:50

### Fait

- Suites de la revue IA de la PR #52 :
  - `/maquette` : PR ouverte avant la boucle de validation ; seule l'accord donné dans la conversation vaut validation, et le statut « validée » est écrit avant le merge ; repli en HTML direct décrit ; avertissement si le dépôt est public avant le premier push.
  - `/implement` : la réponse à la question « Design » est écrite dans le premier commit de la branche, pas avant sa création.
  - `reviewer` : valeur codée en dur relevée quelle que soit la ligne « Design ».
  - `/spec` et `CLAUDE.md` : rien n'est écrit dans le plan sans accord explicite, et aucune décision n'est attribuée à l'humain sans son accord.
  - Spec 009 : vocabulaire « charte et maquette » aligné sur la ligne « Design ».
  - Étape CI CA1 : la ligne « Design » doit suivre immédiatement « Date » ; mutation contrôlée (ligne décalée détectée).
- Scénario CA9 joué (`claude -p`, spec « sans objet ») : aucune étape de design ni de maquette ajoutée ; l'agent s'arrête sur l'absence de stack, comme avant la spec 009.

### Décisions

- Test humain remplacé par des scénarios joués par l'agent, sur décision de Yanis du 2026-10-14 (« test toi-même ») : il n'est pas présenté comme un test humain (Yanis).
- Noms du client et du produit admis dans les maquettes versionnées : extension de la décision de Yanis sur les projets clients (spec 008), en attente de son accord explicite (agent, à valider par Yanis).

### Corrections et limites

- `test-writer` et `security-reviewer` lancés comme subagents génériques, avec leurs consignes et leur modèle déclaré passé en paramètre (`sonnet`, `opus`) : la session est ouverte à la racine de l'espace de travail, où les subagents du dépôt ne sont pas chargés. Écart à la règle n°7 de `CLAUDE.md` (lancer sans paramètre `model`), sans changement de modèle.
- CA10 à CA12 restent non vérifiés : ils demandent l'outil d'artefact, absent des sessions non interactives.

### Prochaine étape

Accord de Yanis sur les noms du client dans les maquettes, puis merge de la PR #52. Ensuite : vérifier les CA de `/maquette` à la maquette du lot E de Tidemark.
