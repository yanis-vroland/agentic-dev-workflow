# Spec 001 : script d'initialisation du template

Statut : validée
Date : 2026-10-07

## Besoin

En tant que développeur qui veut adopter le template sur un projet existant, je veux l'appliquer en une commande, `scripts/init.sh <chemin-du-projet> [--force]`, afin d'obtenir les garde-fous, les skills et la CI sans copie manuelle ni risque d'écraser mon travail.

## Contenu appliqué à la cible

Copiés depuis le template (chemins identiques dans la cible) :

- `.claude/`, sauf `.claude/settings.local.json` (réglages personnels) ;
- `.githooks/` ;
- `tests/hooks.sh` et `tests/pre-commit.sh` : un garde-fou voyage avec son test ;
- `docs/templates/`, en entier ;
- `CLAUDE.md` ;
- `.github/workflows/garde-fous.yml` et `.github/workflows/ai-review.yml` ;
- `.github/pull_request_template.md` ;
- `.github/scripts/verifier-revue-ia.sh` et `tests/verifier-revue-ia.sh`, utilisés par `ai-review.yml` (ajout de la spec 002, CA25 et CA26).

Seuls les fichiers **suivis par Git** dans le template sont copiés. Un fichier présent sur le disque mais non suivi (worktree d'agent sous `.claude/worktrees/`, fichier temporaire, notes personnelles) ne l'est jamais. Le template doit donc être un clone Git (issue #27).

Créés s'ils sont absents, jamais copiés depuis le template :

- `docs/adr/` et `docs/specs/`, chacun avec un `.gitkeep` ;
- `docs/journal.md`, avec l'en-tête du journal et sans entrée.

Ajoutés au `.gitignore` de la cible, seulement s'ils manquent : `.env`, `.env.*`, `!.env.example`, `.claude/settings.local.json`.

Dans un `.gitignore`, la dernière règle qui correspond l'emporte : la négation `!.env.example` doit donc rester **après** `.env.*`. Le script respecte cet ordre :

- une entrée `.env` ou `.env.*` manquante est insérée juste avant le premier `!.env.example` existant, ou ajoutée en fin de fichier s'il n'y en a pas ;
- `!.env.example` est ajouté en fin de fichier s'il manque, ou si sa dernière occurrence précède la dernière ligne `.env.*`. C'est le seul cas où une ligne peut apparaître deux fois : il corrige un ordre déjà inversé dans la cible.

### Séparation de la CI du template

L'actuel `.github/workflows/ci.yml` mélange deux rôles. Il est remplacé par deux workflows :

- `template-ci.yml`, propre au template et **non copié**. Un job, `template`, nommé « Vérifications du template » :
  - frontmatter des skills et subagents ;
  - validité de `.claude/settings.json` ;
  - shellcheck de `scripts/init.sh` et de son test ;
  - test de `init.sh`.
- `garde-fous.yml`, générique et **copié** par `init.sh`. Deux jobs :
  - `garde-fous`, nommé « Tests des garde-fous » :
    - shellcheck des hooks, du script de vérification de la revue IA et de leurs tests ;
    - `tests/verifier-revue-ia.sh` ;
    - `tests/hooks.sh` ;
    - installation de gitleaks (version fixée, somme vérifiée) et `tests/pre-commit.sh`.
  - `secrets`, nommé « Détection de secrets » : binaire gitleaks en version fixée (8.30.1), somme vérifiée, sur tout l'historique Git. `gitleaks-action` n'est plus utilisée : elle exige une licence pour les dépôts d'organisation, et elle ne vérifie pas la somme du binaire.

Les noms « Vérifications du template » et « Détection de secrets » sont ceux qu'exige aujourd'hui le ruleset de `main` ; ils sont conservés. Le nouveau job « Tests des garde-fous » doit être ajouté à la main aux vérifications requises du ruleset.

La version de gitleaks et sa somme de contrôle sont déclarées une seule fois dans `garde-fous.yml`. Elles sont alignées sur la version locale, et leur mise à jour est manuelle.

Le template exécute les deux workflows.

## Principes de test

Les tests vérifient les codes de sortie, les fichiers et la configuration Git produits, et la présence de **fragments** de message (un mot-clé ou un nom de fichier). Ils ne comparent jamais le texte exact d'un message.

## Critères d'acceptation

- CA1 : Étant donné un dossier vide initialisé avec Git, quand je lance `scripts/init.sh <cible>`, alors tous les fichiers de la section « Copiés » existent dans la cible avec un contenu identique au template, et les scripts y restent exécutables.
- CA2 : Étant donné une cible sans `docs/adr/`, `docs/specs/` ni `docs/journal.md`, quand je lance le script, alors ces deux dossiers existent avec un `.gitkeep`, et `docs/journal.md` contient l'en-tête du journal sans aucune entrée.
- CA3 : Étant donné une cible qui contient déjà un fichier de la section « Copiés », quand je lance le script sans `--force`, alors ce fichier n'est pas modifié, le script le liste parmi les fichiers ignorés, et il se termine avec le code 0. La règle vaut pour tout fichier de cette section ; le test l'illustre avec `CLAUDE.md`.
- CA4 : Étant donné la même cible, quand je lance le script avec `--force`, alors `CLAUDE.md` est remplacé par celui du template.
- CA5 : Étant donné une cible dont `docs/journal.md` contient des entrées, quand je lance le script, avec ou sans `--force`, alors le journal n'est pas modifié.
- CA6 : Étant donné une cible dont le `.gitignore` contient déjà `.env` mais pas les autres entrées, quand je lance le script, alors seules les entrées manquantes sont ajoutées. Le contenu existant est conservé, et aucune ligne n'est dupliquée.
- CA7 : Étant donné une cible sans `.gitignore`, quand je lance le script, alors un `.gitignore` est créé avec les quatre entrées, et `git check-ignore` confirme que `.env`, `.env.local` et `.claude/settings.local.json` sont ignorés et que `.env.example` ne l'est pas.
- CA8 : Étant donné une cible qui est la racine d'un dépôt Git sans `core.hooksPath`, quand je lance le script, alors `git config core.hooksPath` vaut `.githooks` dans la cible.
- CA9 : Étant donné une cible dont `core.hooksPath` a déjà une autre valeur, quand je lance le script sans `--force`, alors la valeur est conservée et le script affiche un avertissement qui cite cette valeur et explique comment brancher le pre-commit.
- CA10 : Étant donné une cible dont `core.hooksPath` a déjà une autre valeur, quand je lance le script avec `--force`, alors la valeur devient `.githooks`, et l'avertissement cite l'ancienne valeur, pour qu'on sache quels hooks ont été désactivés.
- CA11 : Étant donné une cible qui n'est pas un dépôt Git, quand je lance le script, alors les fichiers sont appliqués, aucun dépôt Git n'est créé, et le message final indique d'initialiser Git puis d'activer `core.hooksPath`.
- CA12 : Étant donné un dossier situé dans un dépôt Git sans en être la racine, quand je lance le script sur ce dossier, alors il sort avec le code 2, sans rien modifier, et son message invite à cibler la racine du dépôt.
- CA13 : Étant donné une cible qui contient déjà un `.claude/settings.json`, quand je lance le script sans `--force`, alors ce fichier n'est pas modifié. Le script affiche l'avertissement « garde-fous NON installés : fusionne manuellement les permissions et les hooks », et ajoute cette fusion aux étapes manuelles du message final.
- CA14 : Étant donné la même cible, quand je lance le script avec `--force`, alors `.claude/settings.json` est remplacé par celui du template et l'avertissement de CA13 n'apparaît pas.
- CA15 : Étant donné une cible déjà initialisée, quand je relance le script sans `--force`, alors aucun fichier n'est modifié, le `.gitignore` ne contient aucune ligne en double, tous les fichiers copiés sont listés comme ignorés, et le code de sortie est 0 (idempotence).
- CA16 : Étant donné une initialisation réussie, quand le script se termine, alors il affiche les étapes manuelles restantes :
  - secret `CLAUDE_CODE_OAUTH_TOKEN` ;
  - installation de l'application GitHub Claude ;
  - ruleset sur `main` ;
  - création du label `agent-corrigé`, avec la commande `gh` ;
  - sections « À ADAPTER » du `CLAUDE.md`.
- CA17 : Étant donné un poste sans gitleaks, quand je lance le script, alors il réussit, et le message final précise que le pre-commit bloquera **tous** les commits tant que gitleaks n'est pas installé.
- CA18 : Étant donné un poste sans jq, quand je lance le script, alors il réussit, et le message final précise que les hooks de Claude Code ne fonctionnent pas sans jq. En particulier, `protect-secrets.sh` échoue sans bloquer : l'accès de l'agent aux `.env` n'est plus protégé.
- CA19 : Étant donné une initialisation réussie, quand je liste les fichiers de la cible, alors elle ne contient ni `template-ci.yml`, ni `ci.yml`, ni le test de `init.sh`.
- CA20 : Étant donné le template après ce changement, quand la CI s'exécute sur une PR, alors les jobs de `template-ci.yml` et de `garde-fous.yml` passent, et `.github/workflows/ci.yml` n'existe plus. Ce critère est vérifié par la CI elle-même, pas par un test.
- CA21 : Étant donné une cible dont le `.gitignore` contient déjà `!.env.example` mais pas `.env.*`, quand je lance le script, alors `git check-ignore` confirme que `.env` et `.env.local` sont ignorés et que `.env.example` ne l'est pas.
- CA22 : Étant donné un template qui contient, sous `.claude/`, un fichier non suivi par Git, quand je lance le script, alors ce fichier n'est pas copié dans la cible, et les fichiers suivis le sont normalement.
- CA23 : Étant donné un template qui n'est pas la racine de son propre dépôt Git (extrait d'une archive ZIP, ou copié dans un sous-dossier d'un autre dépôt), quand je lance le script, alors il sort avec le code 1, sans rien modifier dans la cible, et son message invite à cloner le template avec Git.

## Cas limites et erreurs

- Sans argument, ou avec une option inconnue : le script affiche l'usage et sort avec le code 2, sans rien modifier.
- Cible inexistante : le script affiche une erreur et sort avec le code 1, sans rien créer.
- Cible qui est le template lui-même : le script refuse et sort avec le code 1.
- `.gitignore` sans saut de ligne final : le script ajoute un saut de ligne avant les nouvelles entrées, pour ne pas coller deux lignes.
- Le script se lance depuis n'importe quel répertoire courant : il retrouve le template à partir de son propre emplacement.
- Fichier suivi par Git mais absent du disque dans le template : le script refuse avec le code 1 **avant toute copie**, liste les fichiers manquants et propose `git restore` (décision de Yanis, revue de la PR #28).

## Hors périmètre

- Mise à jour d'un projet déjà initialisé vers une version plus récente du template (fusion, détection des différences).
- Actions sur GitHub : secret, application, ruleset et label restent manuels et sont seulement listés.
- Copie de `README.md`, `LICENSE`, `docs/adr/*`, `docs/journal.md` du template, `.env.example`, `.nvmrc`, `.idea/`, `scripts/` et `template-ci.yml`.
- Fusion d'un `CLAUDE.md` ou d'un `.claude/settings.json` existant avec ceux du template : c'est tout ou rien, selon `--force`. La fusion automatique du JSON n'est pas prévue.
- Modification des hooks de Claude Code pour qu'ils bloquent en l'absence de jq.
- Prise en charge de Windows hors WSL ou Git Bash.

## Questions ouvertes

- Aucune.
