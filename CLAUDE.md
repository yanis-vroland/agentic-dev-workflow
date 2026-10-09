# CLAUDE.md

Contexte projet pour l'agent de code. Les sections marquées « À ADAPTER » sont propres à chaque projet.

## Projet

À ADAPTER : une phrase sur ce que fait le projet et pour qui.

## Stack et commandes

À ADAPTER :
- Installer : `pnpm install`
- Lancer : `docker compose up`
- Tests : `pnpm test`
- Lint : `pnpm lint`

## Langue

- Code en anglais : variables, fonctions, classes, entités, tables, routes d'API.
- Tout le reste en français : README, ADR, specs, commentaires, messages de commit, PR.
- Commits au format Conventional Commits, préfixe en anglais, message en français :
  `feat: ajout du CRUD des machines`

## Méthode de travail

1. Toute modification du comportement observable exige une spec validée dans `docs/specs/` :
   - nouvelle fonctionnalité (feat) : nouvelle spec ;
   - correction (fix) : référence à la spec concernée et test de non-régression qui échoue avant la correction ; si le bug révèle un cas non prévu, compléter d'abord la spec ;
   - sans changement de comportement (refactor, perf, test, chore, ci, docs) : la description de la PR suffit. Si le changement modifie un comportement malgré son préfixe, il relève des cas précédents.

   Pour les deux premiers cas, sans spec, proposer d'en rédiger une et attendre la validation.
2. Test-first ([ADR-003](https://github.com/yanis-vroland/agentic-dev-workflow/blob/main/docs/adr/003-strategie-test-first.md)) :
   - écrire les tests à partir des critères d'acceptation (subagent `test-writer`), vérifier qu'ils échouent pour la bonne raison, et les committer avant l'implémentation, dans un commit séparé ;
   - relire les tests avant d'implémenter, et renforcer toute vérification qui passerait sans implémentation ;
   - implémenter jusqu'au vert ;
   - sur les garde-fous (hooks, scripts de sécurité, vérifications de CI), contrôle par mutation : désactiver chaque protection une fois et vérifier qu'au moins un test échoue.
3. Ne jamais modifier ou supprimer un test pour le faire passer sans le signaler explicitement.
4. Face à un choix d'architecture structurant, s'arrêter et proposer un ADR dans `docs/adr/` au lieu de trancher seul. L'agent peut rédiger l'ADR en entier, au statut « proposé » ; il ne passe à « accepté » et n'est mergé qu'après validation humaine ([ADR-002](https://github.com/yanis-vroland/agentic-dev-workflow/blob/main/docs/adr/002-place-revue-humaine.md)).
5. Après la revue IA d'une PR, et une fois les corrections poussées, publier un commentaire `## Réponse à la revue IA` dans la PR. Chaque point du rapport y reçoit une suite : corrigé (avec le SHA du commit), non suivi et pourquoi, ou reporté (avec l'issue). La description de la PR renvoie vers ce commentaire sans le répéter. Ne pas se contenter de modifier la description : cela ne laisse aucune trace dans la chronologie et ne notifie personne.

## Reprise de session

Le dépôt est la seule mémoire : une session doit pouvoir être fermée à tout moment et reprise plus tard, sur n'importe quel poste, sans perte ([spec 004](https://github.com/yanis-vroland/agentic-dev-workflow/blob/main/docs/specs/004-reprise-de-session.md)).

- Ne jamais enregistrer une règle, une décision ou un état dans la mémoire locale de Claude Code (désactivée par `autoMemoryEnabled` dans `.claude/settings.json`). Une règle de travail va dans `CLAUDE.md`, un skill ou un subagent, par une PR ; un état va dans le journal de la branche.
- Journal : un fichier par branche, `docs/journal/AAAA-MM-JJ-<branche>.md` (`/` remplacés par `-`, date de création), créé au premier commit de la branche. Chaque entrée commence par `## AAAA-MM-JJ HH:MM` (heure locale) et contient quatre rubriques : **Fait**, **Décisions** (et qui a décidé), **Corrections et limites**, **Prochaine étape**.
- À chaque commit de travail : ajouter une entrée ou compléter celle du jour dans le même commit, puis pousser la branche.
- Ne jamais modifier le fichier de journal d'une autre branche, ni un fichier déjà mergé : la CI le refuse (`verifier-journal.sh`).
- Au début d'une session, le hook `session-start.sh` met la branche à jour si c'est sans risque, et affiche son état et la dernière entrée de journal. Repartir de la « Prochaine étape » de cette entrée. Si la branche est en retard sur `main`, proposer un rebase sans le faire.

## Définition du « done »

- Chaque critère d'acceptation de la spec est couvert par au moins un test.
- Lint, format et tests au vert.
- Aucun TODO sans ticket associé.
- Entrée de journal de la branche à jour et poussée.
- Documentation mise à jour si un comportement public change.

## Interdits

- Lire, créer ou modifier un fichier `.env*`, sauf `.env.example`.
- Committer un secret, une clé ou un token.
- Ajouter une dépendance sans la justifier dans la PR.
- Pousser directement sur `main`.
- Merger une PR : seul l'humain merge ([ADR-002](https://github.com/yanis-vroland/agentic-dev-workflow/blob/main/docs/adr/002-place-revue-humaine.md)).

## Documents de référence

Une information vit à un seul endroit ; les autres documents y renvoient.

- `docs/cahier-des-charges-fonctionnel.md` : le quoi. Acteurs et droits, glossaire, règles métier, parcours, fonctionnalités par phase avec un lien vers leur spec, questions métier ouvertes.
- `docs/architecture-technique.md` : le comment. Modèle de données, contrats entre composants, conventions d'API, sécurité, infrastructure, index des ADR.
- `docs/specs/` détaille une fonctionnalité ; `docs/adr/` explique un choix.

Lire le cahier des charges avant d'écrire une spec, et l'architecture technique avant de toucher aux données, à un contrat, à la sécurité ou à l'infrastructure. Les noms du code sont ceux du glossaire.

Mettre à jour dans la même PR :
- le cahier des charges : nouvelle fonctionnalité, changement d'acteur, de droit, de terme ou de règle métier, changement de statut d'une spec ;
- l'architecture technique : changement du modèle de données, d'un contrat, de la sécurité ou de l'infrastructure, ADR accepté.

Une règle métier non tranchée va dans les questions ouvertes du cahier des charges : ne jamais l'inventer.

## Architecture

À ADAPTER : modules, conventions de nommage, où va quoi.
