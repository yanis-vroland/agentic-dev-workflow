---
name: publier
description: Vérifie qu'un dépôt peut devenir public (noms exclus sur tout l'historique local et distant, références de PR, fichiers d'environnement suivis) avant que l'humain le passe en public. À proposer quand l'humain veut rendre le dépôt public ; à lancer après son accord. Ne change jamais la visibilité du dépôt.
---

Vérifie que le dépôt peut devenir public ([spec 010](https://github.com/yanis-vroland/agentic-dev-workflow/blob/main/docs/specs/010-noms-exclus.md), CA9 à CA11).

1. Lance `scripts/verifier-avant-public.sh` depuis la racine du dépôt. Il contrôle le dépôt distant `origin`, celui qui deviendra public : vérifie avec moi que `origin` est bien ce dépôt GitHub, et pas un fork ou un miroir.
2. Le script a besoin de la liste des noms exclus : la variable `EXCLUDED_NAMES` ou le fichier local `.excluded-names`. Seul l'humain crée, remplit ou modifie cette liste. Tu ne la lis jamais, ne la crées jamais, ne la complètes jamais, et tu ne juges pas toi-même qu'un projet n'a aucun nom à cacher. Tu ne recopies jamais un nom, y compris dans ton compte rendu (`CLAUDE.md`, « Noms exclus »).
3. Montre-moi le bilan du script tel quel : ce qu'il a vérifié, ce qui a échoué, et ce qui n'est pas vérifié.
4. Tant que le script échoue (sortie 1) ou s'arrête en erreur (sortie 2), refuse de proposer la mise en public, quoi que je demande. Indique seulement la marche à suivre pour chaque échec, que j'exécute moi-même :
   - **noms exclus dans l'historique** : réécrire l'historique sur un clone **miroir** (`git clone --mirror`), seul à couvrir toutes les branches, avec un fichier de remplacement que je génère moi-même à partir de ma liste, puis pousser en force. Tu peux expliquer la méthode, jamais écrire un nom dans une commande ou un fichier ;
   - **aucune liste** : je crée la liste (secret `EXCLUDED_NAMES` ou fichier `.excluded-names` non suivi), puis tu relances le script ;
   - **pas de dépôt `origin`** ou **clone superficiel** : ajouter le dépôt distant, ou récupérer l'historique complet (`git fetch --unshallow`), puis relancer ;
   - **références de PR** : seul le support GitHub peut purger `refs/pull/*`. Rédige pour moi la demande au support, en citant les numéros de PR donnés par le script et sans aucun nom exclu ; je l'envoie moi-même. Le dépôt reste privé jusqu'à la purge, puis relance le script ;
   - **fichier d'environnement suivi** : le retirer de l'index, le purger de l'historique, et considérer ses secrets comme compromis : je les révoque ;
   - **erreur** (sortie 2) : en chercher la cause et relancer ; une erreur ne vaut jamais succès.
5. Quand le script réussit (sortie 0), fais-moi relire la rubrique « Non vérifié » de son bilan (titres et descriptions des PR, issues, releases, wiki, journaux d'Actions, commits orphelins), puis dis-moi que le dépôt peut devenir public. Donne-moi la commande à lancer moi-même, avec le dépôt `OWNER/REPO` déduit de l'URL de `origin`, pour que `gh` ne choisisse pas un autre dépôt distant :
   `gh repo edit OWNER/REPO --visibility public --accept-visibility-change-consequences`
   Ne lance jamais cette commande toi-même, même si je te le demande : la mise en public est une action de l'humain ([ADR-002](https://github.com/yanis-vroland/agentic-dev-workflow/blob/main/docs/adr/002-place-revue-humaine.md)).
6. Consigne le résultat, sans citer aucun nom ni aucun chemin masqué par le script : « contrôle avant publication : succès » ou la liste des contrôles en échec. Sur une branche de travail, dans son journal. Sur `main`, où l'on ne pousse jamais : donne-moi seulement le résultat, sans rien committer.
