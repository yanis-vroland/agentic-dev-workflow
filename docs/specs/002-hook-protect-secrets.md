# Spec 002 : hook protect-secrets

Statut : validée
Date : 2026-10-08

## Besoin

En tant que développeur qui confie le code à un agent, je veux que le hook `.claude/hooks/protect-secrets.sh` empêche l'agent d'accéder aux fichiers d'environnement (`.env`, `.env.*`, sauf `.env.example`), afin qu'aucun secret ne lui soit exposé.

Deux exigences s'ajoutent au comportement actuel :

- **Fermeture en cas de panne (#7)** : si le hook ne peut pas décider, il refuse.
- **Pas de refus sur une simple mention (#9)** : une commande qui ne fait que citer un nom de fichier d'environnement dans un texte (message de commit, corps de PR) n'est pas refusée. Une commande qui peut accéder à ce fichier, ou que le hook ne sait pas analyser, reste refusée.

## Contrat du hook

- Entrée : l'objet JSON fourni par Claude Code sur stdin (`tool_name`, `tool_input`).
- Code 0 : l'action est autorisée.
- Code 2 : l'action est refusée, avec un message en français sur stderr. C'est le seul code que Claude Code traite comme un blocage.
- Aucun autre code de sortie n'est permis, quelle que soit l'erreur interne.

## Définitions

- **Chemin protégé** : un chemin dont le dernier segment (après le dernier `/`) vaut `.env`, ou commence par `.env.` suivi d'au moins un caractère, sauf `.env.example`. Exemples protégés : `.env`, `/repo/.env.local`, `./.env.production`. Non protégés : `.env.example`, `.envrc`, `src/app.ts`.
- **Mention** : le motif actuel du hook, appliqué après retrait de `.env.example` : `.env` précédé d'un début de texte ou d'un caractère non alphanumérique, et suivi d'une fin de texte ou d'un caractère autre qu'alphanumérique, `_` ou `-`. `process.env` n'est pas une mention.
- **Option de texte reconnue** : la valeur de `-m` ou `--message` pour `git commit` et `git tag`, et la valeur de `-b`, `--body`, `-t` ou `--title` pour `gh pr` et `gh issue` (`create`, `comment`, `edit`). La forme `--option=valeur` est acceptée.

## Règles

Elles s'appliquent dans cet ordre ; la première qui conclut l'emporte.

1. **Entrée invalide → refus** : jq absent, JSON invalide, entrée vide, `tool_name` absent, `tool_input` absent.
2. **Read, Edit, Write, MultiEdit** : `file_path` absent → refus ; chemin protégé → refus ; sinon autorisé.
3. **Bash** : `command` absente → refus. Si la commande ne contient aucune mention → autorisé. Sinon :
   1. **Commande non analysable → refus.** C'est le cas avec : guillemet non fermé, heredoc (`<<`), substitution de commande (`$(…)` ou accents graves), substitution de processus (`<(…)`, `>(…)`).
   2. La commande est découpée en mots (espaces, guillemets simples et doubles, opérateurs `;`, `&&`, `||`, `|`, `&`, `<`, `>`, `>>`, parenthèses). Un mot, ou la valeur d'un mot `--option=valeur`, qui est un **chemin protégé** → refus.
   3. Un mot non entre guillemets qui contient une mention et un caractère de motif (`*`, `?`, `[`) → refus, car le motif peut s'étendre en `.env`.
   4. Un mot qui contient une mention sans être un chemin protégé est autorisé **seulement** s'il est la valeur d'une option de texte reconnue. Sinon → refus, car le texte peut être du code exécuté (`bash -c`, `python3 -c`, `eval`, `xargs`…).
   5. Sinon → autorisé.
4. **Autre outil** → autorisé (le hook n'est déclenché que pour les outils ci-dessus).

## Critères d'acceptation

### Comportement actuel conservé (les 8 cas de `tests/hooks.sh`)

- CA1 : Étant donné l'outil Read sur `/repo/.env`, quand le hook s'exécute, alors il sort avec le code 2.
- CA2 : Étant donné l'outil Read sur `/repo/.env.local`, quand le hook s'exécute, alors il sort avec le code 2.
- CA3 : Étant donné l'outil Write sur `/repo/.env.production`, quand le hook s'exécute, alors il sort avec le code 2.
- CA4 : Étant donné la commande Bash `cat .env`, quand le hook s'exécute, alors il sort avec le code 2.
- CA5 : Étant donné l'outil Read sur `/repo/.env.example`, quand le hook s'exécute, alors il sort avec le code 0.
- CA6 : Étant donné l'outil Edit sur `/repo/src/app.ts`, quand le hook s'exécute, alors il sort avec le code 0.
- CA7 : Étant donné la commande Bash `grep -r process.env src`, quand le hook s'exécute, alors il sort avec le code 0.
- CA8 : Étant donné l'outil Read sur `/repo/.envrc`, quand le hook s'exécute, alors il sort avec le code 0.

### Fermeture en cas de panne (#7)

- CA9 : Étant donné un PATH sans jq (dossier temporaire contenant des liens symboliques vers les seuls binaires nécessaires), quand le hook reçoit une entrée valide, alors il sort avec le code 2 et son message cite `jq`.
- CA10 : Étant donné une entrée qui n'est pas du JSON valide, quand le hook s'exécute, alors il sort avec le code 2.
- CA11 : Étant donné une entrée vide, quand le hook s'exécute, alors il sort avec le code 2.
- CA12 : Étant donné un JSON sans `tool_name`, quand le hook s'exécute, alors il sort avec le code 2.
- CA13 : Étant donné un JSON sans `tool_input`, quand le hook s'exécute, alors il sort avec le code 2.
- CA14 : Étant donné l'outil Read, Edit ou Write sans `file_path`, quand le hook s'exécute, alors il sort avec le code 2 (un cas testé par outil).
- CA15 : Étant donné l'outil Bash sans `command`, quand le hook s'exécute, alors il sort avec le code 2.
- CA16 : Étant donné une erreur interne quelconque, quand le hook s'exécute, alors son code de sortie n'est jamais autre chose que 0 ou 2. CA9 à CA15 en sont les cas testés.

### Accès qui restent refusés (#9)

- CA17 : Étant donné l'une des commandes Bash suivantes, quand le hook s'exécute, alors il sort avec le code 2 (un cas testé par commande) :
  - `cat .env`
  - `source .env`
  - `. .env`
  - `cp .env /tmp/copie`
  - `wc -l < .env`
  - `cat .env.local`
  - `cat ./config/.env`
  - `cat ".env"`
  - `cp .env.example .env`
  - `tool --file=.env`
- CA18 : Étant donné une commande non analysable qui contient une mention, quand le hook s'exécute, alors il sort avec le code 2 (un cas testé par construction) :
  - guillemet non fermé : `echo "a .env`
  - heredoc : `cat <<EOF` suivi de `.env` et de `EOF`
  - `echo $(cat .env)`
  - commande entre accents graves contenant `cat .env`
  - `diff <(cat .env) x`
- CA19 : Étant donné un texte contenant une mention, utilisé hors d'une option de texte reconnue, quand le hook s'exécute, alors il sort avec le code 2 (un cas testé par commande) : `bash -c "cat .env"`, `python3 -c "open('.env').read()"`, `eval "cat .env"`.
- CA20 : Étant donné un motif non entre guillemets contenant une mention, par exemple `cat .env*`, quand le hook s'exécute, alors il sort avec le code 2.

### Mentions désormais autorisées (#9)

- CA21 : Étant donné `gh pr comment 8 --body "le .gitignore ajoute .env.* puis la négation"`, quand le hook s'exécute, alors il sort avec le code 0.
- CA22 : Étant donné `git commit -m "chore: ignorer .env.local"`, quand le hook s'exécute, alors il sort avec le code 0.
- CA23 : Étant donné `gh issue create --title "fix: lecture de .env" --body-file /tmp/corps.md`, quand le hook s'exécute, alors il sort avec le code 0.
- CA24 : Étant donné `cat .env.example`, quand le hook s'exécute, alors il sort avec le code 0.

### Revue IA en CI (PR de #9)

- CA25 : Étant donné une exécution de la revue IA dont le résultat indique `permission_denials_count` > 0, quand le job se termine, alors il échoue et affiche ce nombre. La vérification est faite par le script `.github/scripts/verifier-revue-ia.sh <fichier de résultat>`, appelé par `ai-review.yml`. Le script est testé par `tests/verifier-revue-ia.sh` sur des fichiers de résultat factices (0 refus : succès ; 3 refus : échec).
- CA26 : Étant donné une exécution où `claude-code-action` n'a pas tourné (action sautée, par exemple quand la PR modifie son propre workflow), quand le job se termine, alors il échoue avec un message qui dit que la revue n'a pas été exécutée. Un fichier de résultat absent, vide, illisible ou sans résultat compte comme une revue non exécutée.

Le script et son test sont copiés par `scripts/init.sh`, comme `ai-review.yml` qui les utilise (spec 001).

## Principes de test

Les tests vérifient les codes de sortie et, pour CA9, la présence du fragment `jq` dans le message. Ils ne comparent jamais le texte exact d'un message. Ils sont ajoutés à `tests/hooks.sh`. Les nouveaux tests de #7 et #9 doivent échouer avant leur correction respective ; ceux de #9 qui portent sur des refus déjà en place (CA17) passent dès aujourd'hui et servent de non-régression.

## Découpage en PR

- **PR #7** (`fix`) : cette spec, CA1 à CA16.
- **PR #9** (`fix`) : CA17 à CA26, et la règle 2 alignée sur la définition du chemin protégé (dernier segment du chemin). La PR #7 appliquait encore le motif de mention au chemin complet, si bien que `/repo/.env.d/x.txt` était refusé. Les CA1 à CA16 doivent rester au vert.

## Cas limites et erreurs

- `--body-file` : sa valeur est un chemin. Elle est soumise à la règle du chemin protégé, pas traitée comme du texte.
- Option de texte reconnue, mais sous une commande non listée (`foo -m ".env"`) : la règle 3.4 ne s'applique pas → refus.
- `.env.example` cité dans un texte : ce n'est pas une mention (retiré avant la recherche) → autorisé partout.

## Hors périmètre

- Accès indirects sans mention littérale : variable (`f=.env; cat "$f"`), motif sans mention (`cat .e*`), lien symbolique. Ils ne sont pas détectés aujourd'hui non plus.
- Détection du contenu des secrets (piste 2 de #9).
- Outils non surveillés par le hook (Grep, Glob, etc.) : le matcher de `.claude/settings.json` n'est pas modifié.
- Retrait du contournement `--body-file` de la revue IA (PR #10) : il reste utile, car un rapport peut contenir une heredoc ou un motif.

## Questions ouvertes

Aucune. Les deux questions du brouillon sont tranchées par la validation de la spec telle quelle :

- Avec la règle 3.1, les commandes `git commit -m "$(cat <<EOF … EOF)"` qui citent `.env` restent refusées : l'agent passe par `git commit -F <fichier>`.
- La liste des options de texte reconnues reste celle des définitions. Une option supplémentaire (par exemple `gh release create --notes`) demandera une mise à jour de cette spec.
