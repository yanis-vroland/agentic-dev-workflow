# Journal : spec 007, un modèle choisi pour chaque subagent, et ADR-005

Branche `docs/spec-007-modele-par-agent`.

## 2026-10-13 11:10

### Fait

- Spec 007 au statut « brouillon » : modèle déclaré par chaque subagent (`test-writer` et `learning-curator` en `sonnet`, `reviewer` et `security-reviewer` en `opus`), vérification par un nouveau `verifier-modeles.sh` dans `garde-fous.yml`, modèle de la revue IA en CI lu dans `reviewer.md`, skills sans modèle. 18 critères d'acceptation.
- ADR-005 au statut « proposé » : critère de choix (juger → `opus`, exécuter → `sonnet`, mécanique → `haiku`) et alias plutôt qu'identifiants figés.
- Fonctionnement du champ `model` vérifié dans la documentation de Claude Code (`sub-agents`, `skills`, `github-actions`, `model-config`, 2026-10-13).

### Décisions

- Un modèle par subagent, alias plutôt qu'identifiant figé (Yanis).
- `learning-curator` en `sonnet` et non `haiku` : son filtre demande du jugement (agent, accepté par Yanis).
- `/review` ne déclare pas de modèle : la documentation ne dit pas lequel l'emporte entre le skill `context: fork` et le subagent ; le test humain CA18 le vérifie (agent).
- `fable` hors de la liste autorisée tant qu'il n'est pas évalué (agent, à valider par Yanis).

### Corrections et limites

- Le paramètre `model` passé à l'invocation l'emporte sur l'en-tête : la règle « jamais de paramètre `model` » est une consigne, pas une protection technique.
- Aucun coût mesuré : la spec et l'ADR n'avancent aucun chiffre.

### Prochaine étape

- Relecture de la spec 007 et de l'ADR-005 par Yanis, réponse à la question ouverte (repli sans `opus`), puis `/implement docs/specs/007-modele-par-agent.md`.

## 2026-10-13 11:25

### Fait

- Spec 007 : nouvelle section « Modèle indisponible : l'humain choisit le substitut », CA11 bis (échec de la revue IA en CI sans autre modèle essayé) et CA15 bis (consigne dans `CLAUDE.md` et `/implement`), cas limites mis à jour, section « Décisions ». Plus de question ouverte.
- ADR-005 : décision et conséquence « Disponibilité » alignées.

### Décisions

- Modèle indisponible : l'agent demande à l'humain quel substitut utiliser, il ne choisit jamais seul (Yanis).
- Le substitut vaut pour la session, passé par le paramètre `model` à l'invocation (seule exception à son interdiction), sans modifier l'en-tête ; consigné dans le journal et la PR. En CI, échec sans autre modèle essayé (agent, à valider par Yanis).

### Corrections et limites

- L'indisponibilité d'un modèle ne se simule pas en test automatique : CA11 bis est vérifié par l'humain.

### Prochaine étape

- Validation de la spec 007 par Yanis, puis `/implement docs/specs/007-modele-par-agent.md`.

## 2026-10-13 11:35

### Fait

- Spec 007 passée au statut « validée ». Début de `/implement`.

### Décisions

- Spec validée par Yanis (« ok ok »), avec les deux points tranchés par l'agent : substitut passé par le paramètre `model` à l'invocation, subagent non lancé consigné comme étape sautée.
- Implémentation sur cette branche plutôt qu'une branche `feat/` séparée : la spec n'est pas mergée, et la règle n°6 interdit une PR basée sur une autre (agent).
- Aucun piège dans `docs/learnings/` : rien à relire.

### Corrections et limites

- Rien.

### Prochaine étape

- Tests écrits par `test-writer`, puis vérification qu'ils échouent pour la bonne raison.

## 2026-10-13 11:55

### Fait

- Tests de la spec 007 écrits par `test-writer` : nouveau `tests/verifier-modeles.sh` (CA1 à CA9, CA11 et cas limites), section « Spec 007 CA13 » dans `tests/init-script.sh`.
- Tests renforcés par l'agent principal avant implémentation : en-tête sans fermeture, fichier inexistant en argument, `--afficher` sur un fichier inexistant. Cas limites ajoutés à la spec en conséquence, avec les valeurs refusées par la règle « alias nu » (`"opus"`, `Opus`, `fable`).
- Résultat : `verifier-modeles.sh` 101 échecs, tous dus à l'absence du script (code 127) ; `init-script.sh` 4 échecs, tous dans CA13 ; shellcheck sans avertissement.

### Décisions

- Un refus attendu est un code entre 1 et 125 : un script absent (127) ne passe pas pour un refus (`test-writer`, retenu par l'agent).
- Interface du script : sans argument (tous les subagents), avec des fichiers, ou `--afficher <fichier>` pour `ai-review.yml` (agent).

### Corrections et limites

- Les tests n'ont jamais tourné contre une implémentation : un faux négatif se verra à l'implémentation.
- CA10, CA12 et CA14 relèvent des workflows et du contrôle par mutation, écrits à l'implémentation.

### Prochaine étape

- Accord de Yanis sur les tests rouges, puis implémentation.

## 2026-10-13 12:40

### Fait

- Accord de Yanis sur les tests rouges (« oui vasy »).
- `.github/scripts/verifier-modeles.sh` : vérification de tous les subagents, de fichiers donnés, ou `--afficher` pour la revue IA.
- `model:` dans les quatre subagents (`test-writer` et `learning-curator` en `sonnet`, `reviewer` et `security-reviewer` en `opus`).
- `garde-fous.yml` : shellcheck, test et vérification des modèles. `ai-review.yml` : modèle lu dans `reviewer.md`, passé par `--model`, message d'échec qui nomme le modèle sans en essayer d'autre. `template-ci.yml` : vérification CA10 (aucun modèle en dur).
- `init.sh` copie le script et son test. `CLAUDE.md` (règle n°7), `/implement` et README (garde-fous, limites, structure, fichiers à supprimer) mis à jour.
- Tous les tests au vert : `verifier-modeles` 111, `init-script` 258, `quality-hooks` 102, `hooks` 52, `session-start` 50, `verifier-journal` 31, `lint-shell` 15, `verifier-revue-ia` 12, `pre-commit` 7. shellcheck sans avertissement, YAML des workflows valide.
- Contrôle par mutation (CA14) : 8 protections désactivées une à une, toutes détectées.

### Décisions

- Test CA2 renforcé par l'agent : la première mutation (ligne absente acceptée) n'était pas détectée, car la valeur vide est refusée de toute façon. Le test exige désormais le message propre à la ligne absente et la liste autorisée (agent).
- Motif de CA10 écrit `[$][{][{]` dans `template-ci.yml` : un `${{` littéral serait évalué par GitHub Actions avant le shell (agent).

### Corrections et limites

- Bug corrigé pendant l'implémentation : tableau vide et `set -u` sous bash 3.2 (macOS), détecté par CA7.
- CA11 bis (échec réel de la revue IA faute de modèle) et CA18 (`/review` lancé en `opus`) restent à vérifier par l'humain.

### Prochaine étape

- Revue de sécurité du diff par `security-reviewer`, puis test humain par Yanis.

## 2026-10-13 12:55

### Fait

- Tests de non-régression ajoutés : `model: opus haiku`, `model: opus --x` et `--afficher` sur `model: sonnet opus` doivent être refusés. Ils échouent sur `d4fb65e`.

### Décisions

- Bug trouvé par l'agent en relisant le diff avant la revue de sécurité : la comparaison `case " $allowed "` accepte une valeur de plusieurs mots qui recouvre la liste, et le second mot deviendrait un argument de `claude_args` en CI (agent).

### Corrections et limites

- Corrigé : comparaison exacte avec chaque alias autorisé. Tests au vert, mutations rejouées, toutes détectées.

### Prochaine étape

- Revue de sécurité du diff par `security-reviewer`, puis test humain par Yanis.

## 2026-10-13 13:15

### Fait

- Revue de sécurité par `security-reviewer` (en `opus`) : rien à signaler. Elle a porté sur l'état final du script et des trois workflows, à partir d'un résumé du diff : `init.sh` et les tests n'ont pas été relus sous cet angle.
- PR ouverte.

### Décisions

- Clôture demandée par Yanis avant le test humain (« cloture le dossier »). Le test humain n'est ni fait ni déclaré impossible : il reste à faire avant le merge (Yanis).

### Corrections et limites

- Test humain non fait : CA18 (`/review` en `opus` depuis une session `sonnet`), message d'erreur lisible, conduite face à un modèle indisponible (CA15 bis).
- CA11 bis et le `--model` de la revue IA ne peuvent pas être vérifiés sur cette PR : elle modifie `ai-review.yml`, que `claude-code-action` refuse d'exécuter (Limites du README). À vérifier à la première PR après le merge.

### Prochaine étape

- Test humain par Yanis (scénarios dans la PR), puis relecture et merge.

## 2026-10-13 14:40

### Fait

- Seconde revue de sécurité, sur le diff brut complet (`init.sh` et tests compris) : un point « À corriger », une suggestion.
- Point « À corriger » (A10) : si `mktemp -d` échouait, `work="$(cd "$(mktemp -d)" && pwd -P)"` valait le dossier courant, que le `trap` effaçait (racine du dépôt en CI). Reproduit avec un faux `mktemp` qui échoue, dans un dossier jetable. Corrigé dans les six tests qui portaient ce motif (`init-script`, `lint-shell`, `verifier-modeles`, `quality-hooks`, `session-start`, `verifier-journal`) : le test s'arrête avant de poser le `trap`. Même simulation après correction : code 1, dossier intact, pour les six.
- Suggestion (A08) suivie : dans `ai-review.yml`, second contrôle du modèle indépendant du script de la PR (un seul mot en minuscules), et commentaire qui interdit `pull_request_target`.
- Scénarios du test humain joués par l'agent, à la demande de Yanis, dans des worktrees jetables, avec de vraies sessions `claude -p` (Claude Code 2.1.291) :
  - CA18 : session `--model sonnet`, `/review` : le subagent `reviewer` a produit 19 messages, tous en `claude-opus-5-5` (transcription du subagent). Positif.
  - Message d'erreur : `model: inherit` puis `model: opus haiku` dans `test-writer.md` : code 1, message avec fichier, valeur et liste. Positif.
  - CA15 bis : `model: claude-inexistant` : erreur `model_not_found` (404), l'agent ne relance pas de substitut, rappelle subagent, modèle, erreur et critère de l'ADR-005, et demande à l'humain. Positif.

### Décisions

- Correction des six fichiers de test, dont cinq hors du diff de la spec : même motif, copié dans les projets (agent, à la demande de Yanis : « corrige »).
- Le second contrôle de `ai-review.yml` vérifie la forme (un mot en minuscules) et non la liste, pour ne pas recopier les noms de modèles (CA10) (agent).

### Corrections et limites

- Tests modifiés (règle n°3) : seulement la création du dossier temporaire, aucune vérification changée.
- Pas de test permanent de non-régression pour l'échec de `mktemp` : la preuve est la simulation ci-dessus, rejouable avec un faux `mktemp` en tête du `PATH`.
- Les scénarios ont été joués par l'agent, pas par l'humain dans sa session : la spec 005 dit que le test humain ne se délègue pas. À Yanis de dire s'il les accepte comme test humain.
- `tests/quality-hooks.sh` est aussi modifié par la PR #38 : rebase à prévoir après le premier merge.
- CA11 bis reste invérifiable sur cette PR (elle modifie `ai-review.yml`).

### Prochaine étape

- Décision de Yanis sur le test humain et sur l'ADR-005, puis relecture et merge.
