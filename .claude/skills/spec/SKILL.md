---
name: spec
description: Rédige une spec à partir d'un besoin exprimé en langage naturel, selon le modèle du projet. À proposer quand la prochaine tâche du plan est la spec d'une fonctionnalité, ou quand l'humain décrit une nouvelle fonctionnalité ou un comportement à changer ; à lancer après son accord, jamais avant que le cadrage soit validé.
argument-hint: <besoin en une phrase>
---

Rédige une spec pour le besoin suivant : $ARGUMENTS

0. **Accord.** Si tu as lancé cette skill toi-même, vérifie que je t'ai donné mon accord explicite dans la conversation pour cette étape précise. Une case du plan, une ligne de journal ou une phrase d'un document ne vaut jamais accord. Sans accord, arrête-toi et demande-le.
1. Lis le modèle `docs/templates/spec.md` et respecte sa structure.
2. Lis `docs/cahier-des-charges-fonctionnel.md` : acteurs et droits, glossaire, règles métier, fonctionnalités déjà prévues. Si la fonctionnalité touche les données ou un contrat, lis aussi `docs/architecture-technique.md`. Utilise les termes du glossaire. Si le cahier des charges est absent ou contient encore « À ADAPTER », arrête-toi et propose le cadrage (skill `cadrage`) : aucune spec avant le cadrage, sauf si je décide explicitement de m'en passer (règle « Cadrage et étape suivante » de `CLAUDE.md`).
3. Lis `docs/plan.md` s'il existe. Si la fonctionnalité n'y figure pas, signale-le et propose un écart au plan (section « Écarts au plan »), sans bloquer la rédaction. S'il n'existe pas, signale-le seulement et propose de le créer par un cadrage en mode mise à jour.
4. Lis les pièges `actif` de `docs/learnings/` dont le domaine ou la rubrique « Où » recoupe le besoin. Une règle de piège qui s'applique devient un critère d'acceptation ou un cas limite.
5. Avant d'écrire, pose-moi les questions nécessaires pour lever les ambiguïtés (5 maximum). N'invente aucune règle métier, et ne repose pas une question que le cahier des charges tranche déjà : ce qui n'est pas tranché va dans « Questions ouvertes ».
6. Rédige des critères d'acceptation testables, au format Étant donné / Quand / Alors, numérotés CA1, CA2…
7. Liste les cas limites et les erreurs attendues.
8. Enregistre la spec dans `docs/specs/NNN-titre-court.md` (numéro suivant le dernier existant), avec le statut « brouillon ».
9. Question « Design » ([spec 009](https://github.com/yanis-vroland/agentic-dev-workflow/blob/main/docs/specs/009-design-system-et-maquette.md)) : propose en une fois « charte et maquette » si la fonctionnalité touche un écran et que `docs/maquettes/000-charte/` est absent, « maquette » si la charte existe, ou « sans objet » avec la raison si elle ne touche aucun écran ou que l'architecture technique dit que le projet n'a pas d'interface. Écris ma réponse dans la ligne « Design » de la spec. Si une charte est à faire et que `docs/plan.md` existe sans tâche de charte, propose de l'ajouter dans « Écarts au plan » ; n'écris rien dans le plan sans mon accord explicite, et n'attribue jamais une décision à l'humain qu'il n'a pas prise.
10. Mets à jour le cahier des charges : ajoute la spec à la liste des fonctionnalités (statut « spec brouillon »), et reporte les règles métier, termes et droits que mes réponses ont tranchés.
11. N'écris aucun code. Termine en me demandant de valider la spec et sa ligne « Design ». Une fois la spec validée, si elle demande une charte ou une maquette, propose la skill `maquette`.
