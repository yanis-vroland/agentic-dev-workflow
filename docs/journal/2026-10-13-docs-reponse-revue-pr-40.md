# Journal : docs/reponse-revue-pr-40

Branche `docs/reponse-revue-pr-40`. Suite de la revue IA de la PR #40, mergée avant que la revue soit traitée.

## 2026-10-13 15:14

### Fait

- README, « Comment ce projet a été construit » : période et plage mises à jour (7 au 13 octobre, 30 PR, #1 à #40), cohérentes avec la ligne #39 ajoutée par #40.
- ADR-005 : titre de section ramené à « Décision » ; attribution placée dans le statut (revue en 15:20).
- Décisions de la spec 007 recopiées ci-dessous, pour qu'elles vivent sur `main` et pas seulement dans le commit `e5dcdc1`, hors de `main`.

### Décisions

- Reportées de l'entrée de 15:00 du journal de `docs/spec-007-modele-par-agent` (commit `e5dcdc1`, jamais mergé) :
  - Yanis (« tout est good ») : ADR-005 accepté, option alias.
  - Yanis : les scénarios joués par l'agent sont acceptés comme test humain de la spec 007 : CA18 (`/review` en `opus` depuis une session `sonnet`), message d'erreur de `verifier-modeles.sh`, CA15 bis (modèle inexistant, aucun substitut choisi par l'agent). Exception à la spec 005, qui demande un test par l'humain.
  - Test humain positif sans boucle négative : pas de capitalisation par `learning-curator`.
- Yanis : rattrapage de la revue de #40 par cette PR plutôt que par une issue.

### Corrections et limites

- Ordre réel des événements de #39, reconstitué avec GitHub et Git : PR annoncée prête, « tout est good » de Yanis, merge à 14:26, commit `e5dcdc1` à 14:28, puis push. L'agent a ajouté un commit à une PR déjà annoncée prête sans prévenir qu'il fallait l'attendre : c'est la première moitié de la règle 6 (« pousser tous les commits avant d'annoncer qu'une PR est prête ») qui n'a pas été tenue. La vérification après merge a détecté l'écart, après coup. L'entrée de journal de `e5dcdc1` était datée 15:00, l'heure était fausse.
- Même schéma sur #40 : merge avant la réponse à la revue IA (règle 5). La réponse est publiée en commentaire de #40 après coup.
- Pas de piège dans `docs/learnings/` : c'est une règle de travail de la chaîne, déjà écrite dans `CLAUDE.md`, pas un piège du code découvert au test humain.
- CA11 bis de la spec 007 (échec réel de la revue IA faute de modèle) reste à vérifier par l'humain.

### Prochaine étape

- Réponse à la revue IA de cette PR, puis merge par Yanis, puis vérification que le dernier commit est sur `main`.

## 2026-10-13 15:20

### Fait

- Réponse à la revue IA de #41 :
  - heure de l'entrée précédente corrigée (15:14, heure du commit `4dec470`, et non 15:30) ;
  - ADR-005 : statut ramené à « accepté », sans nom ni date, comme les ADR-001 à 003. L'attribution reste dans la section « Décision » (option alias) et la conduite face à un modèle indisponible ;
  - README : lignes spec 006 (#37, #38) et ADR-004 proposé (#36) ajoutées à « Specs et décisions » ; « Écarts au processus » datés du 2026-10-13, avec le test humain délégué de la spec 007 et les deux merges avant clôture (#39, #40).

### Décisions

- Agent : aligner l'ADR-005 sur le format des ADR-001 à 003 plutôt que d'ajouter le nom et la date aux quatre ADR, pour ne pas toucher à des ADR acceptés hors du sujet de cette PR.

### Corrections et limites

- Le job « Revue IA de la PR » de `4dec470` a échoué sur `verifier-revue-ia.sh` (« 1 action refusée pendant la revue »), alors que le rapport a bien été publié. Le rapport a été traité tel quel ; l'action refusée n'est pas identifiée.

### Prochaine étape

- Revue IA de ce commit, réponse à la revue, annonce de la PR prête, puis merge par Yanis.
