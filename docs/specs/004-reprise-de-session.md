# Spec 004 : reprise de session sans mémoire locale

Statut : brouillon
Date : 2026-10-09

## Besoin

En tant que développeur qui travaille avec l'agent sur plusieurs sessions, je veux pouvoir fermer une session Claude Code et en reprendre une autre plus tard, sur ce poste ou un autre, sans rien perdre, afin que tout le contexte utile soit dans le dépôt et non dans la mémoire locale de l'agent.

Constats d'origine (2026-10-09) :

- Une règle de travail n'existait que dans la mémoire locale de l'agent sur le template. FieldOps, initialisé avec ce template, ne l'appliquait pas.
- Sur FieldOps, l'agent tient une section « Prochaines étapes » dans `docs/journal.md`. Deux PR ouvertes en même temps (#10 et #11) touchent ce fichier ou ses voisins : un seul fichier modifié par toutes les PR produit des conflits, et son contenu devient faux dès qu'une autre PR est mergée.
- Rien ne met le dépôt local à jour au début d'une session : l'agent peut travailler sur une copie en retard de `main`.

## Principes

1. **Le dépôt est la seule mémoire.** Règles de travail : `CLAUDE.md`, skills, subagents. Contexte du projet : documents de référence (spec 003). Feuille de route : la liste des fonctionnalités du cahier des charges, avec leur statut. État d'un travail en cours : le journal de sa branche. Rien n'est gardé seulement dans la mémoire locale de Claude Code.
2. **Un fichier de journal par branche, jamais modifié par une autre PR.** Deux PR n'écrivent jamais dans le même fichier de journal : les conflits sont impossibles par construction, au lieu d'être détectés après coup.
3. **Tout est daté.** Le nom du fichier porte la date de création de la branche, et chaque entrée porte sa date et son heure.
4. **Le début d'une session met à jour le dépôt et l'agent**, sans jamais écraser du travail local.

## Le journal

Le fichier unique `docs/journal.md` est remplacé par un dossier `docs/journal/`.

- Un fichier par branche de travail : `docs/journal/AAAA-MM-JJ-<branche>.md`. La date est celle de la création du fichier, et `<branche>` est le nom de la branche, avec les `/` remplacés par des `-` (exemple : `2026-10-09-feat-documents-de-reference.md`).
- Le fichier est créé au premier commit de la branche, et ne vit que dans cette branche jusqu'au merge.
- Chaque entrée commence par un titre `## AAAA-MM-JJ HH:MM`, à l'heure locale de l'auteur. Les entrées sont dans l'ordre chronologique, et aucune n'est antérieure à la date du nom du fichier.
- Une entrée contient quatre rubriques, chacune pouvant valoir « rien » :
  - **Fait** : ce qui a été produit (commits, PR) ;
  - **Décisions** : ce qui a été tranché, et par qui ;
  - **Corrections et limites** : ce que l'humain a corrigé et pourquoi, ce que l'agent a mal fait, les limites observées. C'est le rôle de l'ancien journal ;
  - **Prochaine étape** : ce qu'une nouvelle session doit faire en premier pour reprendre.
- L'agent ajoute une entrée, ou complète celle du jour, à chaque commit de travail, dans le même commit, puis pousse la branche. Une session fermée sans prévenir ne perd donc que le travail non committé.
- Une fois la branche mergée, son fichier n'est plus jamais modifié. Pour corriger une erreur, une autre branche ajoute une entrée dans son propre fichier.
- L'ancien `docs/journal.md` est déplacé tel quel dans `docs/journal/<date de sa première entrée>-historique.md`.

Il n'y a plus de section « Prochaines étapes » commune. La feuille de route est la liste des fonctionnalités du cahier des charges (spec 003) ; la reprise d'un travail en cours est la dernière entrée du journal de sa branche.

## Début de session : hook `SessionStart`

`.claude/hooks/session-start.sh`, branché dans `.claude/settings.json` sur l'événement `SessionStart`, pour le démarrage (`startup`), la reprise (`resume`) et l'effacement (`clear`) d'une session. Claude Code ne bloque jamais une session sur ce hook ; le script se termine malgré tout avec le code 0, même en cas d'erreur. Ce qu'il affiche est ajouté au contexte de l'agent.

1. **Récupération** : `git fetch` de `origin`, avec un délai maximal de quelques secondes. Un échec (hors ligne, pas de remote) est signalé, et la suite continue sur l'état local.
2. **Mise à jour** : si l'arbre de travail est propre et que la branche courante a une branche distante de suivi, avance rapide seulement (`fast-forward`). Dans tous les autres cas (modifications non committées, branches divergentes, pas de branche de suivi), le hook ne touche à rien et dit pourquoi.
3. **État affiché** :
   - la branche courante, son avance et son retard sur sa branche distante, et son retard sur `origin/main` ;
   - si la branche est en retard sur `main`, une invitation à proposer un rebase, sans le faire ;
   - la dernière entrée du journal de la branche courante ; sur `main`, la dernière entrée du fichier de journal le plus récent ;
   - les PR ouvertes du dépôt, si `gh` est installé et authentifié.

## Mémoire locale de Claude Code

- `CLAUDE.md`, nouvelle règle : ne jamais enregistrer une règle de travail, une décision ou un état dans la mémoire locale de Claude Code. Une règle va dans `CLAUDE.md` ou un skill, par une PR ; un état va dans le journal de la branche.
- La mémoire automatique est désactivée pour le projet : `"autoMemoryEnabled": false` dans `.claude/settings.json` ([documentation de Claude Code](https://code.claude.com/docs/en/memory)). Le réglage est versionné, il s'applique donc à tout poste qui clone le dépôt. Un réglage personnel (`.claude/settings.local.json`) peut encore le contredire : la règle de `CLAUDE.md` reste nécessaire.

## Contrôle en CI : `verifier-journal.sh`

`.github/scripts/verifier-journal.sh <base> <head>`, lancé par un job « Journal » de `garde-fous.yml` sur chaque PR. Il refuse la PR (code 1, message en français qui cite le fichier et la règle) si :

- un fichier de `docs/journal/` présent dans `<base>` est modifié, supprimé ou renommé ;
- un fichier ajouté a un nom hors du format `AAAA-MM-JJ-<slug>.md` (slug en minuscules, chiffres et `-`), ou une date de nom invalide ;
- un titre de niveau 2 d'un fichier ajouté n'a pas le format `## AAAA-MM-JJ HH:MM`, ou porte une date invalide ;
- les entrées d'un fichier ajouté ne sont pas dans l'ordre chronologique, ou l'une d'elles est antérieure à la date du nom du fichier ;
- `docs/journal.md` est recréé ou modifié après la migration.

Une PR qui ne touche pas `docs/journal/` passe. Le job n'exige pas d'entrée de journal dans chaque PR : une PR de l'humain ou de Renovate n'en a pas besoin.

## Application par `init.sh`

Modifie la spec 001 :

- `init.sh` crée `docs/journal/` avec un `.gitkeep`, au lieu de `docs/journal.md`.
- Si la cible a déjà un `docs/journal.md`, il n'est pas modifié, et le script affiche une étape manuelle : le déplacer dans `docs/journal/` avec la commande `git mv` à utiliser.
- `session-start.sh`, `verifier-journal.sh` et leurs tests sont copiés comme les autres garde-fous.

## Critères d'acceptation

### Hook `session-start.sh` (tests sur des dépôts temporaires avec un remote local)

- CA1 : Étant donné une branche propre en retard sur sa branche distante, quand le hook s'exécute, alors la branche est avancée jusqu'à la branche distante, et la sortie le dit.
- CA2 : Étant donné une branche avec des modifications non committées et en retard sur sa branche distante, quand le hook s'exécute, alors aucun fichier ni commit n'est modifié, et la sortie signale le retard et la raison de l'absence de mise à jour.
- CA3 : Étant donné une branche qui a divergé de sa branche distante, quand le hook s'exécute, alors rien n'est modifié, et la sortie signale la divergence.
- CA4 : Étant donné une branche de travail en retard sur `origin/main`, quand le hook s'exécute, alors elle n'est ni rebasée ni fusionnée, et la sortie indique le nombre de commits de retard.
- CA5 : Étant donné un remote injoignable, quand le hook s'exécute, alors il se termine avec le code 0, et la sortie signale l'échec de la récupération.
- CA6 : Étant donné une branche dont le fichier de journal contient plusieurs entrées, quand le hook s'exécute, alors la sortie contient la dernière entrée, et pas les précédentes.
- CA7 : Étant donné un dossier qui n'est pas un dépôt Git, quand le hook s'exécute, alors il se termine avec le code 0, sans erreur affichée.

### Script `verifier-journal.sh` (tests sur des dépôts temporaires)

- CA8 : Étant donné une PR qui ajoute un fichier de journal conforme, quand le script s'exécute, alors il réussit.
- CA9 : Étant donné une PR qui modifie, supprime ou renomme un fichier de journal présent dans la base, quand le script s'exécute, alors il échoue en citant le fichier.
- CA10 : Étant donné un fichier ajouté au nom invalide (format ou date), quand le script s'exécute, alors il échoue en citant le fichier.
- CA11 : Étant donné un fichier ajouté avec un titre d'entrée invalide (format ou date), quand le script s'exécute, alors il échoue en citant le titre.
- CA12 : Étant donné un fichier ajouté dont les entrées ne sont pas chronologiques, ou dont une entrée précède la date du nom, quand le script s'exécute, alors il échoue.
- CA13 : Étant donné une PR qui recrée ou modifie `docs/journal.md`, quand le script s'exécute, alors il échoue.
- CA14 : Étant donné une PR qui ne touche pas `docs/journal/`, quand le script s'exécute, alors il réussit.
- CA15 : Étant donné deux branches créées depuis le même `main`, qui ajoutent chacune leur fichier de journal, quand on fusionne l'une puis l'autre dans `main`, alors aucun conflit ne survient, et le script réussit sur la seconde.

### `init.sh` (ajouts à `tests/init-script.sh`)

- CA16 : Étant donné une cible vide, quand je lance `init.sh`, alors `docs/journal/.gitkeep` existe et `docs/journal.md` n'existe pas.
- CA17 : Étant donné une cible avec un `docs/journal.md`, quand je lance `init.sh`, avec ou sans `--force`, alors ce fichier n'est pas modifié, et la sortie propose la commande `git mv` de migration.

### Relecture humaine (consignes, non testables automatiquement)

- CA18 : `CLAUDE.md` interdit la mémoire locale et impose une entrée de journal à chaque commit de travail ; `/implement` la rappelle.
- CA19 : `.claude/settings.json` branche `session-start.sh` sur `SessionStart` (`startup`, `resume`, `clear`) et contient `"autoMemoryEnabled": false`. La CI du template vérifie ces deux points par `jq`.

## Cas limites et erreurs

- `HEAD` détaché : pas de mise à jour, état affiché.
- Pas de remote `origin` : récupération sautée, signalée.
- `gh` absent ou non authentifié : la liste des PR est omise, avec une ligne qui le dit.
- Plusieurs fichiers de journal pour une même branche (renommage de branche) : le hook affiche le plus récent par son nom.
- Branche sans fichier de journal : le hook le dit et rappelle de le créer au premier commit.

## Hors périmètre

- Détection des conflits sur les autres fichiers partagés (cahier des charges, architecture technique, code) : GitHub les signale déjà, et le ruleset peut exiger une branche à jour avant le merge.
- Rebase ou fusion automatique de `main` dans la branche de travail.
- Résumé automatique de la conversation à la fermeture : le hook `SessionEnd` s'exécute après la fin de la session, sans tour de parole pour l'agent, avec un délai de 1,5 seconde par défaut. D'où l'entrée de journal à chaque commit. Un hook `Stop` (à chaque fin de tour) pourrait rappeler une entrée manquante, mais il interviendrait à chaque réponse : écarté pour l'instant.
- Sauvegarde de la conversation elle-même : `claude --resume` existe, mais il reste local au poste.

## Questions ouvertes

- Heure locale ou UTC pour les titres d'entrée ? Proposition : heure locale, plus lisible ; l'ordre n'est vérifié qu'à l'intérieur d'un fichier, qui n'a qu'un auteur à la fois.
- Faut-il exiger une entrée de journal dans toute PR ouverte par l'agent ? Proposition : non en CI (impossible de distinguer l'auteur de façon fiable), oui dans `CLAUDE.md`, et le reviewer le vérifie.
