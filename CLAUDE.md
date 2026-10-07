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

1. Toute fonctionnalité (feat) exige une spec validée dans `docs/specs/`. Sans spec, proposer d'en rédiger une et attendre la validation. Les changements chore, ci et docs s'appuient sur la description de la PR.
2. Test-first : écrire les tests à partir des critères d'acceptation, vérifier qu'ils échouent, puis implémenter jusqu'au vert.
3. Ne jamais modifier ou supprimer un test pour le faire passer sans le signaler explicitement.
4. Face à un choix d'architecture structurant, s'arrêter et proposer un ADR dans `docs/adr/` au lieu de trancher seul.

## Définition du « done »

- Chaque critère d'acceptation de la spec est couvert par au moins un test.
- Lint, format et tests au vert.
- Aucun TODO sans ticket associé.
- Documentation mise à jour si un comportement public change.

## Interdits

- Lire, créer ou modifier un fichier `.env*`, sauf `.env.example`.
- Committer un secret, une clé ou un token.
- Ajouter une dépendance sans la justifier dans la PR.
- Pousser directement sur `main`.

## Architecture

À ADAPTER : modules, conventions de nommage, où va quoi.
