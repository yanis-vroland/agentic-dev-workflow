# Spec 003 : documents de référence du projet

Statut : brouillon
Date : 2026-10-09

## Besoin

En tant que développeur qui construit un projet avec l'agent, je veux deux documents de référence à la racine de `docs/`, l'un fonctionnel et l'autre technique, que la chaîne tient à jour à chaque spec et à chaque PR. Ainsi, une règle métier, un acteur, une entité ou un contrat est décrit à un seul endroit, à jour, que l'humain comme l'agent lisent avant d'écrire une spec ou du code.

Constat d'origine : sur FieldOps, premier projet initialisé avec le template, les specs se multiplient. Le glossaire, les règles métier et l'architecture étaient dispersés entre la vision, les specs et `CLAUDE.md`, sans document qui les rassemble.

## Les deux documents

| Document | Question | Contenu |
| --- | --- | --- |
| `docs/cahier-des-charges-fonctionnel.md` | Quoi | objectif et périmètre, acteurs et droits, glossaire (terme et nom dans le code), règles métier (statuts, transitions), parcours utilisateur, fonctionnalités par phase avec un lien vers leur spec, questions métier ouvertes |
| `docs/architecture-technique.md` | Comment | vue d'ensemble, modèle de données, contrats entre composants, conventions d'API, sécurité (identification, droits, audit, secrets), infrastructure (environnements, CI), index des ADR |

Rôle de chacun, par rapport aux documents existants :

- une **spec** détaille une fonctionnalité ; le cahier des charges résume et renvoie vers elle ;
- un **ADR** explique pourquoi un choix a été fait ; l'architecture technique décrit l'état qui en résulte et renvoie vers lui ;
- un **contrat** (fichier OpenAPI, schéma MCP) fait foi ; l'architecture technique dit qui le produit, qui le consomme, et où il se trouve.

Une information vit à un seul endroit ; les autres documents y renvoient.

## Contenu

### Modèles

`docs/templates/cahier-des-charges-fonctionnel.md` et `docs/templates/architecture-technique.md` contiennent la structure des deux documents. Chaque section explique ce qu'elle contient, et les parties propres au projet sont marquées « À ADAPTER ». Ils sont copiés par `init.sh` avec le reste de `docs/templates/` (spec 001, CA1).

### Création par `init.sh`

Complète la section « Créés s'ils sont absents » de la spec 001 : `init.sh` crée `docs/cahier-des-charges-fonctionnel.md` et `docs/architecture-technique.md` à partir des modèles, s'ils sont absents. Comme le journal, ils appartiennent au projet : `init.sh` ne les modifie jamais s'ils existent, même avec `--force`.

### Règles de l'agent

- `CLAUDE.md`, nouvelle section « Documents de référence » : rôle de chaque document, et obligation de mise à jour dans la même PR :
  - cahier des charges : nouvelle fonctionnalité, changement d'acteur, de droit, de terme ou de règle métier, changement de statut d'une spec ;
  - architecture technique : changement du modèle de données, d'un contrat, de la sécurité ou de l'infrastructure, ADR accepté.
- `CLAUDE.md`, définition du « done » : les deux documents sont à jour.
- `/spec` lit le cahier des charges avant de poser ses questions, utilise les termes du glossaire, et ajoute la spec à la liste des fonctionnalités.
- `/implement` met à jour les deux documents avant le récapitulatif, et les cite dans celui-ci.
- Le subagent `reviewer`, utilisé aussi par la revue IA, vérifie que les documents concernés sont mis à jour par la PR, et qu'elle ne contredit pas le glossaire ni les règles métier.
- Le modèle de PR contient une section « Documents de référence ».

## Critères d'acceptation

Vérifiés par `tests/init-script.sh` :

- CA1 : Étant donné une cible sans `docs/cahier-des-charges-fonctionnel.md` ni `docs/architecture-technique.md`, quand je lance `scripts/init.sh`, alors les deux fichiers sont créés, chacun identique à son modèle de `docs/templates/`.
- CA2 : Étant donné une cible où les deux documents existent avec un contenu propre au projet, quand je lance le script sans `--force`, alors ils ne sont pas modifiés.
- CA3 : Étant donné la même cible, quand je lance le script avec `--force`, alors ils ne sont pas modifiés non plus.
- CA4 : Étant donné une cible où un seul des deux documents existe, quand je lance le script, alors le document existant n'est pas modifié et l'autre est créé à partir de son modèle.
- CA5 : Étant donné une initialisation réussie, quand le script se termine, alors sa sortie mentionne la création de chacun des deux documents, et les étapes manuelles invitent à les compléter.

Vérifiés par la relecture humaine (texte des consignes, non testable automatiquement) :

- CA6 : `CLAUDE.md` contient la section « Documents de référence » décrite plus haut, et sa définition du « done » cite les deux documents.
- CA7 : le skill `/spec` impose la lecture du cahier des charges avant les questions et l'ajout de la spec à la liste des fonctionnalités.
- CA8 : le skill `/implement` impose la mise à jour des deux documents avant le récapitulatif.
- CA9 : le subagent `reviewer` classe « À corriger » une PR qui change une règle métier, un acteur, une fonctionnalité, le modèle de données, un contrat, la sécurité ou l'infrastructure sans mettre à jour le document concerné.
- CA10 : `.github/pull_request_template.md` contient une section « Documents de référence ».

## Cas limites et erreurs

- Modèle absent du template (supprimé du disque mais suivi par Git) : refus avant toute copie, comme pour tout fichier de `docs/templates/` (spec 001, section « Cas limites et erreurs »).
- Relance sur une cible déjà initialisée : les documents ne sont pas modifiés (CA2), et l'idempotence de la spec 001 (CA15) reste vraie.
- Projet sans fonctionnalité métier (outil, bibliothèque) : les sections sans objet restent, avec la mention « Sans objet » et une phrase d'explication, plutôt que d'être supprimées.

## Hors périmètre

- Vérification automatique en CI de la cohérence entre le code et les deux documents. La revue (IA et humaine) en est chargée.
- Application de ces documents au dépôt du template lui-même. Le template est un outil dont les specs et les ADR suffisent ; son `CLAUDE.md` garde lui aussi ses sections « À ADAPTER ».
- Document de vision : un projet peut en avoir un, comme FieldOps. Le template ne l'impose pas : la section « Objectif et périmètre » du cahier des charges en tient lieu.

## Questions ouvertes

- Aucune.
