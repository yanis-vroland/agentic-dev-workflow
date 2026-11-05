---
name: publier
description: Vérifie qu'un dépôt peut devenir public (noms exclus sur tout l'historique, références de PR, fichiers d'environnement suivis) avant que l'humain le passe en public. À proposer quand l'humain veut rendre le dépôt public ; à lancer après son accord. Ne change jamais la visibilité du dépôt.
---

Vérifie que le dépôt peut devenir public ([spec 010](https://github.com/yanis-vroland/agentic-dev-workflow/blob/main/docs/specs/010-noms-exclus.md), CA9 à CA11).

1. Lance `scripts/verifier-avant-public.sh` depuis la racine du dépôt, à jour avec `origin`. Il a besoin de la liste des noms exclus : la variable `EXCLUDED_NAMES` ou le fichier local `.excluded-names`. Ne lis jamais ce fichier, et ne recopie jamais un nom, y compris dans ton compte rendu (`CLAUDE.md`, « Noms exclus »).
2. Montre-moi le bilan du script tel quel : ce qu'il a vérifié, et ce qui a échoué.
3. Tant que le script échoue (sortie 1) ou s'arrête en erreur (sortie 2), refuse de proposer la mise en public, quoi que je demande. Propose seulement la marche à suivre pour chaque échec :
   - **noms exclus dans l'historique** : réécrire l'historique sur un clone **miroir** (`git clone --mirror`), seul à couvrir toutes les branches, puis pousser en force. C'est une action de l'humain, que tu peux préparer sans la lancer ;
   - **aucune liste** : créer la liste (secret `EXCLUDED_NAMES` ou fichier `.excluded-names` non suivi) ; pour un projet sans nom à cacher, un nom inventé suffit ;
   - **références de PR** : seul le support GitHub peut purger `refs/pull/*`. Rédige pour moi la demande au support, en citant les numéros de PR donnés par le script et sans aucun nom exclu ; je l'envoie moi-même. Le dépôt reste privé jusqu'à la purge, puis relance le script ;
   - **fichier d'environnement suivi** : le retirer de l'index, le purger de l'historique, et considérer ses secrets comme compromis : je les révoque ;
   - **erreur** (sortie 2) : en chercher la cause et relancer ; une erreur ne vaut jamais succès.
4. Quand le script réussit (sortie 0), dis-moi que le dépôt peut devenir public, et donne-moi la commande à lancer moi-même :
   `gh repo edit --visibility public --accept-visibility-change-consequences`
   Ne lance jamais cette commande toi-même, même si je te le demande : la mise en public est une action de l'humain ([ADR-002](https://github.com/yanis-vroland/agentic-dev-workflow/blob/main/docs/adr/002-place-revue-humaine.md)).
5. Consigne le résultat dans le journal de la branche, sans citer aucun nom : « contrôle avant publication : succès » ou la liste des contrôles en échec.
