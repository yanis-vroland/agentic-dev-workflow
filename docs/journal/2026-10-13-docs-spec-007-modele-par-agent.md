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
